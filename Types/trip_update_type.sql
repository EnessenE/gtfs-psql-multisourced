-- Type: trip_update_type

-- DROP TYPE IF EXISTS public.trip_update_type;

CREATE TYPE public.trip_update_type AS
(
	data_origin text,
	internal_id uuid,
	id text,
	trip_id text,
	last_updated timestamp with time zone,
	delay integer,
	schedule_relationship text,
	vehicle_id text,
	vehicle_label text,
	vehicle_license_plate text,
	vehicle_wheelchair_accessible text,
	measurement_time timestamp with time zone
);
