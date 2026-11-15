-- One-time migration: add the GTFS-RT VehicleDescriptor fields to vehicle positions.
-- After this, recreate the dependent objects from the repo files:
--   Types/position_entity_type.sql        (fresh installs; prod uses ALTER TYPE below)
--   Procedures/upsert_position_array.sql
--   Functions/nearby_vehicles.sql
--   Functions/get_positions_from_data_origin.sql

ALTER TABLE public.position_entities
    ADD COLUMN IF NOT EXISTS vehicle_id text,
    ADD COLUMN IF NOT EXISTS vehicle_label text,
    ADD COLUMN IF NOT EXISTS vehicle_license_plate text;

-- Composite type used by upsert_position_array: attributes are appended at the end.
-- (ALTER TYPE ... ADD ATTRIBUTE has no IF NOT EXISTS, so guard manually.)
DO $$
BEGIN
    ALTER TYPE public.position_entity_type ADD ATTRIBUTE vehicle_id text;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
    ALTER TYPE public.position_entity_type ADD ATTRIBUTE vehicle_label text;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
    ALTER TYPE public.position_entity_type ADD ATTRIBUTE vehicle_license_plate text;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
