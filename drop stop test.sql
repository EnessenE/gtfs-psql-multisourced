SELECT * FROM stops where id = '3067984' and data_origin = 'OpenOV'

DELETE FROM related_stops where primary_stop in 
(select primary_stop from related_stops inner join stops on stops.internal_id = related_stops.related_stop 
where stops.id = '3067984' and stops.data_origin = 'OpenOV')
call merge_stop2('3067984', 'OpenOV')


		(select primary_stop from related_stops inner join related_stops on stops.internal_id = related_stops.related_stop where stops.id = position_entities.stop_id and stops.data_origin = trips.data_origin),
