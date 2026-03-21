DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid);
DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(uuid, date);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target uuid, target_date date DEFAULT CURRENT_DATE)
RETURNS TABLE(
    sequence bigint,
    id text,
    name text,
    planned_arrival_time timestamp with time zone,
    planned_departure_time timestamp with time zone,
    actual_arrival_time timestamp with time zone,
    actual_departure_time timestamp with time zone,
    trip_schedule_relationship text,
    stop_schedule_relationship text,
    platform_code text,
    stop_headsign text,
    latitude double precision,
    longitude double precision,
    drop_off int,
    pick_up int,
    stop_type int,
    time_zone text
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
                SELECT primary_stop::text
        FROM related_stops
                WHERE stops.internal_id = related_stops.related_stop
                    AND stops.data_origin = related_stops.related_data_origin
        LIMIT 1
    ) AS id,

    stops.name,

    CASE
        WHEN stop_times.arrival_time IS NULL THEN NULL
        ELSE (target_date + stop_times.arrival_time) AT TIME ZONE effective_timezone.time_zone
    END AS planned_arrival_time,
    CASE
        WHEN stop_times.departure_time IS NULL THEN NULL
        ELSE (target_date + stop_times.departure_time) AT TIME ZONE effective_timezone.time_zone
    END AS planned_departure_time,

    trip_updates_stop_times.arrival_time AS actual_arrival_time,
    trip_updates_stop_times.departure_time AS actual_departure_time,
    trip_updates.schedule_relationship,
    trip_updates_stop_times.schedule_relationship,
    stops.platform_code,
    stop_times.stop_headsign,
    stops.latitude,
    stops.longitude,
    stop_times.drop_off_type,
    stop_times.pickup_type,
    stops.stop_type,
    effective_timezone.time_zone

FROM
    stop_times AS stop_times
    JOIN stops ON stop_times.stop_id = stops.id AND stop_times.data_origin = stops.data_origin
    LEFT JOIN stops parent_stop ON parent_stop.id = stops.parent_station AND parent_stop.data_origin = stops.data_origin
    JOIN trips ON trips.id = stop_times.trip_id AND trips.data_origin = stop_times.data_origin
    LEFT JOIN routes ON trips.route_id = routes.id AND routes.data_origin = trips.data_origin
    LEFT JOIN agencies ON routes.agency_id = agencies.id AND routes.data_origin = agencies.data_origin
    LEFT JOIN trip_updates ON trips.id = trip_updates.trip_id
        AND trip_updates.data_origin = trips.data_origin
    LEFT JOIN trip_updates_stop_times ON trips.id = trip_updates_stop_times.trip_id
        AND trip_updates_stop_times.data_origin = trips.data_origin
        AND trip_updates_stop_times.stop_id = stops.id
    CROSS JOIN LATERAL (
        SELECT COALESCE(
            NULLIF(stops.timezone, ''),
            NULLIF(parent_stop.timezone, ''),
            NULLIF(agencies.timezone, ''),
            'UTC'
        ) AS time_zone
    ) effective_timezone

WHERE
    trips.internal_id = target

ORDER BY
    stop_times.stop_sequence;
$$;
