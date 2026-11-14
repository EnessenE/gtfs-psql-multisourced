CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(target_stop_id text, target_stop_type integer, from_time timestamp with time zone)
 RETURNS TABLE(trip_id text, arrival_time timestamp with time zone, departure_time timestamp with time zone, planned_arrival_time timestamp with time zone, planned_departure_time timestamp with time zone, actual_arrival_time timestamp with time zone, actual_departure_time timestamp with time zone, trip_schedule_relationship text, stop_schedule_relationship text, stop_headsign text, data_origin text, headsign text, short_name text, planned_platform text, actual_platform text, service_id text, route_short_name text, route_long_name text, operator text, route_url text, route_type text, route_desc text, route_color text, route_text_color text, stop_type bigint, real_time boolean, starts_from text, starts_before boolean, ends_at text)
 LANGUAGE sql
 STABLE PARALLEL SAFE
AS $function$
WITH departures AS (
SELECT
    trips.internal_id::text AS trip_id,
    
    -- 1. Original Time Hacks (Anchored to gsd.service_date for Midnight Support)
    (make_timestamp(EXTRACT(YEAR FROM gsd.service_date)::int, EXTRACT(MONTH FROM gsd.service_date)::int, EXTRACT(DAY FROM gsd.service_date)::int, EXTRACT(HOUR FROM stop_times.arrival_time)::int, EXTRACT(MINUTE FROM stop_times.arrival_time)::int, EXTRACT(SECOND FROM stop_times.arrival_time)) AT TIME ZONE COALESCE(agencies.timezone, 'Europe/Amsterdam')) AS arrival_time,
    (make_timestamp(EXTRACT(YEAR FROM gsd.service_date)::int, EXTRACT(MONTH FROM gsd.service_date)::int, EXTRACT(DAY FROM gsd.service_date)::int, EXTRACT(HOUR FROM stop_times.departure_time)::int, EXTRACT(MINUTE FROM stop_times.departure_time)::int, EXTRACT(SECOND FROM stop_times.departure_time)) AT TIME ZONE COALESCE(agencies.timezone, 'Europe/Amsterdam')) AS departure_time,
    (make_timestamp(EXTRACT(YEAR FROM gsd.service_date)::int, EXTRACT(MONTH FROM gsd.service_date)::int, EXTRACT(DAY FROM gsd.service_date)::int, EXTRACT(HOUR FROM stop_times.arrival_time)::int, EXTRACT(MINUTE FROM stop_times.arrival_time)::int, EXTRACT(SECOND FROM stop_times.arrival_time)) AT TIME ZONE COALESCE(agencies.timezone, 'Europe/Amsterdam')) AS planned_arrival_time,
    (make_timestamp(EXTRACT(YEAR FROM gsd.service_date)::int, EXTRACT(MONTH FROM gsd.service_date)::int, EXTRACT(DAY FROM gsd.service_date)::int, EXTRACT(HOUR FROM stop_times.departure_time)::int, EXTRACT(MINUTE FROM stop_times.departure_time)::int, EXTRACT(SECOND FROM stop_times.departure_time)) AT TIME ZONE COALESCE(agencies.timezone, 'Europe/Amsterdam')) AS planned_departure_time,

    trip_updates_stop_times.arrival_time AS actual_arrival_time,
    trip_updates_stop_times.departure_time AS actual_departure_time,
    -- Trip Status lookup (Lazy Scalar: Runs only 100 times)
    (SELECT tu.schedule_relationship FROM trip_updates tu WHERE tu.trip_id = trips.id AND tu.data_origin = trips.data_origin LIMIT 1) AS trip_schedule_relationship,
    trip_updates_stop_times.schedule_relationship AS stop_schedule_relationship,
    
    stop_times.stop_headsign AS stop_headsign,
    stop_times.data_origin AS data_origin,
    
    -- 2. Fallback Headsign (Clean official, fallback with ?)
    COALESCE(NULLIF(trips.headsign, ''), trips.destination_stop_name || ' (?)', 'Unknown Destination') AS headsign,
    
    trips.short_name AS short_name,
    stops.platform_code AS planned_platform,
    stops.platform_code AS actual_platform,
    trips.service_id AS service_id,
    routes.short_name AS route_short_name,
    routes.long_name AS route_long_name,
    COALESCE(agencies.name, 'Unknown agency') AS operator,
    routes.url AS route_url,
    routes.type::text AS route_type,
    routes.description AS route_desc,
    routes.color AS route_color,
    routes.text_color AS route_text_color,
    stops.stop_type AS stop_type,
    (trip_updates_stop_times.trip_id IS NOT NULL OR position_entities.trip_id IS NOT NULL) AS real_time,

    -- starts_from: Fixed table aliases
    CASE 
        WHEN lower(trip_updates_stop_times.schedule_relationship) = 'skipped' THEN (
            SELECT next_stops.name FROM stop_times AS next_st
            JOIN stops AS next_stops ON next_st.stop_id = next_stops.id AND next_st.data_origin = next_stops.data_origin
            LEFT JOIN trip_updates_stop_times AS next_tust ON next_st.trip_id = next_tust.trip_id AND next_st.data_origin = next_tust.data_origin AND next_st.stop_id = next_tust.stop_id
            WHERE next_st.trip_id = trips.id AND next_st.data_origin = trips.data_origin AND next_st.stop_sequence > stop_times.stop_sequence
            AND (lower(next_tust.schedule_relationship) IS NULL OR lower(next_tust.schedule_relationship) NOT IN ('skipped', 'cancelled'))
            AND (next_st.pickup_type != 1 OR next_st.drop_off_type != 1)
            ORDER BY next_st.stop_sequence LIMIT 1
        )
        ELSE NULL 
    END AS starts_from,

    -- starts_before: Fixed table aliases
    CASE 
        WHEN lower(trip_updates_stop_times.schedule_relationship) = 'skipped' THEN (
            NOT EXISTS (
                SELECT 1 FROM stop_times AS rem_st
                LEFT JOIN trip_updates_stop_times AS rem_tust ON rem_st.trip_id = rem_tust.trip_id AND rem_st.data_origin = rem_tust.data_origin AND rem_st.stop_id = rem_tust.stop_id
                WHERE rem_st.trip_id = trips.id AND rem_st.data_origin = trips.data_origin AND rem_st.stop_sequence > stop_times.stop_sequence
                AND (lower(rem_tust.schedule_relationship) IS NULL OR lower(rem_tust.schedule_relationship) NOT IN ('skipped', 'cancelled'))
                AND (rem_st.pickup_type != 1 OR rem_st.drop_off_type != 1)
            )
        )
        ELSE NULL 
    END AS starts_before,

    -- ends_at: Fixed table aliases and logical truncation check
    CASE 
        WHEN (trip_updates_stop_times.trip_id IS NOT NULL OR position_entities.trip_id IS NOT NULL) THEN (
            SELECT final_stops.name 
            FROM stop_times AS final_st
            JOIN stops AS final_stops ON final_stops.id = final_st.stop_id AND final_stops.data_origin = final_st.data_origin
            WHERE final_st.trip_id = trips.id AND final_st.data_origin = trips.data_origin
            AND final_st.stop_sequence = (
                SELECT MAX(act_end_st.stop_sequence)
                FROM stop_times AS act_end_st
                LEFT JOIN trip_updates_stop_times AS act_end_tust ON act_end_st.trip_id = act_end_tust.trip_id AND act_end_st.stop_id = act_end_tust.stop_id AND act_end_st.data_origin = act_end_tust.data_origin
                WHERE act_end_st.trip_id = trips.id AND act_end_st.data_origin = trips.data_origin
                  AND (lower(act_end_tust.schedule_relationship) IS NULL OR lower(act_end_tust.schedule_relationship) NOT IN ('skipped', 'cancelled'))
            )
            AND final_st.stop_sequence < (SELECT MAX(planned_max.stop_sequence) FROM stop_times AS planned_max WHERE planned_max.trip_id = trips.id AND planned_max.data_origin = trips.data_origin)
        )
        ELSE NULL 
    END AS ends_at

FROM
    -- 3. Scope anchor
    (SELECT 
        date_trunc('day', from_time) AS base_service_day,
        target_stop_id::uuid AS target_uuid
    ) AS ctx
    CROSS JOIN related_stops 
    INNER JOIN stops ON stops.internal_id = related_stops.related_stop AND stops.stop_type = target_stop_type
    INNER JOIN stop_times ON stop_times.stop_id = stops.id AND stop_times.data_origin = stops.data_origin
    INNER JOIN trips ON trips.id = stop_times.trip_id AND trips.data_origin = stop_times.data_origin
    
    -- 4. Today and Tomorrow Join (Midnight Awareness)
    INNER JOIN gtfs_service_dates gsd ON gsd.service_handle_id = trips.service_handle_id 
        AND gsd.service_date BETWEEN (ctx.base_service_day::date - 1) AND ctx.base_service_day::date
    
    INNER JOIN routes ON routes.id = trips.route_id AND routes.data_origin = trips.data_origin
    LEFT JOIN agencies ON (agencies.id = routes.agency_id AND agencies.data_origin = routes.data_origin)
    LEFT JOIN trip_updates_stop_times ON (trips.id = trip_updates_stop_times.trip_id AND trip_updates_stop_times.stop_id = stops.id AND trips.data_origin = trip_updates_stop_times.data_origin)
    LEFT JOIN position_entities ON (trips.id = position_entities.trip_id AND trips.data_origin = position_entities.data_origin)
WHERE
    related_stops.primary_stop = ctx.target_uuid
    AND stop_times.departure_time IS NOT NULL
    -- Last planned stop of the trip: train ends here, not a departure
    AND stop_times.stop_sequence < (SELECT MAX(st_max.stop_sequence) FROM stop_times st_max WHERE st_max.trip_id = trips.id AND st_max.data_origin = trips.data_origin)
    
    -- 5. Time Filter (DST & Midnight proof)
    AND (make_timestamp(EXTRACT(YEAR FROM gsd.service_date)::int, EXTRACT(MONTH FROM gsd.service_date)::int, EXTRACT(DAY FROM gsd.service_date)::int, EXTRACT(HOUR FROM stop_times.departure_time)::int, EXTRACT(MINUTE FROM stop_times.departure_time)::int, EXTRACT(SECOND FROM stop_times.departure_time)) AT TIME ZONE COALESCE(agencies.timezone, 'Europe/Amsterdam')) >= from_time

),
-- Feeds can contain the same physical departure as several trips: one per platform, or
-- once per overlapping service pattern with slightly different times. Rows with a trip
-- number (short_name) are clustered by number within a five-minute chain (train numbers
-- are unique per day); rows without a number get their own cluster per exact departure time.
lagged AS (
  SELECT
    d.*,
    CASE WHEN NULLIF(d.short_name, '') IS NULL THEN d.departure_time::text ELSE d.short_name END AS cluster_key,
    lag(d.departure_time) OVER w AS prev_departure_time
  FROM departures d
  WINDOW w AS (
    PARTITION BY d.data_origin, d.route_short_name,
      CASE WHEN NULLIF(d.short_name, '') IS NULL THEN d.departure_time::text ELSE d.short_name END
    ORDER BY d.departure_time
  )
),
clustered AS (
  SELECT
    l.*,
    SUM(CASE
          WHEN l.prev_departure_time IS NULL
            OR l.departure_time - l.prev_departure_time > interval '5 minutes'
          THEN 1 ELSE 0
        END) OVER (PARTITION BY l.data_origin, l.route_short_name, l.cluster_key ORDER BY l.departure_time) AS cluster_id
  FROM lagged l
)
SELECT *
FROM (
  SELECT DISTINCT ON (c.data_origin, c.route_short_name, c.cluster_key, c.cluster_id)
      c.trip_id, c.arrival_time, c.departure_time, c.planned_arrival_time, c.planned_departure_time,
      c.actual_arrival_time, c.actual_departure_time, c.trip_schedule_relationship, c.stop_schedule_relationship,
      c.stop_headsign, c.data_origin, c.headsign, c.short_name, c.planned_platform, c.actual_platform,
      c.service_id, c.route_short_name, c.route_long_name, c.operator, c.route_url, c.route_type,
      c.route_desc, c.route_color, c.route_text_color, c.stop_type, c.real_time, c.starts_from, c.starts_before, c.ends_at
  FROM clustered c
  ORDER BY c.data_origin, c.route_short_name, c.cluster_key, c.cluster_id,
      c.real_time DESC NULLS LAST, c.departure_time, c.planned_platform ASC NULLS LAST
) AS deduped
ORDER BY deduped.departure_time
LIMIT 100;
$function$

