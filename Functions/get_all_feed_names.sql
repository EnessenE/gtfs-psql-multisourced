CREATE OR REPLACE FUNCTION public.get_all_feed_names()
 RETURNS TABLE(name text)
 LANGUAGE sql
 STABLE
AS $function$
    SELECT supplier_configurations.name
    FROM public.supplier_configurations
    WHERE supplier_configurations.name IS NOT NULL
      AND btrim(supplier_configurations.name) <> ''
    ORDER BY supplier_configurations.name;
$function$

