CREATE OR REPLACE FUNCTION public.get_related_stops(target text)
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
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH stop_data AS(
        SELECT
            id,
            parent_station
        FROM
            stops
        WHERE
            lower(id) = lower(target))
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
        parent_station =(
            SELECT
                id
            FROM
                stop_data)
        OR(parent_station != ''
            AND parent_station =(
                SELECT
                    parent_station
                FROM
                    stop_data))
        OR id =(
            SELECT
                parent_station
            FROM
                stop_data)
$BODY$;

ALTER FUNCTION public.get_related_stops(text) OWNER TO dennis;

SELECT
    *
FROM
    get_related_stops('S8819406')
