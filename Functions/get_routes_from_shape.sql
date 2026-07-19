DROP FUNCTION IF EXISTS public.get_routes_from_shape(text, text);

CREATE OR REPLACE FUNCTION public.get_routes_from_shape(
    p_data_origin text,
    p_shape_id text
)
RETURNS TABLE(
    data_origin text,
    id text,
    short_name text,
    long_name text,
    color text,
    text_color text,
    agency text,
    type text
)
LANGUAGE sql
STABLE PARALLEL SAFE
AS $BODY$
    SELECT DISTINCT
        r.data_origin,
        r.id,
        r.short_name,
        r.long_name,
        r.color,
        r.text_color,
        COALESCE(a.name, 'Unknown') AS agency,
        r.type::text
    FROM trips t
    INNER JOIN routes r
        ON r.id     = t.route_id
       AND r.data_origin = t.data_origin
    LEFT JOIN agencies a
        ON a.id          = r.agency_id
       AND a.data_origin = r.data_origin
    WHERE t.shape_id    = p_shape_id
      AND t.data_origin = p_data_origin
    ORDER BY r.short_name
    LIMIT 30;
$BODY$;

ALTER FUNCTION public.get_routes_from_shape(text, text)
    OWNER TO postgres;
