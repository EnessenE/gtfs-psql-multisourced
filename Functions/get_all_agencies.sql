CREATE OR REPLACE FUNCTION public.get_all_agencies()
    RETURNS TABLE(
    data_origin text,
    id text,
    name text,
    url text,
    timezone text,
    language_code text,
    phone text,
    fare_url text,
    email text,
    internal_id uuid,
    last_updated timestamp with time zone
    )
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        data_origin,
        id,
        name,
        url,
        timezone,
        language_code,
        phone,
        fare_url,
        email,
        internal_id,
        last_updated
    FROM
        public.agencies;
$BODY$;

ALTER FUNCTION public.get_all_agencies() OWNER TO dennis;

