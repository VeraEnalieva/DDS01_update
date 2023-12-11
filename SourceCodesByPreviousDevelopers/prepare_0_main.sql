-- Обрезание CutDistance М от Санкт-Петербурга
DO $$
  declare CutDistance integer;
  declare CutRegion text;
begin
  CutDistance := 10000;
  CutRegion := ' in  (''Санкт-Петербург'', ''Ленинградская область'')';

  drop table if exists reg_bnd;
  execute 'create TEMPORARY table reg_bnd as (
  with reg AS (
        select st_collect(f.way) as geom
        FROM (
		SELECT 1 as grp, osm_id, way
        	FROM public.planet_osm_polygon 
		where name '||CutRegion||' and boundary=''administrative''
	) As f
    	GROUP BY grp
  ), un as (  
	Select st_buffer(geom, '||CutDistance||') as geom from reg
	union all
	SELECT p.way FROM public.planet_osm_polygon p
	join osm_old.regions r on (r.admin_level = 6 and r.hand = ''handadd'' and (ST_AREA(ST_Intersection(p.way, r.geom)) / ST_AREA(r.geom)) between 0.95 and 1.05)
	WHERE p."boundary" = ''administrative'' and p.admin_level = ''6''
  )
  select st_union(un.geom) geom from un
  )';

  DELETE FROM public.planet_osm_line a USING reg_bnd b WHERE not st_intersects(b.geom, a.way);
  RAISE INFO 'Удалили все лишнее, по границе % км от % из таблицы planet_osm_line.', CutDistance/1000, CutRegion;

  DELETE FROM public.planet_osm_point a USING reg_bnd b WHERE not st_intersects(b.geom, a.way);
  RAISE INFO 'Удалили все лишнее, по границе % км от % из таблицы planet_osm_point.', CutDistance/1000, CutRegion;

  DELETE FROM public.planet_osm_polygon a USING reg_bnd b WHERE not st_intersects(b.geom, a.way);
  RAISE INFO 'Удалили все лишнее, по границе % км от % из таблицы planet_osm_polygon.', CutDistance/1000, CutRegion;

  update public.planet_osm_polygon p set way=st_intersection(p.way, r.geom) from (select * from reg_bnd) r WHERE st_intersects(r.geom, p.way);
  RAISE INFO 'Удалили все лишнее из таблицы planet_osm_polygon.';

  DELETE FROM public.planet_osm_polygon a WHERE GeometryType(a.way) = 'MULTILINESTRING';
  RAISE INFO 'Удалили границы соседних субъектов из таблицы planet_osm_polygon.';

  update public.planet_osm_polygon p set way=case when ST_IsValid(ST_Multi(ST_CollectionExtract(p.way, 3))) then ST_Multi(ST_CollectionExtract(p.way, 3)) else null end;
  DELETE FROM public.planet_osm_polygon WHERE way is null;

  DELETE FROM public.planet_osm_roads a USING reg_bnd b WHERE not st_intersects(b.geom, a.way);
  RAISE INFO 'Удалили все лишнее, по границе % км от % из таблицы planet_osm_roads.', CutDistance/1000, CutRegion;
end;

$$;
-- Создаем резервные копии
DROP TABLE IF EXISTS public.planet_osm_line_c, public.planet_osm_point_c, public.planet_osm_polygon_c, public.planet_osm_roads_c;

create table public.planet_osm_line_c as (select * from public.planet_osm_line);
DO $$ 
    BEGIN	
		RAISE INFO 'Создали резервную таблицу planet_osm_line_c.';    
	END;
$$;

create table public.planet_osm_point_c as (select * from public.planet_osm_point);
DO $$ 
	BEGIN	
		RAISE INFO 'Создали резервную таблицу planet_osm_point_c.';    
	END;
$$;

create table public.planet_osm_polygon_c as (select * from public.planet_osm_polygon);
DO $$ 
	BEGIN
		RAISE INFO 'Создали резервную таблицу planet_osm_polygon_c.';    
	END;
$$;

create table public.planet_osm_roads_c as (select * from public.planet_osm_roads);
DO $$ 
	BEGIN	
		RAISE INFO 'Создали резервную таблицу planet_osm_roads_c.';    
	END;
$$;

DO $$ 
    BEGIN	RAISE INFO 'Создали резервные таблицы.';    END;
$$;

