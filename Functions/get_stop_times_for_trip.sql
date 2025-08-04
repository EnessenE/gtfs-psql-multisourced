DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target uuid)
RETURNS TABLE(
    sequence bigint,
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
    stop_type int
)
LANGUAGE sql
COST 100
VOLATILE
PARALLEL UNSAFE
ROWS 1000
AS $$
SELECT
    stop_times.stop_sequence,

    (
        SELECT primary_stop
        FROM related_stops
        WHERE stops.internal_id = related_stops.related_stop
        LIMIT 1
    ) AS id,

    stops.name,

    -- Convert stored local time to UTC
    (coalesce(calendar_dates.date, CURRENT_DATE) + stop_times.arrival_time) AT TIME ZONE agencies.timezone AT TIME ZONE 'UTC' AS planned_arrival_time,
    (coalesce(calendar_dates.date, CURRENT_DATE) + stop_times.departure_time) AT TIME ZONE agencies.timezone AT TIME ZONE 'UTC' AS planned_departure_time,

    trip_updates_stop_times.arrival_time AS actual_arrival_time,
    trip_updates_stop_times.departure_time AS actual_departure_time,
    trip_updates_stop_times.schedule_relationship,
    stops.platform_code,
    stop_times.stop_headsign,
    stops.latitude,
    stops.longitude,
    stop_times.drop_off_type,
    stop_times.pickup_type,
    stops.stop_type

FROM
    stop_times2 AS stop_times
    JOIN stops ON stop_times.stop_id = stops.id AND stop_times.data_origin = stops.data_origin
    JOIN trips ON trips.id = stop_times.trip_id AND trips.data_origin = stop_times.data_origin
    LEFT JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
        AND calendar_dates.data_origin = trips.data_origin
        AND calendar_dates.date = CURRENT_DATE
    LEFT JOIN calendars ON trips.service_id = calendars.service_id AND calendars.data_origin = trips.data_origin
    LEFT JOIN routes ON trips.route_id = routes.id AND routes.data_origin = trips.data_origin
    LEFT JOIN agencies ON routes.agency_id = agencies.id AND routes.data_origin = agencies.data_origin
    LEFT JOIN trip_updates_stop_times ON trips.id = trip_updates_stop_times.trip_id
        AND trip_updates_stop_times.data_origin = trips.data_origin
        AND trip_updates_stop_times.stop_id = stops.id

WHERE
    trips.internal_id = target

ORDER BY
    stop_times.stop_sequence;
$$;
