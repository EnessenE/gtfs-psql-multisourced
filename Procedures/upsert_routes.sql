DROP PROCEDURE IF EXISTS public.upsert_routes;

CREATE OR REPLACE PROCEDURE public.upsert_routes(
    _routes public.routes_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.routes (
        data_origin, id, agency_id, short_name, long_name, description, type, url, color, text_color, internal_id, last_updated, import_id
    )
    SELECT 
        _route.data_origin, 
        _route.id, 
        _route.agency_id, 
        _route.short_name, 
        _route.long_name, 
        _route.description, 
        _route.route_type, 
        _route.url, 
        _route.color, 
        _route.text_color, 
        _route.internal_id, 
        _route.last_updated, 
        _route.import_id
    FROM UNNEST(_routes) AS _route
    ON CONFLICT (id, data_origin) DO UPDATE
    SET 
        agency_id = EXCLUDED.agency_id,
        short_name = EXCLUDED.short_name,
        long_name = EXCLUDED.long_name,
        description = EXCLUDED.description,
        type = _route.type,
        url = EXCLUDED.url,
        color = EXCLUDED.color,
        text_color = EXCLUDED.text_color,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;
