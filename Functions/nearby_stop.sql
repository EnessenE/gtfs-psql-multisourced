-- FUNCTION: public.search_stop(text)
DROP FUNCTION IF EXISTS public.nearby_stops(double precision, double precision);

CREATE OR REPLACE FUNCTION public.nearby_stops(x double precision, y double precision)
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
            stop_type != 1000
            AND ST_DWithin(stops.geo_location, ST_MakePoint(x, y), 1000, FALSE)
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
        stop_type != 1000
        AND related_stops.primary_stop IN(
            SELECT
                primary_stop
            FROM
                found_primaries
    WHERE
        stop_type != 1000)
    GROUP BY
        stops.name,
        stops.stop_type,
        primary_stop
    LIMIT 100;
$BODY$;

ALTER FUNCTION public.nearby_stops(double precision, double precision) OWNER TO dennis;

SELECT
    *
FROM
    public.nearby_stops(51.794179, 4.653556)
