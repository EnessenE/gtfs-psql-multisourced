CREATE OR REPLACE FUNCTION public.get_stops_from_data_origin_in_bounds(
    target_data_origin text,
    p_min_lat double precision,
    p_max_lat double precision,
    p_min_lon double precision,
    p_max_lon double precision,
    p_limit integer DEFAULT 8000)
 RETURNS TABLE(name text, stop_type integer, id text, coordinates double precision[])
 LANGUAGE sql
 STABLE PARALLEL SAFE
AS $function$
WITH in_bounds AS (
    SELECT
        rs.primary_stop,
        s.stop_type,
        s.name,
        s.longitude,
        s.latitude,
        s.last_updated
    FROM public.related_stops rs
    INNER JOIN public.stops s
        ON rs.related_stop = s.internal_id
       AND rs.related_data_origin = s.data_origin
    WHERE s.data_origin = target_data_origin
      AND s.latitude BETWEEN p_min_lat AND p_max_lat
      AND s.longitude BETWEEN p_min_lon AND p_max_lon
),
limited_primary AS (
    SELECT primary_stop
    FROM in_bounds
    GROUP BY primary_stop
    ORDER BY MAX(last_updated) DESC
    LIMIT GREATEST(0, LEAST(p_limit, 20000))
)
SELECT
    MAX(ib.name) AS name,
    ib.stop_type,
    ib.primary_stop::text AS id,
    array_agg(ARRAY[ib.longitude, ib.latitude]) AS coordinates
FROM in_bounds ib
INNER JOIN limited_primary lp
    ON lp.primary_stop = ib.primary_stop
GROUP BY ib.primary_stop, ib.stop_type
ORDER BY MAX(ib.last_updated) DESC;
$function$
