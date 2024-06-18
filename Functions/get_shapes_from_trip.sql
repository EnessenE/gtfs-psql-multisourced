CREATE OR REPLACE FUNCTION public.get_shapes_from_trip(target text)
    RETURNS TABLE(
        id text,
        latitude double precision,
        longitude double precision,
        SEQUENCE bigint
,
            distance_travelled double precision,
            data_origin character varying(100))
        LANGUAGE 'sql'
        COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
        AS $BODY$
    SELECT
        shapes.id,
        latitude,
        longitude,
        SEQUENCE,
        distance_travelled,
        shapes.data_origin
    FROM
        shapes
        INNER JOIN trips ON trips.shape_id = shapes.id
    WHERE
        LOWER(trips.internal_id::text) = LOWER(target)
    ORDER BY sequence DESC
$BODY$;

