DROP FUNCTION IF EXISTS get_stops_from_route(text, text);

CREATE OR REPLACE FUNCTION public.get_stops_from_route(target_data_origin text, target_route_id text)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        coordinates double precision[])
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH matched_route AS (
        SELECT
            routes.id,
            routes.data_origin
        FROM
            routes
        WHERE
            routes.data_origin = target_data_origin
            AND (
                routes.id = target_route_id
                OR routes.short_name = target_route_id
            )
        ORDER BY
            CASE WHEN routes.id = target_route_id THEN 0 ELSE 1 END,
            routes.last_updated DESC
        LIMIT 1
    ),
    -- Pick the trip with the most stops as the canonical ordering reference
    -- (mirrors the longest-shape selection in get_shapes_from_route)
    canonical_trip AS (
        SELECT
            trips.id,
            trips.data_origin,
            trips.import_id
        FROM
            trips
            INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
                AND trips.route_id = matched_route.id
        ORDER BY
            (
                SELECT COUNT(*)
                FROM stop_times st_count
                WHERE st_count.trip_id = trips.id
                  AND st_count.data_origin = trips.data_origin
                  AND st_count.import_id = trips.import_id
            ) DESC
        LIMIT 1
    ),
    route_trips AS (
        SELECT DISTINCT
            trips.id,
            trips.data_origin,
            trips.import_id
        FROM
            trips
            INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
        WHERE
            trips.route_id = matched_route.id
    ),
    found_primaries AS (
        SELECT DISTINCT
            related_stops.primary_stop,
            stops.stop_type
        FROM
            route_trips
            INNER JOIN stop_times ON stop_times.trip_id = route_trips.id
                AND stop_times.data_origin = route_trips.data_origin
                AND stop_times.import_id = route_trips.import_id
            INNER JOIN stops ON stops.id = stop_times.stop_id
                AND stops.data_origin = stop_times.data_origin
                AND stops.import_id = stop_times.import_id
            INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
                AND related_stops.related_data_origin = stops.data_origin
    ),
    -- Map each primary stop to its first sequence position in the canonical trip
    canonical_sequence AS (
        SELECT
            related_stops.primary_stop,
            MIN(stop_times.stop_sequence) AS seq
        FROM
            canonical_trip
            INNER JOIN stop_times ON stop_times.trip_id = canonical_trip.id
                AND stop_times.data_origin = canonical_trip.data_origin
                AND stop_times.import_id = canonical_trip.import_id
            INNER JOIN stops ON stops.id = stop_times.stop_id
                AND stops.data_origin = stop_times.data_origin
                AND stops.import_id = stop_times.import_id
            INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
                AND related_stops.related_data_origin = stops.data_origin
        GROUP BY related_stops.primary_stop
    )
    SELECT
        MIN(stops.name) AS name,
        found_primaries.stop_type,
        found_primaries.primary_stop::text AS id,
        array_agg(DISTINCT ARRAY[stops.longitude, stops.latitude]) AS coordinates
    FROM
        found_primaries
        INNER JOIN related_stops ON related_stops.primary_stop = found_primaries.primary_stop
        INNER JOIN stops ON stops.internal_id = related_stops.related_stop
            AND stops.data_origin = related_stops.related_data_origin
            AND stops.stop_type = found_primaries.stop_type
        LEFT JOIN canonical_sequence ON canonical_sequence.primary_stop = found_primaries.primary_stop
    GROUP BY
        found_primaries.primary_stop,
        found_primaries.stop_type
    ORDER BY
        COALESCE(MIN(canonical_sequence.seq), 999999),
        MIN(stops.name) ASC
$BODY$;