A PostgresQL GTFS database that support GTFS data from multiple external sources.<br>
Originally made with EF-Core so you may see some oddities still remain. It is, and stays a hobby-project.
<br>
For example:
- Data is imported from data supplier 1 for country 1
- Data is imported from data supplier 2 for country 2
- Data is imported from data supplier 3 for country 1
- Data is imported from data supplier 4 for country 1 and 2
- Data is imported from data supplier 5 for country 2 and 3
- Data is imported from data supplier 6 for country 1
<br>
All data imported should be available, uniquely distinguishable and easily/quickly reachable.<br>
<br>

We accomplish showing correct data by essentially adding additional relational data between supplier data. Incase supplier 1 delivers us data for stop_1 and stop_2. Then supplier 2 will will deliver data for stop_3 and stop_4. But in reality stop_1 and stop_3 are the same and stop_2 and stop_4 are the same. Yet no connection exist in the data sets delivered. <br>

To make sure we can correlate this data we pre-process this by checking if any related data is available based on some predetermined arbitrary factors like GPS position, name etc. 
