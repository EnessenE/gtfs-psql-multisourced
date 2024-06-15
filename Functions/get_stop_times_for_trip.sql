-- FUNCTION: public.get_stop_times_for_trip(text)
DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(text);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target text)
    RETURNS TABLE(
        SEQUENCE bigint
,
            id text,
            name text,
            arrival time without time zone,
            departure time without time zone,
            platform_code text,
            stop_headsign text,
            latitude double precision,
            longitude double precision,
            stop_type int)
        LANGUAGE 'sql'
        COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
        AS $BODY$
    SELECT
        stop_times.stop_sequence,
(
            SELECT
                related_stop
            FROM
                related_stops
            WHERE(stops.id = related_stops.related_stop
                AND stops.data_origin = related_stops.related_data_origin)
        LIMIT 1) AS id,
stops.name,
stop_times.arrival_time,
stop_times.departure_time,
stops.platform_code,
stop_times.stop_headsign,
stops.latitude,
stops.longitude,
stops.stop_type
FROM
    stop_times
    JOIN stops ON stop_times.stop_id = stops.id
WHERE
    stop_times.trip_id = target
ORDER BY
    stop_times.stop_sequence;
$BODY$;

ALTER FUNCTION public.get_stop_times_for_trip(text) OWNER TO dennis;

