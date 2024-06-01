-- FUNCTION: public.get_trip_from_id(text)
-- DROP FUNCTION IF EXISTS public.get_trip_from_id(text);
CREATE OR REPLACE FUNCTION public.get_stop_from_id(target text)
    RETURNS TABLE(
        id text,
        code text,
        name text,
        description text,
        latitude double precision,
        longitude double precision,
        zone text,
        location_type text,
        parent_station text,
        platform_code text,
        data_origin text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1
    AS $BODY$
    SELECT
        id,
        code,
        name,
        description,
        latitude,
        longitude,
        zone,
        location_type,
        parent_station,
        platform_code,
        data_origin
    FROM
        stops
    WHERE
        id = target
$BODY$;

ALTER FUNCTION public.get_stop_from_id(text) OWNER TO dennis;

