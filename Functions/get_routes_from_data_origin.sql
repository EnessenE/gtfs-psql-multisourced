DROP FUNCTION IF EXISTS get_routes_from_data_origin(text);

CREATE OR REPLACE FUNCTION public.get_routes_from_data_origin(target_data_origin text)
    RETURNS TABLE(
        agency text,
        short_name text,
        long_name text,
        description text,
        type text,
        url text,
        color text,
        text_color text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
SELECT
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color
FROM
    routes
    LEFT JOIN agencies ON agencies.id = routes.agency_id
        AND agencies.data_origin = routes.data_origin
WHERE routes.data_origin = target_data_origin
GROUP BY
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color
ORDER BY
    short_name ASC
$BODY$;

SELECT
    *
FROM
    get_routes_from_data_origin('OpenOV')
