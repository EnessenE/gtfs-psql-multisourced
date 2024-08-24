CREATE OR REPLACE FUNCTION public.get_routes_from_stop(target uuid, target_stop_type int)
    RETURNS TABLE(
        data_origin text,
        id text,
        agency text,
        short_name text,
        long_name text,
        description text,
        type text,
        url text,
        color text,
        text_color text,
        internal_id uuid,
        last_updated timestamp with time zone,
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
    SELECT distinct
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
        route_id, data_origin
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
    routes.id,
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color,
    routes.internal_id,
    routes.last_updated,
    routes.import_id
FROM
    routes
LEFT JOIN agencies ON agencies.id = routes.agency_id and agencies.data_origin = routes.data_origin
WHERE(routes.id,
    routes.data_origin) IN(
        SELECT
            route_id,
            data_origin
        FROM
            trip_data)
			ORDER BY id, short_name asc
$BODY$;

ALTER FUNCTION public.get_routes_from_stop(uuid, int) OWNER TO dennis;

select * from get_routes_from_stop('75cbbb0d-7082-4395-a466-fedb4f04ba01', 1)
