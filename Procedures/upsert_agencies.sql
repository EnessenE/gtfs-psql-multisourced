DROP PROCEDURE IF EXISTS public.upsert_agencies(
    public.agencies_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_agencies(
    _agencies public.agencies_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO public.agencies AS target
    USING (
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
            last_updated,
            import_id
        FROM (
            SELECT DISTINCT ON (id, data_origin)
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
                last_updated,
                import_id
            FROM UNNEST(_agencies)
            ORDER BY id, data_origin, last_updated DESC
        ) AS deduplicated
    ) AS source
    ON target.id = source.id 
       AND target.data_origin = source.data_origin
    WHEN MATCHED THEN
        UPDATE SET
            name = source.name,
            url = source.url,
            timezone = source.timezone,
            language_code = source.language_code,
            phone = source.phone,
            fare_url = source.fare_url,
            email = source.email,
            internal_id = source.internal_id,
            last_updated = source.last_updated,
            import_id = source.import_id
    WHEN NOT MATCHED THEN
        INSERT (
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
            last_updated, 
            import_id
        )
        VALUES (
            source.data_origin, 
            source.id, 
            source.name, 
            source.url, 
            source.timezone, 
            source.language_code, 
            source.phone, 
            source.fare_url, 
            source.email, 
            source.internal_id, 
            source.last_updated, 
            source.import_id
        );
END;
$$;
