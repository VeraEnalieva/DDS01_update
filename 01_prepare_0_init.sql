DROP TABLE IF EXISTS public.planet_osm_line_dc, public.planet_osm_point_dc, public.planet_osm_polygon_dc, public.planet_osm_roads_dc;
create table public.planet_osm_line_dc as (select * from public.planet_osm_line WHERE public.planet_osm_line.highway is null);
DO $$
    BEGIN
		RAISE INFO 'Создали резервную таблицу planet_osm_line_dc.';
	END;
$$;

create table public.planet_osm_point_dc as (select * from public.planet_osm_point);
DO $$
	BEGIN
		RAISE INFO 'Создали резервную таблицу planet_osm_point_dc.';
	END;
$$;

create table public.planet_osm_polygon_dc as (select * from public.planet_osm_polygon);
DO $$
	BEGIN
		RAISE INFO 'Создали резервную таблицу planet_osm_polygon_dc.';
	END;
$$;

create table public.planet_osm_roads_dc as (select * from public.planet_osm_line WHERE public.planet_osm_line.highway is not null);
DO $$
	BEGIN
		RAISE INFO 'Создали резервную таблицу planet_osm_roads_dc.';
	END;
$$;
create table public.planet_osm_roads as (select * from public.planet_osm_line WHERE public.planet_osm_line.highway is not null);
DO $$
	BEGIN
		RAISE INFO 'Создали основную таблицу planet_osm_roads.';
	END;
$$;