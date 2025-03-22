drop function if exists get_all_realtime_feeds();

CREATE OR REPLACE FUNCTION public.get_all_realtime_feeds()
    RETURNS TABLE(
        supplier_configuration_name text,
        url text,
        polling_rate interval,
		last_attempt timestamp with time zone,
        enabled boolean,
        header text,
        header_secret text)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        supplier_configuration_name,
        url,
        polling_rate,
        last_attempt,
        enabled,
        header,
        header_secret
    FROM
        public.realtime_configurations;
$BODY$;

ALTER FUNCTION public.get_all_realtime_feeds() OWNER TO dennis;