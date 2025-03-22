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
		stop_times int,
		trips int,
		realtime bool)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        supplier_configurations.name,
        supplier_configurations.polling_rate,
        supplier_configurations.last_updated,
        supplier_configurations.download_pending,
        supplier_configurations.last_attempt,
        supplier_configurations.last_checked,
		(select count(*) from stops where stops.data_origin = supplier_configurations.name) stops,
		(select count(*) from routes where routes.data_origin = supplier_configurations.name) routes,
		(select count(*) from agencies where agencies.data_origin = supplier_configurations.name) agencies,
		-- (select count(*) from stop_times2 where stop_times2.data_origin = supplier_configurations.name) stop_times,
        0,
		(select count(*) from trips where trips.data_origin = supplier_configurations.name) trips,
		(select count(*) from realtime_configurations where realtime_configurations.supplier_configuration_name = supplier_configurations.name AND realtime_configurations.enabled) > 0
    FROM
        public.supplier_configurations
$BODY$;

ALTER FUNCTION public.get_all_feeds() OWNER TO dennis;

select * from get_all_feeds();