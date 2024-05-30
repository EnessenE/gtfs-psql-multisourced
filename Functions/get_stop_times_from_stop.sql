-- FUNCTION: public.get_stop_times_from_stop(text, time without time zone, date)

-- DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(text, time without time zone, date);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(
	target text,
	fromtime time without time zone,
	fromdate date)
    RETURNS TABLE(tripid text, arrivaltime time without time zone, departuretime time without time zone, stopheadsign text, dataorigin text, headsign text, shortname text, platform text, serviceid text, routeshortname text, routelongname text, operator text) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

	
	with stopdata as (SELECT
	    id
	FROM
	    stops
	where
	    LOWER(id) = LOWER(target)
	),
	stopdata2 as (SELECT
	    parentstation
	FROM
	    stops
	where
	    LOWER(id) = LOWER(target)
		and
		parentstation != ''
	)
	
	select stop_times.tripid, stop_times.arrivaltime, stop_times.departuretime, stop_times.stopheadsign, stop_times.dataorigin, trips.headsign, trips.shortname, stops.platformcode, trips.serviceid, routes.shortname, routes.longname, agencies.name 
	from stop_times
	inner join trips on stop_times.tripid = trips.id
	inner join stops on stop_times.stopid = stops.id
	inner join routes on trips.routeid = routes.id
	inner join agencies on routes.agencyid = agencies.id
	inner join calendar_dates on trips.serviceid = calendar_dates.serviceid
	where (( parentstation != '' and parentstation = COALESCE((select parentstation from stopdata2 limit 1), (select id from stopdata limit 1))) or stopid = (select id from stopdata limit 1)) and stop_times.arrivaltime > fromtime and calendar_dates.date::date = fromdate
	ORDER BY ArrivalTime asc	
LIMIT 100;

$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(text, time without time zone, date)
    OWNER TO dennis;

select * from get_stop_times_from_stop('stoparea:18188', '12:34', '2024-05-30');