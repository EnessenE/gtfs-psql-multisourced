CREATE OR REPLACE FUNCTION public.get_shapes_from_trip(target uuid)
    RETURNS TABLE(
        id text,
        latitude double precision,
        longitude double precision,
        "sequence" bigint
,
            distance_travelled double precision,
            data_origin character varying(100))
        LANGUAGE 'sql'
        COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
        AS $BODY$
    with trip_data AS (
        SELECT * from trips 
		WHERE trips.internal_id = target LIMIT 1
    )
    SELECT
        shapes.id,
        latitude,
        longitude,
        "sequence",
        distance_travelled,
        shapes.data_origin
    FROM
        shapes
    WHERE
        shapes.id = (select shape_id from trip_data limit 1)
    ORDER BY
        "sequence" DESC
$BODY$;

select * from get_shapes_from_trip('be98ccb6-12c0-46a8-995c-4642d4069968')