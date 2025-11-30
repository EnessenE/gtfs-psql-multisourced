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
LANGUAGE sql
STABLE
PARALLEL SAFE
ROWS 100
AS $$
WITH day_context AS (
  SELECT date_trunc('day', from_time) AS service_date
)
SELECT
    t.internal_id::text,
    
    -- Planned times converted correctly to UTC
    (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.arrival_time)::int,
            EXTRACT(MINUTE FROM st.arrival_time)::int,
            EXTRACT(SECOND FROM st.arrival_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS arrival_time,
    
    (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.departure_time)::int,
            EXTRACT(MINUTE FROM st.departure_time)::int,
            EXTRACT(SECOND FROM st.departure_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS departure_time,
    
    -- Return same planned times
    (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.arrival_time)::int,
            EXTRACT(MINUTE FROM st.arrival_time)::int,
            EXTRACT(SECOND FROM st.arrival_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS planned_arrival_time,
    
    (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.departure_time)::int,
            EXTRACT(MINUTE FROM st.departure_time)::int,
            EXTRACT(SECOND FROM st.departure_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' AS planned_departure_time,

    tust.arrival_time,
    tust.departure_time,
    tust.schedule_relationship,
    st.stop_headsign,
    st.data_origin,
    --dont do this in prod kids
    COALESCE(
        t.headsign,
        concat(
            (SELECT stops.name
             FROM stop_times2
             JOIN stops ON stops.id = stop_times2.stop_id AND stops.data_origin = stop_times2.data_origin
             WHERE stop_times2.trip_id = t.id AND stop_times2.data_origin = t.data_origin
             ORDER BY stop_sequence DESC
             LIMIT 1),
            ' (?)')
    ),
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
    INNER JOIN stop_times2 st ON s.id = st.stop_id AND s.data_origin = st.data_origin
    INNER JOIN trips t ON st.trip_id = t.id AND st.data_origin = t.data_origin
    INNER JOIN day_context dc ON TRUE
    INNER JOIN routes r ON t.route_id = r.id AND t.data_origin = r.data_origin
    LEFT JOIN agencies a ON r.agency_id = a.id AND r.data_origin = a.data_origin
    LEFT JOIN trip_updates_stop_times tust ON t.id = tust.trip_id AND tust.data_origin = t.data_origin AND tust.stop_id = s.id
    LEFT JOIN position_entities pe ON t.id = pe.trip_id AND pe.data_origin = t.data_origin
WHERE
    s.internal_id IN (
        SELECT related_stop FROM related_stops WHERE primary_stop = target_stop_id
    )
    AND s.stop_type = target_stop_type
    AND st.departure_time IS NOT NULL
    AND (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.departure_time)::int,
            EXTRACT(MINUTE FROM st.departure_time)::int,
            EXTRACT(SECOND FROM st.departure_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC' >= now()

    AND EXISTS (
        SELECT 1 FROM stop_times2 st2
        WHERE st2.data_origin = st.data_origin AND st2.trip_id = st.trip_id AND st2.stop_sequence > st.stop_sequence
        LIMIT 1
    )
    AND (
        EXISTS (
            SELECT 1 FROM calendars c
            WHERE c.service_id = t.service_id AND c.data_origin = t.data_origin
              AND dc.service_date BETWEEN c.start_date AND c.end_date
              AND CASE EXTRACT(DOW FROM dc.service_date)::int
                   WHEN 0 THEN c.sunday WHEN 1 THEN c.monday WHEN 2 THEN c.tuesday
                   WHEN 3 THEN c.wednesday WHEN 4 THEN c.thursday WHEN 5 THEN c.friday
                   ELSE c.saturday
              END
        )
        OR EXISTS (
            SELECT 1 FROM calendar_dates cd
            WHERE cd.service_id = t.service_id AND cd.data_origin = t.data_origin
              AND cd.date = dc.service_date AND cd.exception_type = 'Added'
        )
    )
    AND NOT EXISTS (
        SELECT 1 FROM calendar_dates cd
        WHERE cd.service_id = t.service_id AND cd.data_origin = t.data_origin
          AND cd.date = dc.service_date AND cd.exception_type = 'Removed'
    )
ORDER BY
    (
        make_timestamp(
            EXTRACT(YEAR FROM dc.service_date)::int,
            EXTRACT(MONTH FROM dc.service_date)::int,
            EXTRACT(DAY FROM dc.service_date)::int,
            EXTRACT(HOUR FROM st.arrival_time)::int,
            EXTRACT(MINUTE FROM st.arrival_time)::int,
            EXTRACT(SECOND FROM st.arrival_time)
        ) AT TIME ZONE COALESCE(a.timezone, 'UTC')
    ) AT TIME ZONE 'UTC'
LIMIT 100;
$$;
