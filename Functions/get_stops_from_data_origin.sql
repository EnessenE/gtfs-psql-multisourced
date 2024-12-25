DROP FUNCTION get_stops_from_data_origin(text);

CREATE OR REPLACE FUNCTION public.get_stops_from_data_origin(target_data_origin text)
    RETURNS TABLE(
        name text,
        stop_type int,
        id text,
        coordinates double precision[])
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH found_primaries AS(
        SELECT DISTINCT
            primary_stop,
            stop_type
        FROM
            public.related_stops
            INNER JOIN stops ON related_stops.related_stop = stops.internal_id
        WHERE
            stops.data_origin = target_data_origin
        GROUP BY
            primary_stop,
            stop_type
)
    SELECT
        stops.name,
        stops.stop_type,
        primary_stop AS id,
        array_agg(ARRAY[longitude, latitude]) AS coordinates
    FROM
        stops
        INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
    WHERE
		stops.data_origin = target_data_origin
		AND
        related_stops.primary_stop IN(
            SELECT
                primary_stop
            FROM
                found_primaries)
    GROUP BY
        stops.name,
        stops.stop_type,
        primary_stop
    ORDER BY
        stops.name DESC
$BODY$;

ALTER FUNCTION public.get_stops_from_data_origin(text) OWNER TO dennis;

SELECT
    *
FROM
    get_stops_from_data_origin('sncf-tgv');

