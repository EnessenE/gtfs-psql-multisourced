
drop function get_all_feeds();

CREATE OR REPLACE FUNCTION public.get_all_feeds()
    RETURNS TABLE(
        name text,
        "interval" interval,
        download_pending boolean,
        last_checked timestamp with time zone,
        "state" text,
        last_check_failure timestamp with time zone,
        last_import_start timestamp with time zone,
        last_import_success timestamp with time zone,
        last_import_failure timestamp with time zone,
		stops int,
		routes int,
		agencies int,
		trips int,
		alerts int,
		vehicles int,
		realtime bool)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        supplier_configurations.name,
        supplier_configurations.polling_rate,
        supplier_configurations.download_pending,
        supplier_configurations.last_checked,
        supplier_configurations.state,
        supplier_configurations.last_check_failure,
        supplier_configurations.last_import_start,
        supplier_configurations.last_import_success,
        supplier_configurations.last_import_failure,
		(select count(*) from stops where stops.data_origin = supplier_configurations.name) stops,
		(select count(*) from routes where routes.data_origin = supplier_configurations.name) routes,
		(select count(*) from agencies where agencies.data_origin = supplier_configurations.name) agencies,
		-- (select count(*) from stop_times2 where stop_times2.data_origin = supplier_configurations.name) stop_times,
		(select count(*) from trips where trips.data_origin = supplier_configurations.name) trips,
		(select count(*) from alerts where alerts.data_origin = supplier_configurations.name) alerts,
		(select count(*) from position_entities where position_entities.data_origin = supplier_configurations.name) vehicles,
		(select count(*) from realtime_configurations where realtime_configurations.supplier_configuration_name = supplier_configurations.name AND realtime_configurations.enabled) > 0
    FROM
        public.supplier_configurations
$BODY$;


select * from get_all_feeds();