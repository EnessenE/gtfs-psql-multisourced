DROP FUNCTION IF EXISTS get_agencies_from_data_origin(text);

CREATE OR REPLACE FUNCTION public.get_agencies_from_data_origin(target_data_origin text)
    RETURNS TABLE(
        data_origin character,
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
    agencies
WHERE agencies.data_origin = target_data_origin
$BODY$;

SELECT
    *
FROM
    get_agencies_from_data_origin('OpenOV')
