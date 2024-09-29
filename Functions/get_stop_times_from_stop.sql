-- FUNCTION: public.get_stop_times_from_stop(uuid, integer, timestamp with time zone)
DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(uuid, integer, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(target uuid, target_stop_type integer, from_time timestamp with time zone)
    RETURNS TABLE(
        trip_id text,
        arrival_time timestamp with time zone,
        departure_time timestamp with time zone,
        planned_arrival_time timestamp with time zone,
        planned_departure_time timestamp with time zone,
        actual_arrival_time timestamp with time zone,
        actual_departure_time timestamp with time zone,
        schedule_relationship text,
        stop_headsign text,
        data_origin text,
        headsign text,
        short_name text,
        planned_platform text,
        actual_platform text,
        service_id text,
        route_short_name text,
        route_long_name text,
        OPERATOR text,
        route_url text,
        route_type text,
        route_desc text,
        route_color text,
        route_text_color text,
        stop_type bigint,
        real_time boolean)
    LANGUAGE 'sql'
    COST 500 VOLATILE PARALLEL UNSAFE ROWS 100
    AS $BODY$
    SELECT
        trips.internal_id,
        -- TO FIX FOR PICKUP/DROPOFF WINDOWS AND CALENDERS
(coalesce(calendar_dates.date,(
                    SELECT
                        CURRENT_DATE)) + stop_times.arrival_time) AT time zone 'UTC' AS arrival_time,
(coalesce(calendar_dates.date,(
                    SELECT
                        CURRENT_DATE)) + stop_times.departure_time) AT time zone 'UTC' AS departure_time,
(coalesce(calendar_dates.date,(
                SELECT
                    CURRENT_DATE)) + stop_times.arrival_time) AT time zone 'UTC' AS planned_arrival_time,
(coalesce(calendar_dates.date,(
            SELECT
                CURRENT_DATE)) + stop_times.departure_time) AT time zone 'UTC' AS planned_departure_time,
(coalesce(calendar_dates.date,(
            SELECT
                CURRENT_DATE)) + trip_updates_stop_times.arrival_time) AS actual_arrival_time,
(coalesce(calendar_dates.date,(
            SELECT
                CURRENT_DATE)) + trip_updates_stop_times.departure_time) AS actual_departure_time,
trip_updates_stop_times.schedule_relationship,
stop_times.stop_headsign,
stop_times.data_origin,
trips.headsign,
trips.short_name,
stops.platform_code,
stops.platform_code,
trips.service_id,
routes.short_name,
routes.long_name,
coalesce(agencies.name, 'Unknown agency'),
routes.url,
routes.type,
routes.description,
routes.color,
routes.text_color,
stops.stop_type,
(trip_updates_stop_times.trip_id IS NOT NULL)
FROM
    trips
    INNER JOIN routes ON trips.route_id = routes.id
        AND trips.data_origin = routes.data_origin
    INNER JOIN stop_times ON stop_times.trip_id = trips.id
        AND stop_times.data_origin = trips.data_origin
    INNER JOIN stops ON stop_times.stop_id = stops.id
        AND stop_times.data_origin = stops.data_origin
    INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
    LEFT JOIN agencies ON routes.agency_id = agencies.id
        AND routes.data_origin = agencies.data_origin
    LEFT JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
        AND calendar_dates.data_origin = trips.data_origin
    LEFT JOIN calenders ON trips.service_id = calenders.service_id
        AND calenders.data_origin = trips.data_origin
    LEFT JOIN trip_updates_stop_times ON trips.id = trip_updates_stop_times.trip_id
        AND trip_updates_stop_times.data_origin = trips.data_origin
        AND trip_updates_stop_times.stop_id = stops.id
WHERE
    --parent_station / station filter
(primary_stop = target)
    AND stop_type = target_stop_type
    --          --Date filter
    AND(((calendar_dates.date::date + stop_times.arrival_time::time WITHOUT time zone) >= from_time)
        --18 <= 10
        OR(calenders.start_date <= from_time
            AND((EXTRACT(DOW FROM from_time) = 0
                    AND sunday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 1
                    AND monday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 2
                    AND tuesday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 3
                    AND wednesday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 4
                    AND thursday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 5
                    AND friday = TRUE)
                OR(EXTRACT(DOW FROM from_time) = 6
                    AND saturday = TRUE))))
    --          -- Prevent showing the trip if the current stop is the last stop
    AND EXISTS(
        SELECT
            1
        FROM
            stop_times st2
        WHERE
            st2.data_origin = stop_times.data_origin
            AND st2.trip_id = stop_times.trip_id
            AND st2.stop_sequence > stop_times.stop_sequence
        LIMIT 1)
ORDER BY
    coalesce(calendar_dates.date,(
            SELECT
                CURRENT_DATE)) + stop_times.arrival_time ASC,
    stop_times.arrival_time ASC
LIMIT 100;
$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(uuid, integer, timestamp with time zone) OWNER TO dennis;

SELECT
    *
FROM
    get_stop_times_from_stop('0c94a1e8-0a61-4bea-a36d-9814aa0f1f1e'::uuid, 2, '2024-09-28 18:00Z');

