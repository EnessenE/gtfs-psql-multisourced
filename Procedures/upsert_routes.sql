
-- Upsert Procedure for Routes
CREATE OR REPLACE PROCEDURE public.upsert_routes(
    routes public.routes_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.routes(
        data_origin, id, agency_id, short_name, long_name, description, type, url, color, text_color, internal_id, last_updated, import_id
    )
    SELECT data_origin, id, agency_id, short_name, long_name, description, type, url, color, text_color, internal_id, last_updated, import_id
    FROM routes
    ON CONFLICT(id, data_origin) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        agency_id = EXCLUDED.agency_id,
        short_name = EXCLUDED.short_name,
        long_name = EXCLUDED.long_name,
        description = EXCLUDED.description,
        type = EXCLUDED.type,
        url = EXCLUDED.url,
        color = EXCLUDED.color,
        text_color = EXCLUDED.text_color,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;