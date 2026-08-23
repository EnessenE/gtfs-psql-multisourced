CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(
    target_stop_id text,
    target_stop_type integer,
    from_time timestamp with time zone)
    RETURNS TABLE(
        trip_id text, arrival_time timestamp with time zone, departure_time timestamp with time zone, 
        planned_arrival_time timestamp with time zone, planned_departure_time timestamp with time zone, 
        actual_arrival_time timestamp with time zone, actual_departure_time timestamp with time zone, 
        trip_schedule_relationship text, stop_schedule_relationship text, stop_headsign text, 
        data_origin text, headsign text, short_name text, planned_platform text, 
        actual_platform text, service_id text, route_short_name text, route_long_name text, 
        operator text, route_url text, route_type text, route_desc text, 
        route_color text, route_text_color text, stop_type bigint, 
        real_time boolean, starts_from text, starts_before boolean, ends_at text
    ) 
    LANGUAGE 'sql'
    STABLE PARALLEL SAFE 
AS $BODY$
SELECT
    trips.internal_id::text,
    
    -- 1. Planned Times (Math anchored by ctx)
    ((ctx.service_day + stop_times.arrival_time) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')) AT TIME ZONE 'UTC',
    ((ctx.service_day + stop_times.departure_time) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')) AT TIME ZONE 'UTC',
    ((ctx.service_day + stop_times.arrival_time) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')) AT TIME ZONE 'UTC',
    ((ctx.service_day + stop_times.departure_time) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')) AT TIME ZONE 'UTC',

    trip_updates_stop_times.arrival_time AS actual_arrival_time,
    trip_updates_stop_times.departure_time AS actual_departure_time,
    -- Trip Status (Scalar lookup: runs only 100 times)
    (SELECT tu.schedule_relationship FROM trip_updates tu WHERE tu.trip_id = trips.id AND tu.data_origin = trips.data_origin LIMIT 1),
    trip_updates_stop_times.schedule_relationship AS stop_schedule_relationship,
    
    stop_times.stop_headsign,
    stop_times.data_origin,
    
    -- 2. Denormalized Headsign (Fallback to pre-calculated destination name)
    COALESCE(trips.headsign, trips.destination_stop_name || ' (?)', 'Unknown Destination'),
    
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

    -- starts_from: Only calculated if stop is skipped
    CASE 
        WHEN lower(trip_updates_stop_times.schedule_relationship) = 'skipped' THEN (
            SELECT s_next.name FROM stop_times st_next
            JOIN stops s_next ON s_next.id = st_next.stop_id AND s_next.data_origin = st_next.data_origin
            LEFT JOIN trip_updates_stop_times tust_next ON st_next.trip_id = tust_next.trip_id AND st_next.data_origin = tust_next.data_origin AND st_next.stop_id = tust_next.stop_id
            WHERE st_next.trip_id = trips.id AND st_next.data_origin = trips.data_origin AND st_next.stop_sequence > stop_times.stop_sequence
            AND (lower(tust_next.schedule_relationship) IS NULL OR lower(tust_next.schedule_relationship) NOT IN ('skipped', 'cancelled'))
            AND (st_next.pickup_type != 1 OR st_next.drop_off_type != 1)
            ORDER BY st_next.stop_sequence LIMIT 1
        )
        ELSE NULL 
    END,

    -- starts_before: Boolean check for remaining stops
    CASE 
        WHEN lower(trip_updates_stop_times.schedule_relationship) = 'skipped' THEN (
            NOT EXISTS (
                SELECT 1 FROM stop_times st_rem
                LEFT JOIN trip_updates_stop_times tust_rem ON st_rem.trip_id = tust_rem.trip_id AND st_rem.data_origin = tust_rem.data_origin AND st_rem.stop_id = tust_rem.stop_id
                WHERE st_rem.trip_id = trips.id AND st_rem.data_origin = trips.data_origin AND st_rem.stop_sequence > stop_times.stop_sequence
                AND (lower(tust_rem.schedule_relationship) IS NULL OR lower(tust_rem.schedule_relationship) NOT IN ('skipped', 'cancelled'))
                AND (st_rem.pickup_type != 1 OR st_rem.drop_off_type != 1)
            )
        )
        ELSE NULL 
    END,

    -- ends_at: Corrected Truncation Logic (Actual Last < Planned Last)
    CASE 
        WHEN (trip_updates_stop_times.trip_id IS NOT NULL OR position_entities.trip_id IS NOT NULL) THEN (
            SELECT s_final.name 
            FROM stop_times st_final
            JOIN stops s_final ON s_final.id = st_final.stop_id AND s_final.data_origin = st_final.data_origin
            WHERE st_final.trip_id = trips.id AND st_final.data_origin = trips.data_origin
            AND st_final.stop_sequence = (
                SELECT MAX(st_act.stop_sequence)
                FROM stop_times st_act
                LEFT JOIN trip_updates_stop_times tust_act ON st_act.trip_id = tust_act.trip_id AND st_act.stop_id = tust_act.stop_id AND st_act.data_origin = tust_act.data_origin
                WHERE st_act.trip_id = trips.id AND st_act.data_origin = trips.data_origin
                  AND (lower(tust_act.schedule_relationship) IS NULL OR lower(tust_act.schedule_relationship) NOT IN ('skipped', 'cancelled'))
            )
            -- Condition: only if actual sequence is strictly less than the planned max
            AND st_final.stop_sequence < (SELECT MAX(stop_sequence) FROM stop_times WHERE trip_id = trips.id AND data_origin = trips.data_origin)
        )
        ELSE NULL 
    END

FROM
    -- Shared variables provided via CROSS JOIN to fix scoping issues
    (SELECT 
        date_trunc('day', from_time) AS service_day,
        (from_time - date_trunc('day', from_time)) AS min_interval,
        target_stop_id::uuid AS target_uuid
    ) ctx
    CROSS JOIN related_stops rs
    INNER JOIN stops ON stops.internal_id = rs.related_stop AND stops.stop_type = target_stop_type
    INNER JOIN stop_times ON stop_times.stop_id = stops.id AND stop_times.data_origin = stops.data_origin
    INNER JOIN trips ON trips.id = stop_times.trip_id AND trips.data_origin = stop_times.data_origin
    
    -- 3. The New Normalized Calendar Join (The Sub-Second Fix)
    INNER JOIN gtfs_service_dates gsd ON gsd.service_handle_id = trips.service_handle_id AND gsd.service_date = ctx.service_day
    
    INNER JOIN routes ON routes.id = trips.route_id AND routes.data_origin = trips.data_origin
    LEFT JOIN agencies ON (agencies.id = routes.agency_id AND agencies.data_origin = routes.data_origin)
    LEFT JOIN trip_updates_stop_times ON (trips.id = trip_updates_stop_times.trip_id AND trip_updates_stop_times.stop_id = stops.id AND trips.data_origin = trip_updates_stop_times.data_origin)
    LEFT JOIN position_entities ON (trips.id = position_entities.trip_id AND trips.data_origin = position_entities.data_origin)
WHERE
    rs.primary_stop = ctx.target_uuid
    AND stop_times.departure_time IS NOT NULL
    -- Broad index hint for stop_times departure index
    AND stop_times.departure_time >= (ctx.min_interval - interval '1 hour')
    -- Final precise precision check
    AND ((ctx.service_day + stop_times.departure_time) AT TIME ZONE COALESCE(agencies.timezone, 'UTC')) AT TIME ZONE 'UTC' >= from_time

ORDER BY 2 ASC
LIMIT 100;
$BODY$;