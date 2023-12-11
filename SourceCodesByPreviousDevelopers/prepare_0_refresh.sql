delete from public.planet_osm_line where true;
insert into public.planet_osm_line (select * from public.planet_osm_line_dc);
delete from public.planet_osm_point where true;
insert into public.planet_osm_point (select * from public.planet_osm_point_dc);
delete from public.planet_osm_polygon where true;
insert into public.planet_osm_polygon (select * from public.planet_osm_polygon_dc);
delete from public.planet_osm_roads where true;
insert into public.planet_osm_roads (select * from public.planet_osm_roads_dc);