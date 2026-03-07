
CREATE TYPE public.position_entity_type AS (
    data_origin text,
    last_updated timestamp with time zone,
    id text,
    trip_id text,
    latitude double precision,
    longitude double precision,
    stop_id text,
    current_status text,
    measurement_time timestamp with time zone,
    congestion_level text,
    occupancy_status text,
    occupancy_percentage integer
);


CREATE OR REPLACE PROCEDURE public.upsert_position_array(
    positions public.position_entity_type[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    position public.position_entity_type;
BEGIN
    FOREACH position IN ARRAY positions
    LOOP
        MERGE INTO public.position_entities
        USING (
            SELECT
                position.id AS id,
                position.data_origin AS data_origin,
                position.last_updated AS last_updated,
                position.trip_id AS trip_id,
                position.latitude AS latitude,
                position.longitude AS longitude,
                ST_SetSRID(
                    ST_MakePoint(position.longitude, position.latitude),
                    4326
                ) AS geo_location,
                position.stop_id AS stop_id,
                position.current_status AS current_status,
                position.measurement_time AS measurement_time,
                position.congestion_level AS congestion_level,
                position.occupancy_status AS occupancy_status,
                position.occupancy_percentage AS occupancy_percentage
        ) AS source_position
        ON (
            public.position_entities.data_origin = source_position.data_origin
            AND (
                public.position_entities.id = source_position.id
                OR public.position_entities.trip_id = source_position.trip_id
            )
        )
        WHEN MATCHED THEN
            UPDATE SET
                last_updated = source_position.last_updated,
                trip_id = COALESCE(
                    source_position.trip_id,
                    public.position_entities.trip_id
                ),
                latitude = source_position.latitude,
                longitude = source_position.longitude,
                geo_location = source_position.geo_location,
                stop_id = source_position.stop_id,
                current_status = source_position.current_status,
                measurement_time = source_position.measurement_time,
                congestion_level = source_position.congestion_level,
                occupancy_status = source_position.occupancy_status,
                occupancy_percentage = source_position.occupancy_percentage

        WHEN NOT MATCHED
             AND source_position.trip_id IS NOT NULL THEN
            INSERT (
                id,
                data_origin,
                last_updated,
                trip_id,
                latitude,
                longitude,
                geo_location,
                stop_id,
                current_status,
                measurement_time,
                congestion_level,
                occupancy_status,
                occupancy_percentage
            )
            VALUES (
                source_position.id,
                source_position.data_origin,
                source_position.last_updated,
                source_position.trip_id,
                source_position.latitude,
                source_position.longitude,
                source_position.geo_location,
                source_position.stop_id,
                source_position.current_status,
                source_position.measurement_time,
                source_position.congestion_level,
                source_position.occupancy_status,
                source_position.occupancy_percentage
            );
    END LOOP;
END;
$$;
