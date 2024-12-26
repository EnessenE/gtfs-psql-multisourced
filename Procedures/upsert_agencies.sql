DROP PROCEDURE upsert_agencies(agencies_type[]);
CREATE OR REPLACE PROCEDURE public.upsert_agencies(
    _agencies public.agencies_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.agencies(
        data_origin, id, name, url, timezone, language_code, phone, fare_url, email, internal_id, last_updated, import_id
    )
    SELECT 
        agency.data_origin,
        agency.id,
        agency.name,
        agency.url,
        agency.timezone,
        agency.language_code,
        agency.phone,
        agency.fare_url,
        agency.email,
        agency.internal_id,
        agency.last_updated,
        agency.import_id
    FROM unnest(_agencies) AS agency
    ON CONFLICT (id, data_origin) 
    DO UPDATE
    SET
        name = EXCLUDED.name,
        url = EXCLUDED.url,
        timezone = EXCLUDED.timezone,
        language_code = EXCLUDED.language_code,
        phone = EXCLUDED.phone,
        fare_url = EXCLUDED.fare_url,
        email = EXCLUDED.email,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;