-- FUNCTION: public.get_stop_times_for_trip(text)
DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target uuid)
    RETURNS TABLE(SEQUENCE bigint
,
        id text,
        name text,
        arrival time with time zone,
        departure time with time zone,
        platform_code text,
        stop_headsign text,
        latitude double precision,
        longitude double precision,
        drop_off int,
        pick_up int,
        stop_type int)
        LANGUAGE 'sql'
        COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
        AS $BODY$
    SELECT
        stop_times.stop_sequence,
(
            SELECT
                primary_stop
            FROM
                related_stops
            WHERE(stops.internal_id = related_stops.related_stop)
        LIMIT 1) AS id,
    stops.name,
(stop_times.arrival_time) AS arrival_time,
(stop_times.departure_time) AS departure_time,
    stops.platform_code,
    stop_times.stop_headsign,
    stops.latitude,
    stops.longitude,
    stop_times.pickup_type,
    stop_times.drop_off_type,
    stops.stop_type
FROM
    stop_times
    JOIN stops ON stop_times.stop_id = stops.id and stop_times.data_origin = stops.data_origin
    JOIN trips ON trips.id = stop_times.trip_id and trips.data_origin = stop_times.data_origin
WHERE
    trips.internal_id = target
ORDER BY
    stop_times.stop_sequence;
$BODY$;

ALTER FUNCTION public.get_stop_times_for_trip(uuid) OWNER TO dennis;

SELECT
    *
FROM
    public.get_stop_times_for_trip('79b7c1ca-17cf-434e-8785-e32d04160f24')
