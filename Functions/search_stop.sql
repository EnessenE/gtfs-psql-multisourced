-- FUNCTION: public.search_stop(text)

-- DROP FUNCTION IF EXISTS public.search_stop(text);


CREATE OR REPLACE FUNCTION public.search_stop(target text)
RETURNS TABLE(
    name text, 
    stop_type integer, 
    id text, 
    coordinates double precision[]
) 
LANGUAGE 'sql'
COST 100
VOLATILE PARALLEL SAFE
ROWS 1000
AS $$
WITH filtered_stops AS (
    SELECT 
        rs.primary_stop,
        s.name,
        s.stop_type,
        ARRAY[s.longitude, s.latitude] AS coordinate,
        strict_word_similarity(s.name, LOWER(target)) AS similarity
    FROM 
        public.related_stops rs
    JOIN 
        public.stops s ON rs.related_stop = s.internal_id
    WHERE 
        s.stop_type != 1000
        AND strict_word_similarity(s.name, LOWER(target)) >= 0.4
)
SELECT 
    name,
    stop_type,
    primary_stop AS id,
    ARRAY_AGG(coordinate) AS coordinates
FROM 
    filtered_stops
GROUP BY 
    name, stop_type, primary_stop
ORDER BY 
    MAX(similarity) DESC
LIMIT 100;
$$;

ALTER FUNCTION public.search_stop(text)
    OWNER TO dennis;
SELECT
    *
FROM
    public.search_stop('Rotterdam')
    -- select * from stops stops
    --     INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
    -- where primary_stop = 'afbb0f2a-0f49-43c3-bc1f-73ce2f9731df'
