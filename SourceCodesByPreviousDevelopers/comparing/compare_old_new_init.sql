DROP TABLE IF EXISTS osm.forts_c, osm.cemetery_c, osm.buildings_c, osm.settlements_c, osm.water_c, osm.water_line_c, osm.bridges_c, osm.regions_c, osm.parks_c, osm.reserve_parks_c, osm.square_c, osm.railway_platform_c, osm.island_c, osm.highways_c, osm.roads_c, osm.milestone_point_c;

create table osm.forts_c as (select * from osm.forts);
create table osm.cemetery_c as (select * from osm.cemetery);
create table osm.settlements_c as (select * from osm.settlements);
create table osm.buildings_c as (select * from osm.buildings);
create table osm.water_c as (select * from osm.water);
create table osm.water_line_c as (select * from osm.water_line);
create table osm.bridges_c as (select * from osm.bridges);
create table osm.regions_c as (select * from osm.regions);
create table osm.parks_c as (select * from osm.parks);
create table osm.reserve_parks_c as (select * from osm.reserve_parks);
create table osm.square_c as (select * from osm.square);
create table osm.railway_platform_c as (select * from osm.railway_platform);
create table osm.island_c as (select * from osm.island);
create table osm.highways_c as (select * from osm.highways);
create table osm.roads_c as (select * from osm.roads);
create table osm.milestone_point_c as (select * from osm.milestone_point);