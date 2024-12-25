-- Upsert Procedure for Agencies
CREATE OR REPLACE PROCEDURE public.upsert_agencies(
    agencies public.agencies_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.agencies(
        data_origin, id, name, url, timezone, language_code, phone, fare_url, email, internal_id, last_updated, import_id
    )
    SELECT data_origin, id, name, url, timezone, language_code, phone, fare_url, email, internal_id, last_updated, import_id
    FROM agencies
    ON CONFLICT(id, data_origin) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
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