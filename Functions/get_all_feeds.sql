drop function get_all_feeds();

CREATE OR REPLACE FUNCTION public.get_all_feeds()
    RETURNS TABLE(
        name text,
        "interval" interval,
        last_updated timestamp with time zone,
        download_pending boolean,
        last_attempt timestamp with time zone,
        last_checked timestamp with time zone,
		stops int,
		routes int,
		agencies int,
		trips int)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        name,
        polling_rate,
        last_updated,
        download_pending,
        last_attempt,
        last_checked,
		(select count(*) from stops where stops.data_origin = supplier_configurations.name) stops,
		(select count(*) from routes where routes.data_origin = supplier_configurations.name) routes,
		(select count(*) from agencies where agencies.data_origin = supplier_configurations.name) agencies,
		(select count(*) from trips where trips.data_origin = supplier_configurations.name) trips
    FROM
        public.supplier_configurations;
$BODY$;

ALTER FUNCTION public.get_all_feeds() OWNER TO dennis;