-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.search_stop(text);
CREATE OR REPLACE FUNCTION public.search_stop(target text)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        longitude double precision,
        latitude double precision)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH found_primaries AS (SELECT DISTINCT
        primary_stop,
		stop_type
    FROM
        public.related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.internal_id
    WHERE
        SIMILARITY(stops.name, LOWER(target)) >= 0.3
	GROUP BY primary_stop, stop_type)
    select         
            stops.name,
            stops.stop_type,
            primary_stop as id,
            longitude,
            latitude 
	from stops
    INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
    where related_stops.primary_stop in (select primary_stop from found_primaries)
    ORDER BY SIMILARITY(stops.name, LOWER(target)) DESC
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
