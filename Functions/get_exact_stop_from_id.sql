CREATE OR REPLACE FUNCTION public.get_exact_stop_from_id(target_id text, target_data_origin text)
    RETURNS TABLE(
        id text,
        code text,q
        name text,
        description text,
        latitude double precision,
        longitude double precision,
        zone text,
        location_type text,
        parent_station text,
        platform_code text,
        data_origin text,
        stop_type int,
        last_updated timestamp with time zone,
        primary_stop uuid)
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
        data_origin,
        stop_type,
        last_updated,
        related_stops.primary_stop
    FROM
        related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.internal_id
            AND related_stops.related_data_origin = stops.data_origin
    WHERE(stops.id = target_id
        AND stops.data_origin = target_data_origin)
LIMIT 1
$BODY$;

