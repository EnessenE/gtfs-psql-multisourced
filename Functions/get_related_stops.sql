CREATE OR REPLACE FUNCTION public.get_related_stops(
	target text)
    RETURNS TABLE(id text, code text, name text, description text, latitude double precision, longitude double precision, zone text, locationtype text, parentstation text, platformcode text, dataorigin text) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

WITH stopdata AS (SELECT
	id, parentstation
FROM
	stops
WHERE
	lower(id) = lower(target)
)
	
SELECT
    id, code, name, description, latitude, longitude, zone, locationtype, parentstation, platformcode, dataorigin
FROM
    stops
where
    parentstation = (select id from stopdata) OR (parentstation != '' and parentstation = (select parentstation from stopdata)) OR id = (select parentstation from stopdata)
$BODY$;

ALTER FUNCTION public.get_related_stops(text)
    OWNER TO dennis;


select * from get_related_stops('S8819406')
