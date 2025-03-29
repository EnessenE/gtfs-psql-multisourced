DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(uuid, integer, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(
    target_stop_id uuid,
    target_stop_type integer,
    from_time timestamp with time zone
)
    RETURNS TABLE(
        trip_id text,
        arrival_time timestamp with time zone,
        departure_time timestamp with time zone,
        planned_arrival_time timestamp with time zone,
        planned_departure_time timestamp with time zone,
        actual_arrival_time timestamp with time zone,
        actual_departure_time timestamp with time zone,
        schedule_relationship text,
        stop_headsign text,
        data_origin text,
        headsign text,
        short_name text,
        planned_platform text,
        actual_platform text,
        service_id text,
        route_short_name text,
        route_long_name text,
        OPERATOR text,
        route_url text,
        route_type text,
        route_desc text,
        route_color text,
        route_text_color text,
        stop_type bigint,
        real_time boolean
    )
    LANGUAGE 'sql'
    COST 100
    STABLE    
    PARALLEL SAFE 
    ROWS 100
AS $BODY$
WITH 
-- Pre-calculate date value once
current_date_cte AS (
    SELECT CURRENT_DATE AS today
),
-- Filter related stops first to reduce initial dataset
relevant_stops AS (
    SELECT rs.related_stop 
    FROM related_stops rs
    WHERE rs.primary_stop = target_stop_id
),
-- Get qualified stop_times first (this is likely the largest table)
qualified_stop_times AS (
    SELECT 
        st.trip_id,
        st.data_origin,
        st.stop_id,
        st.arrival_time,
        st.departure_time,
        st.stop_sequence,
        st.stop_headsign
    FROM stop_times2 st
    INNER JOIN stops s ON st.stop_id = s.id AND st.data_origin = s.data_origin
    WHERE s.internal_id IN (SELECT related_stop FROM relevant_stops)
      AND s.stop_type = target_stop_type
      -- Push the "not last stop" filter to this CTE to reduce rows early
      AND EXISTS (
          SELECT 1
          FROM stop_times2 st2
          WHERE st2.data_origin = st.data_origin
            AND st2.trip_id = st.trip_id
            AND st2.stop_sequence > st.stop_sequence
          LIMIT 1
      )
),
-- Get calendar information separately
calendar_info AS (
    SELECT 
        cd.service_id,
        cd.data_origin,
        cd.date,
        c.start_date,
        c.end_date,
        c.sunday, c.monday, c.tuesday, c.wednesday, c.thursday, c.friday, c.saturday
    FROM calendar_dates cd
    FULL OUTER JOIN calenders c ON cd.service_id = c.service_id AND cd.data_origin = c.data_origin
    WHERE 
        (cd.date::date + '00:00:00'::time WITHOUT TIME ZONE >= from_time::date)
        OR (
            c.start_date <= from_time::date
            AND (c.end_date IS NULL OR c.end_date >= from_time::date)
            AND CASE EXTRACT(DOW FROM from_time)::integer
                WHEN 0 THEN c.sunday
                WHEN 1 THEN c.monday
                WHEN 2 THEN c.tuesday
                WHEN 3 THEN c.wednesday
                WHEN 4 THEN c.thursday
                WHEN 5 THEN c.friday
                WHEN 6 THEN c.saturday
                ELSE FALSE
            END
        )
)
SELECT
    t.internal_id,
    (COALESCE(ci.date, cd.today) + qst.arrival_time) AT TIME ZONE 'UTC' AS arrival_time,
    (COALESCE(ci.date, cd.today) + qst.departure_time) AT TIME ZONE 'UTC' AS departure_time,
    (COALESCE(ci.date, cd.today) + qst.arrival_time) AT TIME ZONE 'UTC' AS planned_arrival_time,
    (COALESCE(ci.date, cd.today) + qst.departure_time) AT TIME ZONE 'UTC' AS planned_departure_time,
    tust.arrival_time AS actual_arrival_time,
    tust.departure_time AS actual_departure_time,
    tust.schedule_relationship,
    qst.stop_headsign,
    qst.data_origin,
    t.headsign,
    t.short_name,
    s.platform_code AS planned_platform,
    s.platform_code AS actual_platform,
    t.service_id,
    r.short_name AS route_short_name,
    r.long_name AS route_long_name,
    COALESCE(a.name, 'Unknown agency') AS operator,
    r.url,
    r.type,
    r.description,
    r.color,
    r.text_color,
    s.stop_type,
    (tust.trip_id IS NOT NULL OR pe.trip_id IS NOT NULL) AS real_time
FROM 
    qualified_stop_times qst
    INNER JOIN trips t ON qst.trip_id = t.id AND qst.data_origin = t.data_origin
    INNER JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
    INNER JOIN stops s ON qst.stop_id = s.id AND qst.data_origin = s.data_origin
    LEFT JOIN agencies a ON r.agency_id = a.id AND r.data_origin = a.data_origin
    LEFT JOIN calendar_info ci ON t.service_id = ci.service_id AND ci.data_origin = t.data_origin
    LEFT JOIN trip_updates_stop_times tust ON t.id = tust.trip_id 
        AND tust.data_origin = t.data_origin
        AND tust.stop_id = s.id
    LEFT JOIN position_entities pe ON t.id = pe.trip_id AND pe.data_origin = t.data_origin
    CROSS JOIN current_date_cte cd
WHERE
    ((ci.date::date + qst.arrival_time::time WITHOUT TIME ZONE) >= from_time
     OR (
         ci.start_date <= from_time
         AND (ci.end_date IS NULL OR ci.end_date >= from_time)
         AND CASE EXTRACT(DOW FROM from_time)::integer
             WHEN 0 THEN ci.sunday
             WHEN 1 THEN ci.monday
             WHEN 2 THEN ci.tuesday
             WHEN 3 THEN ci.wednesday
             WHEN 4 THEN ci.thursday
             WHEN 5 THEN ci.friday
             WHEN 6 THEN ci.saturday
             ELSE FALSE
         END
     )
    )
ORDER BY
    COALESCE(ci.date, cd.today) + qst.arrival_time ASC,
    qst.arrival_time ASC
LIMIT 100;
$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(uuid, integer, timestamp with time zone) OWNER TO dennis;