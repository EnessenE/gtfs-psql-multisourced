-- FUNCTION: public.search_stop(text)
-- DROP FUNCTION IF EXISTS public.search_stop(text);
CREATE OR REPLACE FUNCTION public.search_stop(target text)
    RETURNS TABLE(
		id text,
        name text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT DISTINCT id, stops.name FROM public.related_stops
    inner join stops on related_stops.primary_stop = stops.id	
	WHERE  SIMILARITY(LOWER(stops.name), LOWER(target)) >= 0.4
LIMIT 25;
$BODY$;

ALTER FUNCTION public.search_stop(text) OWNER TO dennis;


SELECT * FROM public.search_stop('kome')