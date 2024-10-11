-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.search_stop(text);

CREATE OR REPLACE FUNCTION public.search_stop(target text)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        coordinates double precision[])
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
 
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
