-- FUNCTION: public.get_stop_times_from_stop(text, time without time zone, date)
DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(text, time WITHOUT time zone, date);

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
        route_text_color text,
        stop_type int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH secondary_stop_data AS(
        SELECT
            primary_stop,
            related_stop,
            stop_type
        FROM
            related_stops
            INNER JOIN stops ON related_stops.related_stop = stops.id
        WHERE
            primary_stop = target
            OR related_stop = target
        LIMIT 1),
	primary_stop_data AS(
        SELECT
            primary_stop,
            related_stop,
            stop_type
        FROM
            related_stops
            INNER JOIN stops ON related_stops.related_stop = stops.id
        WHERE
            primary_stop = (select primary_stop from secondary_stop_data)
			and stop_type = (select stop_type from secondary_stop_data)
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
    routes.text_color,
    stops.stop_type
FROM
    stop_times
    INNER JOIN trips ON stop_times.trip_id = trips.id and stop_times.data_origin = trips.data_origin
    INNER JOIN stops ON stop_times.stop_id = stops.id and stop_times.data_origin = stops.data_origin
    INNER JOIN routes ON trips.route_id = routes.id and stop_times.data_origin = routes.data_origin
    INNER JOIN agencies ON routes.agency_id = agencies.id and stop_times.data_origin = agencies.data_origin
    INNER JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
WHERE
    -- parent_station / station filter
(stop_id = ANY(
            SELECT
                related_stop
            FROM
                primary_stop_data))
        -- stop type filter
        AND(stop_type IN(
                SELECT
                    stop_type
                FROM
                    primary_stop_data))
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
    get_stop_times_from_stop('2510515', '23:34', '2024-05-30');

