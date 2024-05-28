-- FUNCTION: public.search_stop(text)

-- DROP FUNCTION IF EXISTS public.search_stop(text);

CREATE OR REPLACE FUNCTION public.search_stop(
	target text)
    RETURNS TABLE("Id" text, "Name" text, "ParentStation" text) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

select "Id", "Name", "ParentStation"  from stops
WHERE ("ParentStation" is null or "ParentStation" = '') AND LOWER("Name") LIKE CONCAT('%', TRIM(target), '%') 
LIMIT 25;

$BODY$;

ALTER FUNCTION public.search_stop(text)
    OWNER TO dennis;
