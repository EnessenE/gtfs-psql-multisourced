-- FUNCTION: public.get_trip_from_id(text)
CREATE OR REPLACE FUNCTION public.get_stop_from_id(target uuid, target_stop_type int)
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
        data_origin text,
        stop_type int,
        last_updated timestamp with time zone)
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
        last_updated
    FROM
        related_stops
        INNER JOIN stops ON related_stops.related_stop = stops.internal_id
            AND related_stops.related_data_origin = stops.data_origin
    WHERE(primary_stop = target
        AND stop_type = target_stop_type)
LIMIT 1
$BODY$;

ALTER FUNCTION public.get_stop_from_id(uuid, int) OWNER TO dennis;

