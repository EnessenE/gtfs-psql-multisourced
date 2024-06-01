-- FUNCTION: public.get_stop_times_from_stop(text, time without time zone, date)
-- DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(text, time without time zone, date);
CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(target text, from_time time without time zone, from_date date)
    RETURNS TABLE(
        trip_id text,
        arrival_time time without time zone,
        departure_time time without time zone,
        stop_headsign text,
        data_origin text,
        headsign text,
        short_name text,
        platform text,
        service_id text,
        route_short_name text,
        route_long_name text,
        OPERATOR text,
        route_url text,
        route_type text,
        route_desc text,
        route_color text,
        route_text_color text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH stop_data AS(
        SELECT
            id
        FROM
            stops
        WHERE
            LOWER(id) = LOWER(target)
),
stop_data2 AS(
    SELECT
        parent_station
    FROM
        stops
    WHERE
        LOWER(id) = LOWER(target)
        AND parent_station != ''
)
SELECT
    stop_times.trip_id,
    stop_times.arrival_time,
    stop_times.departure_time,
    stop_times.stop_headsign,
    stop_times.data_origin,
    trips.headsign,
    trips.short_name,
    stops.platform_code,
    trips.service_id,
    routes.short_name,
    routes.long_name,
    agencies.name,
    routes.url,
    routes.type,
    routes.description,
    routes.color,
    routes.text_color
FROM
    stop_times
    INNER JOIN trips ON stop_times.trip_id = trips.id
    INNER JOIN stops ON stop_times.stop_id = stops.id
    INNER JOIN routes ON trips.route_id = routes.id
    INNER JOIN agencies ON routes.agency_id = agencies.id
    INNER JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
WHERE
    -- parent_station / station filter
((parent_station != ''
            AND parent_station = COALESCE((
                SELECT
                    parent_station
                FROM stop_data2 LIMIT 1),(
            SELECT
                id
            FROM stop_data LIMIT 1)))
        OR stop_id =(
            SELECT
                id
            FROM
                stop_data
            LIMIT 1))
    -- Date filter
    AND((stop_times.arrival_time >= from_time
            AND calendar_dates.date::date = from_date)
        OR(stop_times.arrival_time <= from_time - INTERVAL '12 hours'
            AND calendar_dates.date::date = from_date + INTERVAL '1 day'))
--Prevent showing the trip if the current stop is the last stop
AND EXISTS(
    SELECT
        1
    FROM
        stop_times st2
    WHERE
        st2.trip_id = stop_times.trip_id
        AND st2.stop_sequence > stop_times.stop_sequence)
ORDER BY
    calendar_dates.date::date,
    arrival_time ASC
LIMIT 100;
$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(text, time WITHOUT time zone, date) OWNER TO dennis;

SELECT
    *
FROM
    get_stop_times_from_stop('stoparea:18188', '23:34', '2024-05-30');

