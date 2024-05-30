CREATE
OR REPLACE FUNCTION public.get_trip_from_id(target text) RETURNS TABLE(
    id text,
    routeid text,
    serviceid text,
    headsign text,
    shortname text,
    direction int,
    blockid text,
    dataorigin text
) LANGUAGE 'sql' COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000 
AS $BODY$
SELECT
    id,
    routeid,
    serviceid,
    headsign,
    shortname,
    direction,
    blockid,
    dataorigin
FROM
    trips
where
    id = target
$BODY$;