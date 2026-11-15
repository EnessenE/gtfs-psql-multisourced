DROP FUNCTION IF EXISTS public.get_all_feed_names();

CREATE OR REPLACE FUNCTION public.get_all_feed_names()
RETURNS TABLE(name text)
LANGUAGE sql
STABLE
AS $BODY$
    SELECT supplier_configurations.name
    FROM public.supplier_configurations
    WHERE supplier_configurations.name IS NOT NULL
      AND btrim(supplier_configurations.name) <> ''
    ORDER BY supplier_configurations.name;
$BODY$;

SELECT * FROM public.get_all_feed_names();