CREATE OR REPLACE PROCEDURE public.upsert_alert_entities(
    entities_input public.alert_entity_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.alert_entities (
        data_origin,
        id,
        alert_id,
        last_updated,
        agency_id,
        route_id,
        trip_id,
        stop_id
    )
    SELECT DISTINCT ON (
        data_origin,
        id, 
        internal_id, 
        agency_id, 
        route_id, 
        trip_id, 
        stop_id
    )
        data_origin,
        id, 
        internal_id,
        last_updated,
        agency_id,
        route_id,
        trip_id,
        stop_id
    FROM UNNEST(entities_input)
    -- This ORDER BY ensures that if there are duplicates in the input,
    -- we take the one with the newest timestamp.
    ORDER BY 
        data_origin, id, internal_id, agency_id, route_id, trip_id, stop_id, 
        last_updated DESC
    ON CONFLICT ON CONSTRAINT uq_alert_entities_logical 
    DO UPDATE SET
        last_updated = EXCLUDED.last_updated;
END;
$$;