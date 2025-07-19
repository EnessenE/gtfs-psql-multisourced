-- FUNCTION: public.get_stop_times_for_trip(text)
DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target uuid)
    RETURNS TABLE(SEQUENCE bigint
,
        id text,
        name text,
        planned_arrival_time timestamp with time zone,
        planned_departure_time timestamp with time zone,
        actual_arrival_time timestamp with time zone,
        actual_departure_time timestamp with time zone,
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
(coalesce(calendar_dates.date,(SELECT CURRENT_DATE)) + stop_times.arrival_time) AS planned_arrival_time,

						
(coalesce(calendar_dates.date,(SELECT CURRENT_DATE)) + stop_times.departure_time) AS planned_departure_time,
(trip_updates_stop_times.arrival_time)   AS actual_arrival_time,
(trip_updates_stop_times.departure_time)   AS actual_departure_time,
trip_updates_stop_times.schedule_relationship,
    stops.platform_code,
    stop_times.stop_headsign,
    stops.latitude,
    stops.longitude,
    stop_times.pickup_type,
    stop_times.drop_off_type,
    stops.stop_type
FROM
    stop_times2 as stop_times
    JOIN stops ON stop_times.stop_id = stops.id and stop_times.data_origin = stops.data_origin
    JOIN trips ON trips.id = stop_times.trip_id and trips.data_origin = stop_times.data_origin
    LEFT JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
        AND calendar_dates.data_origin = trips.data_origin and calendar_dates.service_id = trips.service_id and date = (SELECT CURRENT_DATE)
    LEFT JOIN calendars ON trips.service_id = calendars.service_id
        AND calendars.data_origin = trips.data_origin and calendars.service_id = trips.service_id
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
    public.get_stop_times_for_trip('e8bd1d7f-f490-4a86-8771-b35061c36956')
