CREATE OR REPLACE FUNCTION public.get_train_station_performance()
    RETURNS TABLE(
        primary_stop_id uuid,
        stop_id text,
        stop_name text,
        stop_type text,
        data_origin text,
        latitude double precision,
        longitude double precision,
        on_time_percentage numeric,
        on_time_count bigint,
        delay_count bigint,
        cancellation_count bigint,
        total_trips_count bigint
    )
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$
WITH train_stations AS (
    SELECT DISTINCT ON (rs.primary_stop, s.data_origin)
        rs.primary_stop AS primary_stop_id,
        s.id AS stop_id,
        s.name AS stop_name,
        s.data_origin,
        s.latitude,
        s.longitude,
        s.last_updated
    FROM public.related_stops rs
    INNER JOIN public.stops s
        ON s.internal_id = rs.related_stop
       AND s.data_origin = rs.related_data_origin
    WHERE s.stop_type BETWEEN 100 AND 117
    ORDER BY rs.primary_stop, s.data_origin, s.last_updated DESC
),
recent_updates AS (
    SELECT
        rs.primary_stop,
        tust.data_origin,
        ROW_NUMBER() OVER (
            PARTITION BY rs.primary_stop, tust.data_origin
            ORDER BY tust.last_updated DESC
        ) AS rn,
        CASE
            WHEN lower(COALESCE(tust.schedule_relationship, '')) IN ('skipped', 'canceled') THEN 1
            ELSE 0
        END AS is_cancel,
        CASE
            WHEN lower(COALESCE(tust.schedule_relationship, '')) NOT IN ('skipped', 'canceled')
                AND COALESCE(tust.departure_delay, tust.arrival_delay, 0) > 0 THEN 1
            ELSE 0
        END AS is_delay
    FROM public.trip_updates_stop_times tust
    INNER JOIN public.stops s
        ON s.id = tust.stop_id
       AND s.data_origin = tust.data_origin
    INNER JOIN public.related_stops rs
        ON rs.related_stop = s.internal_id
    WHERE s.stop_type BETWEEN 100 AND 117
),
aggregated AS (
    SELECT
        ru.primary_stop,
        ru.data_origin,
        COUNT(*)::bigint AS total_trips_count,
        SUM(ru.is_delay)::bigint AS delay_count,
        SUM(ru.is_cancel)::bigint AS cancellation_count
    FROM recent_updates ru
    WHERE ru.rn <= 100
    GROUP BY ru.primary_stop, ru.data_origin
)
SELECT
    ts.primary_stop_id,
    ts.stop_id,
    ts.stop_name,
    'Train'::text AS stop_type,
    ts.data_origin,
    ts.latitude,
    ts.longitude,
    CASE
        WHEN COALESCE(ag.total_trips_count, 0) = 0 THEN 100::numeric
        ELSE ROUND(
            GREATEST(
                0,
                (
                    (COALESCE(ag.total_trips_count, 0)
                    - COALESCE(ag.delay_count, 0)
                    - COALESCE(ag.cancellation_count, 0)
                    )::numeric
                    / COALESCE(ag.total_trips_count, 1)::numeric
                ) * 100
            ),
            2
        )
    END AS on_time_percentage,
    GREATEST(
        0,
        COALESCE(ag.total_trips_count, 0)
        - COALESCE(ag.delay_count, 0)
        - COALESCE(ag.cancellation_count, 0)
    )::bigint AS on_time_count,
    COALESCE(ag.delay_count, 0)::bigint AS delay_count,
    COALESCE(ag.cancellation_count, 0)::bigint AS cancellation_count,
    COALESCE(ag.total_trips_count, 0)::bigint AS total_trips_count
FROM train_stations ts
LEFT JOIN aggregated ag
    ON ag.primary_stop = ts.primary_stop_id
   AND ag.data_origin = ts.data_origin
ORDER BY on_time_percentage ASC, cancellation_count DESC, delay_count DESC, stop_name ASC;
$BODY$;

ALTER FUNCTION public.get_train_station_performance()
    OWNER TO postgres;
