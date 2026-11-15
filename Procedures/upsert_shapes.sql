-- PROCEDURE: public.upsert_shapes(shapes_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_shapes(shapes_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_shapes(
    IN _shapes public.shapes_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Perform a single bulk insert for all rows in the _shapes array
    INSERT INTO public.shapes (
        data_origin, id, sequence, latitude, longitude, distance_travelled, last_updated, import_id
    )
    SELECT 
        _shape.data_origin, 
        _shape.id, 
        _shape.sequence_data,  -- Use _sequence_data from the array
        _shape.latitude, 
        _shape.longitude, 
        _shape.distance_travelled, 
        _shape.last_updated, 
        _shape.import_id
    FROM UNNEST(_shapes) AS _shape
    ON CONFLICT (data_origin, id, sequence, import_id) 
    DO NOTHING;  -- Ignore the conflict, effectively skipping duplicate entries
END;
$$;

ALTER PROCEDURE public.upsert_shapes(shapes_type[])
    OWNER TO postgres;
