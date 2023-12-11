-- ####################################################################
-- -- Прописываем наименования региона, района, населенного пункта 
-- ####################################################################

DO $$ 
    BEGIN
	update osm.regions set
               name_orig  = name,
               geonim_name = geonim('region','name', name),
               geonim_type = lower(geonim('region','type', name))
	where name is not null;
	update osm.regions set name  = COALESCE(geonim_name||' '|| geonim_type, name) 
	where name is not null;
    END;
$$;
DO $$ 
    BEGIN
	RAISE INFO 'Исправили наименования регионов, районов, муниципалитетов .';
    END;
$$;

update osm.regions st set addr_reg = name where admin_level=4;
drop table if exists reg_bnd;
create TEMPORARY table reg_bnd as (
  select gid as reg_gid, name, geom from osm.regions where name is not null and admin_level = 4
);

ALTER TABLE IF EXISTS reg_bnd ADD PRIMARY KEY (reg_gid);
alter table IF EXISTS reg_bnd owner to postgres;

-- Прописываем наименование региона в районы и округа
update osm.regions st set addr_reg = rg.name, reg_id = rg.reg_gid
from 
(
 select s.gid, reg.reg_gid, reg.name from osm.regions s join reg_bnd reg on area50(reg.geom, s.geom) --ST_Contains(reg.geom, s.geom)
) rg
where st.gid = rg.gid  and admin_level > 4;
DO $$     
    BEGIN
	RAISE INFO 'Прописали наименование региона в районы и округа.';
    END;
$$;

drop table if exists dist_bnd;
create TEMPORARY table dist_bnd as (
  select gid as dist_gid, addr_reg, reg_id as reg_gid, geonim_name as name, geom from osm.regions where name is not null and admin_level in (5,6)
);
ALTER TABLE dist_bnd ADD PRIMARY KEY (dist_gid);
alter table dist_bnd owner to postgres;

-- -- Прописываем наименование города в районы СПБ
-- update osm.regions st set addr_city = rg.name 
-- from 
-- (
--  with reg as (select name, geom from osm.regions where admin_level=4 and ref in ('RU-SPE') ) -- ref in ('RU-SPE')  - список городов федерального значения
--  select s.gid, reg.name from osm.regions s join reg on ST_Contains(reg.geom, s.geom) and  s.addr_reg=reg.name
-- ) rg
-- where st.gid = rg.gid  and admin_level > 4;
-- DO $$     
--     BEGIN
-- 	RAISE INFO 'Прописали наименование города в районы СПБ.';
--     END;
-- $$;


-- Прописываем наименования района в округа и поселения
update osm.regions st set addr_district = rg.name, district_id = rg.dist_gid
from 
(
 select s.gid, reg.dist_gid, reg.name from osm.regions s right join dist_bnd reg on area50(reg.geom, s.geom) --ST_Contains(reg.geom, s.geom)
	and s.addr_reg=reg.addr_reg
) rg
where st.gid = rg.gid and admin_level > 6;
DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования района в округа и поселения.';
    END;
$$;

-- -- Прописываем наименования региона, района в населенные пункты
update osm.settlements st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.settlements )
 select s.gid, reg.reg_gid, reg.addr_reg, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- Прописываем наименования региона, района в населенные пункты
update osm.settlements st set addr_reg = rg.name, reg_id = rg.reg_gid
from ( with rd as (select gid, geom from osm.settlements where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;


DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в населенные пункты.';
    END;
$$;

-- -- Прописываем наименования вложенных населенных пунктов в населенные пункты
DO $$
  declare setl osm.settlements%rowtype;
begin
  update osm.settlements set updated = false,
                             addr_city = geonim_name,
                             addr_city_full = geonim_name,
                             fullname = ARRAY[geonim_name],
                             fullpath = ARRAY[gid],
                             geom_uniq = geom where true;
  for setl in select * from osm.settlements order by st_area(geom) desc
  LOOP
      update osm.settlements st set updated = true where st.gid = setl.gid;
      update osm.settlements st set geom_uniq = COALESCE(case when st_IsValid(su.geom_uniq) then su.geom_uniq else st.geom end, st.geom)
      from
      (
        with ug as (select st_Union(geom) as ugeom from osm.settlements where updated = false and area50(setl.geom, geom)) --st_contains(setl.geom, geom))
        select ST_MULTI(ST_CollectionExtract(ST_Difference(setl.geom, ugeom), 3)) as geom_uniq from ug
      ) su
      where st.gid = setl.gid;
      update osm.settlements st set fullname = array_append(st.fullname, setl.geonim_name),
                                    fullpath = array_append(st.fullpath, setl.gid)
      where updated = false and area50(setl.geom, geom);
      RAISE INFO '%',setl.name;
  END LOOP;
  update osm.settlements set addr_city = array_to_string(fullname, ',', ''),
                             addr_city_full = array_to_string(array_append(array_append(fullname, addr_district), addr_reg), ',', ''),
                             fullname = array_append(array_append(fullname, addr_district), addr_reg)
      where true;
end;
$$;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования вложенных населенных пунктов в населенные пункты.';
    END;
$$;

-- #################################################################################################
-- Временная таблица населенных пунктов
-- #################################################################################################
drop table if exists setl_bnd;
create TEMPORARY table setl_bnd as (
  select addr_reg, reg_id, addr_district, district_id, addr_city, gid as city_id, geom_uniq as geom from osm.settlements where name is not null
);
ALTER TABLE setl_bnd ADD PRIMARY KEY (city_id);
alter table setl_bnd owner to postgres;
-- #################################################################################################

-- -- osm.forts
-- -- Прописываем наименования региона, района, населенного пункта
update osm.forts st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.forts where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района 
update osm.forts st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.forts where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.forts st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.forts where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования региона, района, населенного пункта в osm.forts';
    END;
$$;

-- -- osm.cemetery
-- -- Прописываем наименования региона, района, населенного пункта
update osm.cemetery st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.cemetery where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.cemetery st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.cemetery where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.cemetery st set addr_reg = rg.name, reg_id = rg.reg_gid
from ( with rd as (select gid, geom from osm.cemetery where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.cemetery';
    END;
$$;

-- -- osm.water
-- -- Прописываем наименования региона, района, населенного пункта
update osm.water set name_orig  = name, name  = COALESCE(geonim('water','name', name)||' '||lower(geonim('water','type', name)), name)
where name is not null;

update osm.water st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.water where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.water st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.water where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.water st set addr_reg = rg.name, reg_id = rg.reg_gid
from ( with rd as (select gid, geom from osm.water where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.water';
    END;
$$;

-- -- osm.water_line
-- -- Прописываем наименования региона, района, населенного пункта
update osm.water_line set name_orig  = name, name  = COALESCE(geonim('water','name', name)||' '||lower(geonim('water','type', name)), name)
where name is not null;

update osm.water_line st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.water_line where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on length50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.water_line st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.water_line where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on length50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.water_line st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.water_line where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on length50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.water_line';
    END;
$$;

-- -- osm.bridges
-- -- Прописываем наименования региона, района, населенного пункта
update osm.bridges set name_orig  = name, name  = COALESCE(geonim('street','name', name)||' '||lower(geonim('street','type', name)), name)
where name is not null;

update osm.bridges st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.bridges where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.bridges st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.bridges where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.bridges st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.bridges where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.bridges';
    END;
$$;

-- -- osm.parks
-- -- Прописываем наименования региона, района, населенного пункта
update osm.parks set name_orig  = name, name  = COALESCE(geonim('street','name', name)||' '||lower(geonim('street','type', name)), name)
where name is not null;

update osm.parks st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.parks where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.parks st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.parks where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.parks st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.parks where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.parks';
    END;
$$;

-- -- osm.reserve_parks
-- -- Прописываем наименования региона, района, населенного пункта
update osm.reserve_parks set name_orig  = name, name  = COALESCE(geonim('street','name', name)||' '||lower(geonim('street','type', name)), name)
where name is not null;

update osm.reserve_parks st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.reserve_parks where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.reserve_parks st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.reserve_parks where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.reserve_parks st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.reserve_parks where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.reserve_parks';
    END;
$$;

-- -- osm.square
-- -- Прописываем наименования региона, района, населенного пункта
update osm.square set name_orig  = name, name  = COALESCE(geonim('street','name', name)||' '||lower(geonim('street','type', name)), name)
where name is not null;

update osm.square st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.square where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.square st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.square where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.square st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.square where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.square';
    END;
$$;

-- -- osm.island
-- -- Прописываем наименования региона, района, населенного пункта
update osm.island set name_orig  = name, name  = COALESCE(geonim('street','name', name)||' '||lower(geonim('street','type', name)), name)
where name is not null;

update osm.island st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.island where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.island st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.island where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.island st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.island where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on area50(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.island';
    END;
$$;

-- -- osm.railway_point
-- -- Прописываем наименования региона, района, населенного пункта
update osm.railway_point st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.railway_point where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on st_contains(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.railway_point st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.railway_point where district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on st_contains(reg.geom, s.geom)
) rg
where st.name is not null and  st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.railway_point st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.railway_point where reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on st_contains(reg.geom, s.geom)
) rg
where st.name is not null and st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.railway_point';
    END;
$$;

-- -- osm.highways
-- -- Прописываем наименования региона, района, населенного пункта
update osm.highways set geonim_type = lower(geonim('street','type', name)), geonim_name = geonim('street','name', name)
where name is not null;

update osm.highways set name_orig  = name, name  = COALESCE(geonim_name||' '||geonim_type, name)
where name is not null;

update osm.highways st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.highways where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.highways st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.highways where name is not null and district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.highways st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.highways where name is not null and reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.highways';
    END;
$$;

-- -- osm.roads
-- -- Прописываем наименования региона, района, населенного пункта
update osm.roads set geonim_type = lower(geonim('street','type', name)), geonim_name = geonim('street','name', name)
where name is not null;

update osm.roads set name_orig  = name, name  = COALESCE(geonim_name||' '||geonim_type, name)
where name is not null;

update osm.roads st set addr_reg = rg.addr_reg, reg_id = rg.reg_id, addr_district = rg.addr_district, district_id = rg.district_id, addr_city = rg.addr_city, city_id = rg.city_id
from ( with rd as (select gid, geom from osm.roads where name is not null)
 select s.gid, reg.* from rd s join setl_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

-- -- Прописываем наименования района
update osm.roads st set addr_reg = rg.addr_reg, reg_id = rg.reg_gid, addr_district = rg.name, district_id = rg.dist_gid
from ( with rd as (select gid, geom from osm.roads where name is not null and district_id is null)
 select s.gid, reg.addr_reg, reg.reg_gid, reg.dist_gid, reg.name from rd s join dist_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

-- -- Прописываем наименования региона
update osm.roads st set addr_reg = rg.name, reg_id=rg.reg_gid
from ( with rd as (select gid, geom from osm.roads where name is not null and reg_id is null)
 select s.gid, reg.reg_gid, reg.name from rd s join reg_bnd reg on length50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

DO $$     
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в osm.roads';
    END;
$$;

update osm.buildings set geonim_type =  lower(geonim('street','type', addr_street)), geonim_name = geonim('street','name', addr_street)
where addr_street is not null;

update osm.buildings set addr_street_orig  = addr_street, addr_street  = COALESCE(geonim_name||' '||geonim_type, addr_street)
where addr_street is not null;

DO $$
  declare setrec osm.settlements%rowtype;
begin
  for setrec in select * from osm.settlements where name is not null order by st_area(geom) desc
  LOOP
    update osm.buildings set addr_city = setrec.addr_city, addr_district = setrec.addr_district, addr_reg = setrec.addr_reg where st_contains(setrec.geom ,geom);
  END LOOP;
end
$$;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования населенного пункта в дома.';
    END;
$$;


-- Обновление километровых столбов
DO $$
    BEGIN
        update osm.milestone_point set distance = COALESCE(trim(regexp_replace(lower(distance), '([Kk]m|[Кк]м)', '')), trim(regexp_replace(lower(name), '([Kk]m|[Кк]м)', ''))) where true;
        update osm.milestone_point set name = distance || ' км' where true;
		update osm.milestone_point osmp set addr_street=p.name
		from
		(
			select oh.name as name, om.gid as gid  from osm.highways oh
			join osm.milestone_point om on (oh.name is not null and st_distance(oh.geom, om.geom) < 1)
		) p
		where osmp.gid = p.gid;
    END;
$$;
DO $$ 
    BEGIN
	RAISE INFO 'Обновили километровые столбы.';
    END;
$$;

update osm.regions set geom_uniq = geom where true;

/*DO $$
    BEGIN
	RAISE INFO 'Вырезали районы из регионов.';
    END;
$$;
*/
DO $$
    declare reg osm.regions%rowtype;
    begin
        for reg in select * from osm.regions
            LOOP
                update osm.regions st set geom_uniq = COALESCE(su.geom_uniq, st.geom)
                from
                    (
                        with ug as (select st_Union(geom) as ugeom
                        from osm.settlements where st_contains(reg.geom, geom))
                        select ST_MULTI(ST_CollectionExtract(ST_Difference(reg.geom, ugeom), 3)) as geom_uniq from ug
                    ) su
                where st.gid = reg.gid;
            END LOOP;
    end;
$$;


DO $$
    BEGIN
	RAISE INFO 'Вырезали населенные пункты из регионов.';
    END;
$$;

---------------------------
--Удаление таблиц                                                                          
  DROP TABLE IF EXISTS osm.settlements_name, osm.water_name, osm.regions_name, osm.parks_name, osm.reserve_parks_name, 
  osm.square_name, osm.industrial_name, osm.commercial_name, osm.education_name, 
  osm.island_name;

DO $$ 
    BEGIN
	RAISE INFO 'Удалили таблицы.';
    END;
$$;

---------------------------
-- Строим таблицу Населенных пунктов 
CREATE TABLE osm.settlements_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    admin_level smallint,
    geom geometry(Point,3857),
    CONSTRAINT settlements_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.settlements_name OWNER to postgres;

insert into osm.settlements_name (gid, osm_id, name, admin_level, geom)
select gid, osm_id, name, admin_level, st_centroid(geom) from osm.settlements;

---------------------------
-- Строим таблицу osm.water_name 
CREATE TABLE osm.water_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT water_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.water_name OWNER to postgres;

insert into osm.water_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.water;

---------------------------
-- Строим таблицу regions_name 
CREATE TABLE osm.regions_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    admin_level smallint,
    geom geometry(Point,3857),
    CONSTRAINT regions_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.regions_name OWNER to postgres;

insert into osm.regions_name (gid, osm_id, name, admin_level, geom)
select gid, osm_id, name, admin_level, st_centroid(geom) from osm.regions;

---------------------------
-- Строим таблицу osm.parks_name 
CREATE TABLE osm.parks_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT parks_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.parks_name OWNER to postgres;

insert into osm.parks_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.parks;

---------------------------
-- Строим таблицу reserve_parks_name 
CREATE TABLE osm.reserve_parks_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT reserve_parks_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.reserve_parks_name OWNER to postgres;

insert into osm.reserve_parks_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.reserve_parks;

---------------------------
-- Строим таблицу square_name 
CREATE TABLE osm.square_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT square_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.square_name OWNER to postgres;

insert into osm.square_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.square;

---------------------------
-- Строим таблицу industrial_name 
CREATE TABLE osm.industrial_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT industrial_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.industrial_name OWNER to postgres;

insert into osm.industrial_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.industrial;

---------------------------
-- Строим таблицу commercial_name 
CREATE TABLE osm.commercial_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT commercial_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.commercial_name OWNER to postgres;

insert into osm.commercial_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.commercial;

---------------------------
-- Строим таблицу education_name 
CREATE TABLE osm.education_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT education_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.education_name OWNER to postgres;

insert into osm.education_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.education;

---------------------------
-- Строим таблицу island_name 
CREATE TABLE osm.island_name
(
    gid uuid NOT NULL UNIQUE,
    osm_id bigint,
    name text,
    geom geometry(Point,3857),
    CONSTRAINT island_name_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.island_name OWNER to postgres;

insert into osm.island_name (gid, osm_id, name, geom)
select gid, osm_id, name, st_centroid(geom) from osm.island;

