-- FUNCTION: public.t01_set_rn_or_rg_ids_for_allroads(text)

-- DROP FUNCTION IF EXISTS public.t01_set_rn_or_rg_ids_for_allroads(text);

CREATE OR REPLACE FUNCTION public.t01_set_rn_or_rg_ids_for_allroads(
	obj text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    rg                record;
    rds               record;
    debugCounter      integer := 1;
    innerDebugCounter integer := 1;
    adm_lvl           text;
begin
    if obj = 'rg_id' then
        adm_lvl := '4';
    else
        adm_lvl := '5,6';
    end if;
    for rg in execute 'select gid, geom from osm.regions where admin_level in (' || adm_lvl || ')'
        loop
            for rds in execute 'select gid, the_geom from routing.allroads where ' || obj || ' is null'
                loop
                    if (st_contains(rg.geom, rds.the_geom)) then
                        execute 'update routing.allroads set ' || obj || ' ='''||rg.gid||'''::uuid where gid = '''||rds.gid||'''::uuid;';
                    end if;
                    if innerDebugCounter % 1000 = 0 then
                        raise notice '% % %', obj, debugCounter, innerDebugCounter;
                    end if;
                    innerDebugCounter := innerDebugCounter + 1;
                end loop;
            innerDebugCounter := 1;
            debugCounter := debugCounter + 1;
        end loop;
    raise notice 'most part of % was setted', obj;

--         для улиц, у которых после предыдущего цикла остался нулевой rn_id заполняет его при условии вхождения улицы в район на >50%
    for rds in execute 'select gid, the_geom from routing.allroads where ' || obj || ' is null'
        loop
            for rg in execute 'select gid, geom from osm.regions where admin_level in (' || adm_lvl || ')'
                loop
                    if ((st_length(st_intersection(rg.geom, rds.the_geom)) / st_length(rds.the_geom)) > 0.50) then
                        execute 'update routing.allroads set ' || obj || ' ='''||rg.gid||'''::uuid where gid = '''||rds.gid||'''::uuid;';
                    end if;
                end loop;
        end loop;

    --         на данный момент остаются дороги, которые не входят ни в какой район больше чем на 50%
--         если дорога входит в несколько районов, берем случайный.
    for rds in execute 'select gid, the_geom from routing.allroads where ' || obj || ' is null'
        loop
            for rg in execute 'select gid, geom from osm.regions where admin_level in (' || adm_lvl || ')'
                loop
                    if (st_intersects(rds.the_geom, rg.geom)) then
                        execute 'update routing.allroads set ' || obj || ' ='''||rg.gid||'''::uuid where gid = '''||rds.gid||'''::uuid;';
                    end if;
                end loop;
        end loop;

--         удаляю те дороги, которые никуда не попали. Такова судьба. Или просто геометрия районов кривая
    execute 'delete from routing.allroads where ' || obj || ' is null;';
    raise notice 'all % were setted', obj;
end;
$BODY$;

ALTER FUNCTION public.t01_set_rn_or_rg_ids_for_allroads(text)
    OWNER TO postgres;
