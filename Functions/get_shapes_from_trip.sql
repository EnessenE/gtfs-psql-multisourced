CREATE
OR REPLACE FUNCTION public.get_shapes_from_trip(target text) RETURNS TABLE(
    id text,
    latitude double precision,
    longitude double precision,
    sequence bigint,
    distancetravelled double precision,
    dataorigin character varying (100)
) LANGUAGE 'sql' COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000 
AS $BODY$
SELECT
    id,
    latitude,
    longitude,
    sequence,
    distancetravelled,
    dataorigin
FROM
    shapes
where
    id = target
$BODY$;