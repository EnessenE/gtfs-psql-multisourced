-- FUNCTION: public.search_stop(text)
-- DROP FUNCTION IF EXISTS public.search_stop(text);
CREATE OR REPLACE FUNCTION public.search_stop(target text)
    RETURNS TABLE(
        id text,
        name text,
        parent_station text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        id,
        name,
        parent_station
    FROM
        stops
    WHERE(parent_station IS NULL
        OR parent_station = '')
    AND LOWER(name)
    LIKE CONCAT('%', TRIM(target), '%')
LIMIT 25;
$BODY$;

ALTER FUNCTION public.search_stop(text) OWNER TO dennis;

