CREATE OR REPLACE PROCEDURE public.upsert_shapes(
    shapes public.shapes_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.shapes(
        internal_id, data_origin, id, sequence, latitude, longitude, geo_location, distance_travelled, last_updated, import_id
    )
    SELECT internal_id, data_origin, id, sequence, latitude, longitude, geo_location, distance_travelled, last_updated, import_id
    FROM shapes
    ON CONFLICT(id, data_origin) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        geo_location = EXCLUDED.geo_location,
        distance_travelled = EXCLUDED.distance_travelled,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;