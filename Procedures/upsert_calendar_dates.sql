DROP PROCEDURE IF EXISTS public.upsert_calendar_dates;

CREATE OR REPLACE PROCEDURE public.upsert_calendar_dates(
    _calendar_dates public.calendar_dates_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO public.calendar_dates AS target
    USING (
        SELECT 
            data_origin, 
            service_id, 
            date, 
            exception_type_data AS exception_type, 
            internal_id, 
            last_updated, 
            import_id
        FROM (
            SELECT DISTINCT ON (data_origin, service_id, date)
                data_origin,
                service_id,
                date,
                exception_type_data,
                internal_id,
                last_updated,
                import_id
            FROM UNNEST(_calendar_dates)
            ORDER BY data_origin, service_id, date, last_updated DESC
        ) AS deduplicated
    ) AS source
    ON target.data_origin = source.data_origin 
       AND target.service_id = source.service_id
       AND target.date = source.date
    WHEN MATCHED THEN
        UPDATE SET
            exception_type = source.exception_type,
            internal_id = source.internal_id,
            last_updated = source.last_updated,
            import_id = source.import_id
    WHEN NOT MATCHED THEN
        INSERT (
            data_origin, 
            service_id, 
            date, 
            exception_type, 
            internal_id, 
            last_updated, 
            import_id
        )
        VALUES (
            source.data_origin, 
            source.service_id, 
            source.date, 
            source.exception_type, 
            source.internal_id, 
            source.last_updated, 
            source.import_id
        );
END;
$$;
