DROP FUNCTION IF EXISTS public.get_routes_near_point(double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION public.get_routes_near_point(
    p_lat  double precision,
    p_lon  double precision,
    p_bbox double precision DEFAULT 0.01
)
RETURNS TABLE(
    data_origin text,
    id          text,
    short_name  text,
    long_name   text,
    color       text,
    text_color  text,
    agency      text,
    type        text
)
LANGUAGE sql
STABLE PARALLEL SAFE
AS $BODY$
    -- Step 1: use the btree ix_shapes_lat_lon index to cheaply find all distinct
    -- shape IDs that have at least one point inside the bounding box around the click.
    WITH nearby_shapes AS (
        SELECT DISTINCT s.id, s.data_origin
        FROM public.shapes s
        WHERE s.latitude  BETWEEN p_lat - p_bbox AND p_lat + p_bbox
          AND s.longitude BETWEEN p_lon - p_bbox AND p_lon + p_bbox
    )
    -- Step 2: resolve shape IDs -> trips -> routes.
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
    INNER JOIN nearby_shapes ns
        ON  ns.id          = t.shape_id
        AND ns.data_origin = t.data_origin
    INNER JOIN routes r
        ON  r.id          = t.route_id
        AND r.data_origin = t.data_origin
    LEFT JOIN agencies a
        ON  a.id          = r.agency_id
        AND a.data_origin = r.data_origin
    ORDER BY r.short_name
    LIMIT 40;
$BODY$;

ALTER FUNCTION public.get_routes_near_point(double precision, double precision, double precision)
    OWNER TO postgres;
