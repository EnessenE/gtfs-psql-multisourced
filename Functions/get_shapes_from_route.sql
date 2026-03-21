DROP FUNCTION IF EXISTS get_shapes_from_route(text, text);

CREATE OR REPLACE FUNCTION public.get_shapes_from_route(target_data_origin text, target_route_id text)
    RETURNS TABLE(
        latitude double precision,
        longitude double precision,
        sequence bigint,
        distance_travelled double precision)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH matched_route AS (
        SELECT
            routes.id,
            routes.data_origin
        FROM
            routes
        WHERE
            routes.data_origin = target_data_origin
            AND (
                routes.id = target_route_id
                OR routes.short_name = target_route_id
            )
        ORDER BY
            CASE WHEN routes.id = target_route_id THEN 0 ELSE 1 END,
            routes.last_updated DESC
        LIMIT 1
    ),
    ranked_shape AS (
        SELECT
            trips.shape_id,
            trips.data_origin,
            MAX(shapes.distance_travelled) AS max_distance,
            MAX(shapes.sequence) AS max_sequence,
            COUNT(*) AS point_count
        FROM
            trips
            INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
                AND trips.route_id = matched_route.id
            INNER JOIN shapes ON shapes.id = trips.shape_id
                AND shapes.data_origin = trips.data_origin
                AND shapes.import_id = trips.import_id
        WHERE
            trips.shape_id IS NOT NULL
        GROUP BY
            trips.shape_id,
            trips.data_origin
        ORDER BY
            MAX(shapes.distance_travelled) DESC NULLS LAST,
            MAX(shapes.sequence) DESC,
            COUNT(*) DESC,
            trips.shape_id ASC
        LIMIT 1
    )
    SELECT
        shapes.latitude,
        shapes.longitude,
        shapes.sequence,
        shapes.distance_travelled
    FROM
        ranked_shape
        INNER JOIN shapes ON shapes.id = ranked_shape.shape_id
            AND shapes.data_origin = ranked_shape.data_origin
    ORDER BY
        shapes.sequence ASC
$BODY$;