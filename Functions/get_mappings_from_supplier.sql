-- FUNCTION: public.get_trip_from_id(text)
CREATE OR REPLACE FUNCTION public.get_mappings_from_supplier(target text)
    RETURNS TABLE(
        listed_type integer,
        new_type integer,
        supplier_configuration_name text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1
    AS $BODY$
    SELECT
        listed_type,
        new_type,
        supplier_configuration_name
    FROM
        public.supplier_type_mapping
    WHERE
        supplier_configuration_name = target;
$BODY$;

ALTER FUNCTION public.get_mappings_from_supplier(text) OWNER TO dennis;

