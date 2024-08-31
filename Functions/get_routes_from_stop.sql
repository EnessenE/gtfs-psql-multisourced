-- FUNCTION: public.get_routes_from_stop(uuid, integer)
-- DROP FUNCTION IF EXISTS public.get_routes_from_stop(uuid, integer);
CREATE OR REPLACE FUNCTION public.get_routes_from_stop(target uuid, target_stop_type integer)
    RETURNS TABLE(
        data_origin text,
        agency text,
        short_name text,
        long_name text,
        description text,
        type text,
        url text,
        color text,
        text_color text,
        import_id uuid)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH primary_stop_data AS(
        SELECT
            id,
            data_origin
        FROM
            stops
            INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
        WHERE
            primary_stop = target
            AND stop_type = target_stop_type
),
stop_data AS(
    SELECT DISTINCT
        trip_id,
        data_origin
    FROM
        stop_times
    WHERE(stop_id,
        data_origin) IN(
        SELECT
            id,
            data_origin
        FROM
            primary_stop_data)
),
trip_data AS(
    SELECT DISTINCT
        route_id,
        data_origin
    FROM
        trips
    WHERE(id,
        data_origin) IN(
        SELECT
            trip_id,
            data_origin
        FROM
            stop_data))
SELECT
    routes.data_origin,
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color,
    routes.import_id
FROM
    routes
    LEFT JOIN agencies ON agencies.id = routes.agency_id
        AND agencies.data_origin = routes.data_origin
WHERE(routes.id,
    routes.data_origin) IN(
        SELECT
            route_id,
            data_origin
        FROM
            trip_data)
GROUP BY
    routes.data_origin,
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color,
    routes.import_id
ORDER BY
    short_name ASC
$BODY$;

ALTER FUNCTION public.get_routes_from_stop(uuid, integer) OWNER TO dennis;

