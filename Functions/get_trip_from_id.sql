
DROP FUNCTION IF EXISTS public.get_trip_from_id(target uuid);

CREATE OR REPLACE FUNCTION public.get_trip_from_id(target uuid)
    RETURNS TABLE(
        id text,
        route_id text,
        service_id text,
        headsign text,
        short_name text,
        direction int,
        block_id text,
        data_origin text,
        latitude double precision,
        longitude double precision,
        current_status text,
        congestion_level text,
        occupancy_status text,
        occupancy_percentage integer,
        measurement_time timestamp with time zone,
        enroute_to text,
		target_stop_id uuid,
		target_stop text,
		route_short_name text,
		route_long_name text
		)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT
        trips.id,
        route_id,
        service_id,
        headsign,
        trips.short_name,
        direction,
        block_id,
        trips.data_origin,
		position_entities.latitude,
		position_entities.longitude,
		position_entities.current_status,
		position_entities.congestion_level,
		position_entities.occupancy_status,
		position_entities.occupancy_percentage,
		position_entities.measurement_time,
 	    (select primary_stop from related_stops inner join stops on stops.internal_id = related_stops.related_stop where stops.id = position_entities.stop_id and stops.data_origin = trips.data_origin limit 1),		
		stops.internal_id,
		stops.name,
		routes.short_name,
		routes.long_name
    FROM
        trips
	LEFT JOIN routes on routes.data_origin = trips.data_origin and routes.id = trips.route_id
	LEFT JOIN position_entities on position_entities.data_origin = trips.data_origin and position_entities.trip_id = trips.id
	LEFT JOIN stops on stops.data_origin = trips.data_origin and position_entities.stop_id = stops.id
    WHERE
        trips.internal_id = target
$BODY$;

select * from get_trip_from_id('a515fae9-3087-4412-94c7-8b42d292c29b');