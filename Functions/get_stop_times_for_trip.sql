-- FUNCTION: public.get_stop_times_for_trip(text)
DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target uuid)
    RETURNS TABLE(SEQUENCE bigint
,
        id text,
        name text,
        planned_arrival_time time with time zone,
        planned_departure_time time with time zone,
        actual_arrival_time time with time zone,
        actual_departure_time time with time zone,
		schedule_relationship text,
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
(stop_times.arrival_time) AT time zone coalesce(stops.timezone, 'UTC')  AS planned_arrival_time,
(stop_times.departure_time) AT time zone coalesce(stops.timezone, 'UTC')  AS planned_departure_time,
(trip_updates_stop_times.arrival_time) A AS actual_arrival_time,
(trip_updates_stop_times.departure_time)  AS actual_departure_time,
trip_updates_stop_times.schedule_relationship,
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
    LEFT JOIN trip_updates_stop_times ON trips.id = trip_updates_stop_times.trip_id
        AND trip_updates_stop_times.data_origin = trips.data_origin AND trip_updates_stop_times.stop_id = stops.id
WHERE
    trips.internal_id = target
ORDER BY
    stop_times.stop_sequence;
$BODY$;

ALTER FUNCTION public.get_stop_times_for_trip(uuid) OWNER TO dennis;

SELECT
    *
FROM
    public.get_stop_times_for_trip('13d5f8e3-1c17-408a-9a07-850720baaf7d')
