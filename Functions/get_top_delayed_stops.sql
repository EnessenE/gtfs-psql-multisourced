-- Function: get_top_delayed_stops()
-- Description: Returns the top 10 stations with the biggest average delay at the current moment
-- Over the most recent 100 delay records per stop, plus stations with most cancellations

DROP FUNCTION IF EXISTS public.get_top_delayed_stops();

CREATE OR REPLACE FUNCTION public.get_top_delayed_stops()
    RETURNS TABLE (
        primary_stop_id uuid,
        stop_id text,
        stop_name text,
        stop_type bigint,
        data_origin text,
        average_delay integer,
        delay_count bigint,
        cancellation_count bigint,
        max_delay integer,
        min_delay integer
    ) AS $$
BEGIN
    RETURN QUERY
    WITH
    delay_and_cancel AS (
        SELECT
            rs.primary_stop as primary_stop_id,
            stops.id as stop_id,
            stops.name as stop_name,
            stops.stop_type::bigint,
            tust.data_origin,
            CAST(AVG(CASE WHEN tust.is_delay THEN COALESCE(tust.departure_delay, tust.arrival_delay, 0) END) AS integer) as average_delay,
            SUM(CASE WHEN tust.is_delay THEN 1 ELSE 0 END) as delay_count,
            SUM(CASE WHEN tust.is_cancel THEN 1 ELSE 0 END) as cancellation_count,
            MAX(CASE WHEN tust.is_delay THEN COALESCE(tust.departure_delay, tust.arrival_delay, 0) END) as max_delay,
            MIN(CASE WHEN tust.is_delay THEN COALESCE(tust.departure_delay, tust.arrival_delay, 0) END) as min_delay
        FROM (
            SELECT
                tust_inner.data_origin,
                tust_inner.stop_id,
                tust_inner.trip_id,
                tust_inner.last_updated,
                tust_inner.departure_delay,
                tust_inner.arrival_delay,
                tust_inner.departure_time,
                tust_inner.arrival_time,
                tust_inner.schedule_relationship,
                    (lower(tust_inner.schedule_relationship) in ('skipped', 'canceled')) as is_cancel,
                    ((lower(tust_inner.schedule_relationship) not in ('skipped', 'canceled')) AND (tust_inner.departure_delay IS NOT NULL OR tust_inner.arrival_delay IS NOT NULL)) as is_delay,
                ROW_NUMBER() OVER (PARTITION BY tust_inner.stop_id, tust_inner.data_origin ORDER BY tust_inner.last_updated DESC) as rn
            FROM (
                SELECT
                    trip_updates_stop_times.data_origin,
                    trip_updates_stop_times.stop_id,
                    trip_updates_stop_times.trip_id,
                    trip_updates_stop_times.last_updated,
                    trip_updates_stop_times.departure_delay,
                    trip_updates_stop_times.arrival_delay,
                    trip_updates_stop_times.departure_time,
                    trip_updates_stop_times.arrival_time,
                    trip_updates_stop_times.schedule_relationship
                FROM trip_updates_stop_times
                WHERE
                    (lower(schedule_relationship) in ('skipped', 'canceled')
                        OR (lower(schedule_relationship) not in ('skipped', 'canceled') AND (departure_delay IS NOT NULL OR arrival_delay IS NOT NULL)))
                    AND COALESCE(
                        departure_time AT TIME ZONE 'UTC',
                        arrival_time AT TIME ZONE 'UTC'
                    ) >= NOW() AT TIME ZONE 'UTC'
                    AND COALESCE(
                        departure_time AT TIME ZONE 'UTC',
                        arrival_time AT TIME ZONE 'UTC'
                    ) <= (NOW() + INTERVAL '5 hours') AT TIME ZONE 'UTC'
            ) tust_inner
        ) tust
        INNER JOIN stops ON stops.id = tust.stop_id AND stops.data_origin = tust.data_origin
        INNER JOIN related_stops rs ON stops.internal_id = rs.related_stop
        WHERE tust.rn <= 100 
        GROUP BY
            rs.primary_stop,
            stops.id,
            stops.name,
            stops.stop_type,
            tust.data_origin
        HAVING SUM(CASE WHEN tust.is_delay THEN 1 ELSE 0 END) > 0 OR SUM(CASE WHEN tust.is_cancel THEN 1 ELSE 0 END) > 0
    )
    SELECT
        delay_and_cancel.primary_stop_id,
        delay_and_cancel.stop_id,
        delay_and_cancel.stop_name,
        delay_and_cancel.stop_type,
        delay_and_cancel.data_origin,
        delay_and_cancel.average_delay,
        delay_and_cancel.delay_count,
        delay_and_cancel.cancellation_count,
        delay_and_cancel.max_delay,
        delay_and_cancel.min_delay
    FROM delay_and_cancel
    ORDER BY
        delay_and_cancel.cancellation_count DESC,
        delay_and_cancel.delay_count DESC,
        delay_and_cancel.average_delay DESC,
        delay_and_cancel.data_origin
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;


select * from public.get_top_delayed_stops()
