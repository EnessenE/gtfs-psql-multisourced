DROP FUNCTION IF EXISTS public.get_map_shapes_in_bounds(double precision, double precision, double precision, double precision, integer, integer);
DROP FUNCTION IF EXISTS public.get_map_shapes_in_bounds(double precision, double precision, double precision, double precision, integer, integer, boolean);

CREATE OR REPLACE FUNCTION public.get_map_shapes_in_bounds(
    p_min_lat double precision,
    p_max_lat double precision,
    p_min_lon double precision,
    p_max_lon double precision,
    p_shape_limit integer DEFAULT 200,
    p_zoom integer DEFAULT 8,
    p_full_shapes boolean DEFAULT false
)
RETURNS TABLE(
    id text,
    data_origin text,
    latitude double precision,
    longitude double precision,
    sequence bigint
)
LANGUAGE sql
STABLE PARALLEL SAFE
AS $BODY$
    -- Step 1: find up to p_shape_limit distinct shape IDs that have at least one
    -- point inside the viewport, using ix_shapes_lat_lon (btree) for a fast scan.
    WITH shape_ids AS (
        SELECT DISTINCT s.id, s.data_origin
        FROM public.shapes s
        WHERE s.latitude  BETWEEN p_min_lat AND p_max_lat
          AND s.longitude BETWEEN p_min_lon AND p_max_lon
        LIMIT GREATEST(1, LEAST(p_shape_limit, 3000))
    )
    -- Step 2: return downsampled points for those shapes.
    -- p_full_shapes=false  → clip to viewport (only points inside the bbox).
    -- p_full_shapes=true   → return the entire shape even if it extends outside.
    SELECT
        s.id,
        s.data_origin,
        s.latitude,
        s.longitude,
        s.sequence
    FROM public.shapes s
    INNER JOIN shape_ids si ON si.id = s.id AND si.data_origin = s.data_origin
    WHERE mod(
            s.sequence,
            CASE
                WHEN p_zoom <= 6 THEN 64
                WHEN p_zoom = 7 THEN 32
                WHEN p_zoom = 8 THEN 16
                WHEN p_zoom = 9 THEN 8
                WHEN p_zoom = 10 THEN 4
                ELSE 2
            END
        ) = 0
      AND (p_full_shapes
           OR (s.latitude  BETWEEN p_min_lat AND p_max_lat
               AND s.longitude BETWEEN p_min_lon AND p_max_lon));
$BODY$;

ALTER FUNCTION public.get_map_shapes_in_bounds(double precision, double precision, double precision, double precision, integer, integer, boolean)
    OWNER TO postgres;