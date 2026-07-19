DROP FUNCTION IF EXISTS get_timetable_from_route(text, text);
DROP FUNCTION IF EXISTS get_timetable_from_route(text, text, date);

CREATE OR REPLACE FUNCTION public.get_timetable_from_route(
    target_data_origin text,
    target_route_id    text,
    target_date        date DEFAULT NULL
)
    RETURNS TABLE(
        stop_id       text,
        stop_name     text,
        stop_sequence bigint,
        trip_id       text,
        trip_headsign text,
        departure_time time)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH matched_route AS (
        SELECT
            routes.id,
            routes.data_origin
        FROM routes
        WHERE routes.data_origin = target_data_origin
          AND (
              routes.id = target_route_id
              OR routes.short_name = target_route_id
          )
        ORDER BY
            CASE WHEN routes.id = target_route_id THEN 0 ELSE 1 END,
            routes.last_updated DESC
        LIMIT 1
    ),
    -- Canonical trip: most stops → defines the stop ordering reference
    canonical_trip AS (
        SELECT trips.id, trips.data_origin, trips.import_id
        FROM trips
        INNER JOIN matched_route
            ON matched_route.data_origin = trips.data_origin
           AND trips.route_id = matched_route.id
        ORDER BY (
            SELECT COUNT(*)
            FROM stop_times st_c
            WHERE st_c.trip_id     = trips.id
              AND st_c.data_origin = trips.data_origin
              AND st_c.import_id   = trips.import_id
        ) DESC
        LIMIT 1
    ),
    -- Canonical stop order: primary_stop → sequence number
    canonical_stop_order AS (
        SELECT
            related_stops.primary_stop,
            MIN(stop_times.stop_sequence) AS seq
        FROM canonical_trip
        INNER JOIN stop_times
            ON stop_times.trip_id    = canonical_trip.id
           AND stop_times.data_origin = canonical_trip.data_origin
           AND stop_times.import_id   = canonical_trip.import_id
        INNER JOIN stops
            ON stops.id          = stop_times.stop_id
           AND stops.data_origin  = stop_times.data_origin
           AND stops.import_id    = stop_times.import_id
        INNER JOIN related_stops
            ON related_stops.related_stop         = stops.internal_id
           AND related_stops.related_data_origin   = stops.data_origin
        GROUP BY related_stops.primary_stop
    ),
    -- All trips on route, capped at 100, ordered by first departure time
    -- When target_date is provided, only trips running on that date are included.
    route_trips AS (
        SELECT
            trips.id AS gtfs_trip_id,
            trips.internal_id::text AS internal_trip_id,
            trips.headsign,
            trips.data_origin,
            trips.import_id,
            MIN(stop_times.departure_time) AS first_departure
        FROM trips
        INNER JOIN matched_route
            ON matched_route.data_origin = trips.data_origin
           AND trips.route_id = matched_route.id
        INNER JOIN stop_times
            ON stop_times.trip_id    = trips.id
           AND stop_times.data_origin = trips.data_origin
           AND stop_times.import_id   = trips.import_id
        WHERE (
            target_date IS NULL
            OR trips.service_id IN (
                -- Calendar rule: within date range + correct day-of-week, not
                -- cancelled by calendar_dates exception_type = '2'
                SELECT c.service_id
                FROM calendars c
                WHERE c.data_origin  = target_data_origin
                  AND c.start_date  <= target_date
                  AND c.end_date    >= target_date
                  AND CASE EXTRACT(DOW FROM target_date)
                          WHEN 0 THEN c.sunday
                          WHEN 1 THEN c.monday
                          WHEN 2 THEN c.tuesday
                          WHEN 3 THEN c.wednesday
                          WHEN 4 THEN c.thursday
                          WHEN 5 THEN c.friday
                          WHEN 6 THEN c.saturday
                      END = true
                  AND NOT EXISTS (
                      SELECT 1 FROM calendar_dates cd
                      WHERE cd.service_id  = c.service_id
                        AND cd.data_origin = c.data_origin
                        AND cd.date        = target_date
                        AND LOWER(cd.exception_type) = 'removed'
                  )
                UNION
                -- calendar_dates exception_type = '1': explicitly added on this date
                SELECT cd2.service_id
                FROM calendar_dates cd2
                WHERE cd2.data_origin     = target_data_origin
                  AND cd2.date            = target_date
                  AND LOWER(cd2.exception_type) = 'added'
            )
        )
        GROUP BY trips.id, trips.internal_id, trips.headsign, trips.data_origin, trips.import_id
        ORDER BY MIN(stop_times.departure_time) NULLS LAST
        LIMIT 100
    )
    -- Flat rows: one per (primary stop × trip), platforms merged away
    SELECT
        related_stops.primary_stop::text                    AS stop_id,
        MIN(stops.name)                                     AS stop_name,
        COALESCE(MIN(canonical_stop_order.seq), 999999)     AS stop_sequence,
        route_trips.internal_trip_id                        AS trip_id,
        route_trips.headsign                                AS trip_headsign,
        MIN(stop_times.departure_time)                      AS departure_time
    FROM route_trips
    INNER JOIN stop_times
        ON stop_times.trip_id    = route_trips.gtfs_trip_id
       AND stop_times.data_origin = route_trips.data_origin
       AND stop_times.import_id   = route_trips.import_id
    INNER JOIN stops
        ON stops.id          = stop_times.stop_id
       AND stops.data_origin  = stop_times.data_origin
       AND stops.import_id    = stop_times.import_id
    INNER JOIN related_stops
        ON related_stops.related_stop         = stops.internal_id
       AND related_stops.related_data_origin   = stops.data_origin
    LEFT JOIN canonical_stop_order
        ON canonical_stop_order.primary_stop = related_stops.primary_stop
    GROUP BY
        related_stops.primary_stop,
        route_trips.internal_trip_id,
        route_trips.headsign,
        route_trips.first_departure
    ORDER BY
        COALESCE(MIN(canonical_stop_order.seq), 999999),
        route_trips.first_departure NULLS LAST,
        route_trips.internal_trip_id
$BODY$;
