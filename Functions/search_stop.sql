-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.search_stop(text);
CREATE OR REPLACE FUNCTION public.search_stop(target text)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
    	coordinates DOUBLE PRECISION[])
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
WITH found_primaries AS (
    SELECT DISTINCT
        primary_stop,
        stop_type
    FROM
        public.related_stops
    INNER JOIN stops ON related_stops.related_stop = stops.internal_id
    WHERE
        stop_type != 1000
        AND SIMILARITY(stops.name, LOWER('Dordrecht')) >= 0.4
    GROUP BY primary_stop, stop_type
)
SELECT
    stops.name,
    stops.stop_type,
    primary_stop as id,
    array_agg(ARRAY[longitude, latitude]) as coordinates
FROM
    stops
INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
WHERE
    stop_type != 1000
    AND related_stops.primary_stop IN (SELECT primary_stop FROM found_primaries)
GROUP BY
    stops.name,
    stops.stop_type,
    primary_stop
ORDER BY
    SIMILARITY(stops.name, LOWER('Dordrecht')) DESC
LIMIT 100;

$BODY$;

ALTER FUNCTION public.search_stop(text) OWNER TO dennis;

SELECT
    *
FROM
    public.search_stop('Dordrecht')


-- select * from stops stops
--     INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
-- where primary_stop = 'afbb0f2a-0f49-43c3-bc1f-73ce2f9731df'
