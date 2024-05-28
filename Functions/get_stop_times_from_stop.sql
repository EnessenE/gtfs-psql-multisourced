-- FUNCTION: public.get_stop_times_from_stop(text)

-- DROP FUNCTION IF EXISTS public.get_stop_times_from_stop(text);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(
	target text)
    RETURNS TABLE("TripId" text, "ArrivalTime" text, "DepartureTime" text, "StopHeadsign" text, "DataOrigin" text, "Headsign" text, "ShortName" text, "ServiceId" text, "RouteShortName" text, "RouteLongName" text) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

select stop_times."TripId", stop_times."ArrivalTime", stop_times."DepartureTime", stop_times."StopHeadsign", stop_times."DataOrigin", trips."Headsign", trips."ShortName", trips."ServiceId", routes."ShortName", routes."LongName" 
from stop_times
inner join trips on stop_times."TripId" = trips."Id"
inner join routes on trips."RouteId" = routes."Id"
WHERE "StopId" = target
LIMIT 100;

$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(text)
    OWNER TO dennis;
