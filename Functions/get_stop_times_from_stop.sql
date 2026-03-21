-- FUNCTION: public.get_stop_times_from_stop(text, integer, timestamp with time zone)

DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(text, integer, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(
	target_stop_id text,
	target_stop_type integer,
	from_time timestamp with time zone)
    RETURNS TABLE(trip_id text, 
    arrival_time timestamp with time zone, 
    departure_time timestamp with time zone, 
    planned_arrival_time timestamp with time zone, 
    planned_departure_time timestamp with time zone, 
    actual_arrival_time timestamp with time zone, 
    actual_departure_time timestamp with time zone, 
    trip_schedule_relationship text, 
    stop_schedule_relationship text, 
    stop_headsign text, 
    data_origin text, 
    headsign text, 
    short_name text, 
    planned_platform text, 
    actual_platform text, 
    service_id text, 
    route_short_name text, 
    route_long_name text, 
    operator text, 
    route_url text, 
    route_type text, 
    route_desc text, 
    route_color text, 
    route_text_color text, 
    stop_type bigint, 
    real_time boolean, 
    starts_from text, 
    starts_before boolean, 
    ends_at text) 
    LANGUAGE 'sql'
    COST 100
    STABLE PARALLEL SAFE 
    ROWS 100

AS $BODY$
WITH day_context AS (
  SELECT date_trunc('day', from_time) AS service_date
)
SELECT
    trips.internal_id::text,
    
    -- Planned times converted correctly to UTC
    (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.arrival_time)::int,
            EXTRACT(MINUTE FROM stop_times.arrival_time)::int,
            EXTRACT(SECOND FROM stop_times.arrival_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS arrival_time,
    
    (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.departure_time)::int,
            EXTRACT(MINUTE FROM stop_times.departure_time)::int,
            EXTRACT(SECOND FROM stop_times.departure_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS departure_time,
    
    -- Return same planned times
    (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.arrival_time)::int,
            EXTRACT(MINUTE FROM stop_times.arrival_time)::int,
            EXTRACT(SECOND FROM stop_times.arrival_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS planned_arrival_time,
    
    (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.departure_time)::int,
            EXTRACT(MINUTE FROM stop_times.departure_time)::int,
            EXTRACT(SECOND FROM stop_times.departure_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS planned_departure_time,

    trip_updates_stop_times.arrival_time,
    trip_updates_stop_times.departure_time,
    trip_updates_stop_times.schedule_relationship,
    -- Joining trip_updates in here murders performance, so we do a subquery instead
    (select trip_updates.schedule_relationship from trip_updates where trip_updates.trip_id = trips.id and trip_updates.data_origin = trips.data_origin limit 1),
    stop_times.stop_headsign,
    stop_times.data_origin,
    --dont do this in prod kids
    -- dont do ANYTHING IN HERE in prod kids
    COALESCE(
        trips.headsign,
        concat(
            (SELECT stops.name
             FROM stop_times
             JOIN stops ON stops.id = stop_times.stop_id AND stops.data_origin = stop_times.data_origin
             JOIN supplier_configurations ON supplier_configurations.name = stop_times.data_origin
             WHERE stop_times.trip_id = trips.id AND stop_times.data_origin = trips.data_origin and stop_times.import_id = supplier_configurations.latest_succesfull_import_id
             ORDER BY stop_sequence DESC
             LIMIT 1),
            ' (?)')
    ),
    trips.short_name,
    stops.platform_code,
    stops.platform_code,
    trips.service_id,
    routes.short_name,
    routes.long_name,
    COALESCE(agencies.name, 'Unknown agency'),
    routes.url,
    routes.type::text,
    routes.description,
    routes.color,
    routes.text_color,
    stops.stop_type,
    (trip_updates_stop_times.trip_id IS NOT NULL OR position_entities.trip_id IS NOT NULL),

    -- starts_from: Populated only if the current stop is skipped, showing the next stop.
    -- This is now conditional on the trip not having terminated before the current stop.
    CASE
        -- Only proceed if the stop is marked as skipped...
        WHEN lower(trip_updates_stop_times.schedule_relationship) = 'skipped'
        -- ...AND the current stop's sequence is LESS THAN the actual last stop that will be served.
        AND stop_times.stop_sequence < (
            SELECT MAX(st_actual.stop_sequence)
            FROM stop_times AS st_actual
            LEFT JOIN trip_updates_stop_times AS tust_actual ON st_actual.trip_id = tust_actual.trip_id AND st_actual.data_origin = tust_actual.data_origin AND st_actual.stop_id = tust_actual.stop_id
            WHERE st_actual.trip_id = trips.id AND st_actual.data_origin = trips.data_origin
            AND (lower(tust_actual.schedule_relationship) IS NULL OR lower(tust_actual.schedule_relationship) not in ('skipped', 'cancelled'))
        )
        THEN
            -- If the conditions are met, find the next non-skipped/cancelled stop.
            (SELECT s_next.name
            FROM stop_times st_next
            JOIN stops s_next ON st_next.stop_id = s_next.id AND st_next.data_origin = s_next.data_origin
            LEFT JOIN trip_updates_stop_times tust_next ON st_next.trip_id = tust_next.trip_id AND st_next.data_origin = tust_next.data_origin AND st_next.stop_id = tust_next.stop_id
            WHERE st_next.trip_id = stop_times.trip_id AND st_next.data_origin = stop_times.data_origin AND st_next.stop_sequence > stop_times.stop_sequence
            AND (lower(tust_next.schedule_relationship) IS NULL OR lower(tust_next.schedule_relationship) not in ('skipped', 'cancelled')) AND (st_next.pickup_type != 1 OR st_next.drop_off_type != 1)
            ORDER BY st_next.stop_sequence
            LIMIT 1)
        ELSE
            -- If the stop is skipped but is after the new end of the line, it doesn't "start from" anywhere.
            NULL
    END,

    -- starts_before: Boolean. True if the trip terminated before this skipped stop.
    CASE
        WHEN lower(trip_updates_stop_times.schedule_relationship) in ('skipped') THEN
            -- This is true if there is no valid next stop to resume service from.
            ((SELECT st_next.stop_id
            FROM stop_times st_next
            LEFT JOIN trip_updates_stop_times tust_next ON st_next.trip_id = tust_next.trip_id AND st_next.data_origin = tust_next.data_origin AND st_next.stop_id = tust_next.stop_id
            WHERE st_next.trip_id = stop_times.trip_id AND st_next.data_origin = stop_times.data_origin AND st_next.stop_sequence > stop_times.stop_sequence
                AND (lower(tust_next.schedule_relationship) IS NULL OR lower(tust_next.schedule_relationship) not in ('skipped', 'cancelled')) AND (st_next.pickup_type != 1 OR st_next.drop_off_type != 1)
            LIMIT 1) IS NULL)
        ELSE
            NULL
    END,
    -- ends_earlier: Name of the new final stop, but only if the trip is ending earlier than planned.
    CASE
        WHEN -- Condition: The actual last stop sequence is less than the planned last stop sequence
            (
                SELECT MAX(st_actual.stop_sequence)
                FROM stop_times AS st_actual
                LEFT JOIN trip_updates_stop_times AS tust_actual ON st_actual.trip_id = tust_actual.trip_id AND st_actual.data_origin = tust_actual.data_origin AND st_actual.stop_id = tust_actual.stop_id
                WHERE st_actual.trip_id = trips.id AND st_actual.data_origin = trips.data_origin
                  AND (lower(tust_actual.schedule_relationship) IS NULL OR lower(tust_actual.schedule_relationship) not in ('skipped', 'cancelled'))
            )
            <
            (
                SELECT MAX(st_planned.stop_sequence)
                FROM stop_times AS st_planned
                WHERE st_planned.trip_id = trips.id AND st_planned.data_origin = trips.data_origin
            )
        THEN -- Action: Get the name of the actual last stop
            (
                SELECT s_last.name
                FROM stop_times AS st_last
                JOIN stops AS s_last ON st_last.stop_id = s_last.id AND st_last.data_origin = s_last.data_origin
                WHERE st_last.trip_id = trips.id AND st_last.data_origin = trips.data_origin
                AND st_last.stop_sequence = (
                    -- Re-calculating the actual last stop sequence to get the correct stop
                    SELECT MAX(st_actual.stop_sequence)
                    FROM stop_times AS st_actual
                    LEFT JOIN trip_updates_stop_times AS tust_actual ON st_actual.trip_id = tust_actual.trip_id AND st_actual.data_origin = tust_actual.data_origin AND st_actual.stop_id = tust_actual.stop_id
                    WHERE st_actual.trip_id = trips.id AND st_actual.data_origin = trips.data_origin
                    AND (lower(tust_actual.schedule_relationship) IS NULL OR lower(tust_actual.schedule_relationship) not in ('skipped', 'cancelled'))
                )
                LIMIT 1
            )
        ELSE
            NULL
    END

FROM
    stops
    INNER JOIN stop_times ON stops.id = stop_times.stop_id AND stops.data_origin = stop_times.data_origin
    INNER JOIN trips ON stop_times.trip_id = trips.id AND stop_times.data_origin = trips.data_origin
    INNER JOIN day_context ON TRUE
    INNER JOIN routes ON trips.route_id = routes.id AND trips.data_origin = routes.data_origin
    LEFT JOIN agencies ON routes.agency_id = agencies.id AND routes.data_origin = agencies.data_origin
    LEFT JOIN trip_updates_stop_times ON trips.id = trip_updates_stop_times.trip_id AND trips.data_origin = trip_updates_stop_times.data_origin AND trip_updates_stop_times.stop_id = stops.id
    LEFT JOIN position_entities ON trips.id = position_entities.trip_id AND trips.data_origin = position_entities.data_origin
WHERE
    stops.internal_id IN (
        SELECT related_stop FROM related_stops WHERE primary_stop = target_stop_id::uuid
    )
    AND stops.stop_type = target_stop_type
    AND stop_times.departure_time IS NOT NULL
    AND (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.departure_time)::int,
            EXTRACT(MINUTE FROM stop_times.departure_time)::int,
            EXTRACT(SECOND FROM stop_times.departure_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' >= timezone('utc', from_time)

    AND EXISTS (
        SELECT 1 FROM stop_times st2
        WHERE st2.data_origin = stop_times.data_origin AND st2.trip_id = stop_times.trip_id AND st2.stop_sequence > stop_times.stop_sequence
        LIMIT 1
    )
    AND (
        EXISTS (
            SELECT 1 FROM calendars c
            WHERE c.service_id = trips.service_id AND c.data_origin = trips.data_origin
              AND day_context.service_date BETWEEN c.start_date AND c.end_date
              AND CASE EXTRACT(DOW FROM day_context.service_date)::int
                   WHEN 0 THEN c.sunday WHEN 1 THEN c.monday WHEN 2 THEN c.tuesday
                   WHEN 3 THEN c.wednesday WHEN 4 THEN c.thursday WHEN 5 THEN c.friday
                   ELSE c.saturday
              END
        )
        OR EXISTS (
            SELECT 1 FROM calendar_dates cd
            WHERE cd.service_id = trips.service_id AND cd.data_origin = trips.data_origin
              AND cd.date = day_context.service_date AND cd.exception_type = 'Added'
        )
    )
    AND NOT EXISTS (
        SELECT 1 FROM calendar_dates cd
        WHERE cd.service_id = trips.service_id AND cd.data_origin = trips.data_origin
          AND cd.date = day_context.service_date AND cd.exception_type = 'Removed'
    )
ORDER BY
    (
        make_timestamp(
            EXTRACT(YEAR FROM day_context.service_date)::int,
            EXTRACT(MONTH FROM day_context.service_date)::int,
            EXTRACT(DAY FROM day_context.service_date)::int,
            EXTRACT(HOUR FROM stop_times.arrival_time)::int,
            EXTRACT(MINUTE FROM stop_times.arrival_time)::int,
            EXTRACT(SECOND FROM stop_times.arrival_time)
        ) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')
    ) AT TIME ZONE 'UTC'
LIMIT 100;
$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(text, integer, timestamp with time zone)
    OWNER TO postgres;

