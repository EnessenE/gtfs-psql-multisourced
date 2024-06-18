CREATE OR REPLACE FUNCTION public.get_trip_from_id(target text)
    RETURNS TABLE(
        id text,
        route_id text,
        service_id text,
        headsign text,
        short_name text,
        direction int,
        block_id text,
        data_origin text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        id,
        route_id,
        service_id,
        headsign,
        short_name,
        direction,
        block_id,
        data_origin
    FROM
        trips
    WHERE
        internal_id = target
$BODY$;

