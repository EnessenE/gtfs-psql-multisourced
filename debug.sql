SELECT * FROM stops where id = '3067984' and data_origin = 'OpenOV'

DELETE FROM related_stops where primary_stop in 
(select primary_stop from related_stops inner join stops on stops.internal_id = related_stops.related_stop 
where stops.id = '3548632' and stops.data_origin = 'OpenOV')

call merge_stop2('3067984', 'OpenOV')


		(select primary_stop from related_stops inner join related_stops on stops.internal_id = related_stops.related_stop where stops.id = position_entities.stop_id and stops.data_origin = trips.data_origin),



select * from stops 
inner join routes on routes.route_id = related_stops.related_stop 
where stops.id = '78805' and stops.data_origin = 'renfe-commuter'


select distinct calendars.start_date, calendars.end_date from stop_times
inner join trips on stop_times.trip_id = trips.id
inner join calendars on calendars.service_id = trips.service_id

where stop_times.data_origin = 'renfe-commuter' and stop_id = '78805'
order by start_date asc
limit 500

select * from trips where id in ('5128S25600R1',
'5128S25601R1',
'5128S25602R1',
'5128S25603R1',
'5128S25604R1',
'5128S25606R1',
'5128S25607R1',
'5128S25608R1',
'5128S25611R1',
'5128S25612R1',
'5128S25613R1',
'5128S25615R1',
'5128S25616R1'
)and data_origin = 'renfe-commuter' 

select * from calendars where service_id = '5128S' and data_origin = 'renfe-commuter' 

'5128S25600R1'
'5128S25601R1'
'5128S25602R1'
'5128S25603R1'
'5128S25604R1'
'5128S25606R1'
'5128S25607R1'
'5128S25608R1'
'5128S25611R1'
'5128S25612R1'
'5128S25613R1'
'5128S25615R1'
'5128S25616R1'


