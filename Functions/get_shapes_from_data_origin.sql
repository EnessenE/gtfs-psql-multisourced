DROP FUNCTION get_shapes_from_data_origin(text);

CREATE OR REPLACE FUNCTION public.get_shapes_from_data_origin(target_data_origin text)
    RETURNS TABLE(
		id text,
        latitude double precision,
        longitude double precision)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
		id,
        latitude,
        longitude
    FROM
        shapes
    WHERE
    shapes.data_origin = target_data_origin and sequence % 2 <> 0
	order by sequence desc
$BODY$;

SELECT
    *
FROM
    get_shapes_from_data_origin('OpenOV')
