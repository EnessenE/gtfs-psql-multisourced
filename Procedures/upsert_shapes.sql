DROP PROCEDURE IF EXISTS public.upsert_shapes;

CREATE OR REPLACE PROCEDURE public.upsert_shapes(
    _shapes public.shapes_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.shapes(
        internal_id, data_origin, id, sequence, latitude, longitude, geo_location, distance_travelled, last_updated, import_id
    )
    SELECT 
        _shape.internal_id, 
        _shape.data_origin, 
        _shape.id, 
        _shape.sequence_data, 
        _shape.latitude, 
        _shape.longitude, 
        ST_SetSRID(ST_MakePoint(_shape.longitude, _shape.latitude), 4326), 
        _shape.distance_travelled, 
        _shape.last_updated, 
        _shape.import_id
    FROM UNNEST(_shapes) AS _shape
    ON CONFLICT(id, data_origin, sequence) DO UPDATE
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
