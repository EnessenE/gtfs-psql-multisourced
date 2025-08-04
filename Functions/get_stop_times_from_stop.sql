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
        operator text,
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
-- This small CTE is safe and just calculates the date range once.
target_date_range AS (
    SELECT
        date_trunc('day', from_time) AS start_of_day,
        date_trunc('day', from_time) + interval '1 day' AS end_of_day
)
SELECT
    t.internal_id::text,
    (d.start_of_day + st.arrival_time),
    (d.start_of_day + st.departure_time),
    (d.start_of_day + st.arrival_time),
    (d.start_of_day + st.departure_time),
    tust.arrival_time,
    tust.departure_time,
    tust.schedule_relationship,
    st.stop_headsign,
    st.data_origin,
-- this is awful dont do this in prod kids
    COALESCE(t.headsign, 
   concat((SELECT stops.name FROM public.stop_times2
        inner join stops on stops.id = stop_times2.stop_id and stops.data_origin = stop_times2.data_origin
        where trip_id = t.id and  stops.data_origin = t.data_origin
        ORDER BY stop_sequence desc
        limit 1), ' (?)')),
            t.short_name,
    s.platform_code,
    s.platform_code,
    t.service_id,
    r.short_name,
    r.long_name,
    COALESCE(a.name, 'Unknown agency'),
    r.url,
    r.type::text,
    r.description,
    r.color,
    r.text_color,
    s.stop_type,
    (tust.trip_id IS NOT NULL OR pe.trip_id IS NOT NULL)
FROM
    stops s
    -- START with the stops table and filter down to the one we want. This is the crucial change.
    INNER JOIN stop_times2 st ON s.id = st.stop_id AND s.data_origin = st.data_origin
    INNER JOIN trips t ON st.trip_id = t.id AND st.data_origin = t.data_origin
    INNER JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
    CROSS JOIN target_date_range d
    LEFT JOIN agencies a ON r.agency_id = a.id AND r.data_origin = a.data_origin
    LEFT JOIN trip_updates_stop_times tust ON t.id = tust.trip_id AND tust.data_origin = t.data_origin AND tust.stop_id = s.id
    LEFT JOIN position_entities pe ON t.id = pe.trip_id AND pe.data_origin = t.data_origin
WHERE
    -- 1. Primary filter: Find the stop(s) we care about.
    s.internal_id IN (SELECT related_stop FROM related_stops WHERE primary_stop = target_stop_id)
    AND s.stop_type = target_stop_type
    -- 2. Filter by time
    AND (d.start_of_day + st.departure_time) >= from_time
    -- 3. Ensure it's not the last stop on the trip
    AND EXISTS (
      SELECT 1 FROM stop_times2 st2
      WHERE st2.data_origin = st.data_origin AND st2.trip_id = st.trip_id AND st2.stop_sequence > st.stop_sequence
      LIMIT 1
    )
    -- 4. NEW and EFFICIENT service check logic
    AND (
        -- Check if service is active in the regular calendar
        EXISTS (
            SELECT 1 FROM public.calendars c
            WHERE c.service_id = t.service_id AND c.data_origin = t.data_origin
              AND d.start_of_day >= c.start_date AND d.start_of_day <= c.end_date -- Sargable
              AND CASE EXTRACT(DOW FROM d.start_of_day)::integer
                    WHEN 0 THEN c.sunday WHEN 1 THEN c.monday WHEN 2 THEN c.tuesday
                    WHEN 3 THEN c.wednesday WHEN 4 THEN c.thursday WHEN 5 THEN c.friday
                    ELSE c.saturday
                  END
        )
        OR
        -- OR check if it's an added exception
        EXISTS (
            SELECT 1 FROM public.calendar_dates cd
            WHERE cd.service_id = t.service_id AND cd.data_origin = t.data_origin
              AND cd.exception_type = 'Added'
              AND cd.date >= d.start_of_day AND cd.date < d.end_of_day -- Sargable
        )
    )
    -- 5. AND ensure the service is NOT a removed exception
    AND NOT EXISTS (
        SELECT 1 FROM public.calendar_dates cd
        WHERE cd.service_id = t.service_id AND cd.data_origin = t.data_origin
          AND cd.exception_type = '2'
          AND cd.date >= d.start_of_day AND cd.date < d.end_of_day -- Sargable
    )
ORDER BY
    (d.start_of_day + st.arrival_time) ASC
LIMIT 100;
$BODY$;
