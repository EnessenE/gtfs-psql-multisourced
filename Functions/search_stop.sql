-- FUNCTION: public.search_stop(text)

-- DROP FUNCTION IF EXISTS public.search_stop(text);

CREATE OR REPLACE FUNCTION public.search_stop(
	target text)
    RETURNS TABLE(id text, name text, parentstation text) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

select id, name, parentstation  from stops
WHERE (parentstation is null or parentstation = '') AND LOWER(name) LIKE CONCAT('%', TRIM(target), '%') 
LIMIT 25;

$BODY$;

ALTER FUNCTION public.search_stop(text)
    OWNER TO dennis;
