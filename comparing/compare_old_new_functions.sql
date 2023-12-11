CREATE OR REPLACE FUNCTION compare_new_old(oldtab text, newtab text, dist integer, ext_cond text) RETURNS text AS $$
	declare oldcount integer;
    declare newcount integer;
    declare dblcount integer;

    BEGIN
	execute 'update '||newtab||' set old_gid = null';
     -- совпадение по геометриям
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and rr.name is not null and nrr.name is not null and ST_Equals(rr.geom,nrr.geom)) ) r where nr.gid=r.gid_new';
     -- совпадение по osm_id и геометриям с буфером dist
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and rr.name is not null and nrr.name is not null and nrr.old_gid is null and nrr.osm_id=rr.osm_id and (ST_Within(nrr.geom, st_buffer(rr.geom, '||dist::text||')) or ST_Within(rr.geom, st_buffer(nrr.geom, '||dist::text||')))) ) r where nr.gid=r.gid_new';
     -- совпадение по osm_id
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and rr.name is not null and nrr.name is not null and nrr.old_gid is null and nrr.osm_id=rr.osm_id) ) r where nr.gid=r.gid_new';
     -- совпадение по геометриям с буфером dist
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and rr.name is not null and nrr.name is not null and nrr.old_gid is null and ST_Within(nrr.geom, st_buffer(rr.geom, '||dist::text||')) and ST_Within(rr.geom, st_buffer(nrr.geom, '||dist::text||'))) ) r where nr.gid=r.gid_new';

        execute 'select count(gid) from '||oldtab||' o where o.name is not null and not exists (select gid from '||newtab||' n where n.name is not null and n.old_gid=o.gid)' into oldcount;
        execute 'select count(gid) from '||newtab||' where name is not null and old_gid is null' into newcount;
        execute 'with ogs as(select count(old_gid) ogs_count, old_gid from '||newtab||' where name is not null group by old_gid ) select count(*) from ogs where  ogs_count > 1 ' into dblcount;

        RAISE NOTICE '% -> Есть в старой, отсутствует в новой: %. Есть в новой, нет в старой: %. Дублирование элементов: %',oldtab, oldcount::text, newcount::text, dblcount::text;
        return 'ok -> Есть в старой, отсутствует в новой: '|| oldcount::text||'. Есть в новой, нет в старой: '||newcount::text||'. Дублирование элементов: '||dblcount::text;
    EXCEPTION
        WHEN OTHERS THEN
           RAISE NOTICE 'ошибка для таблиц %, %',oldtab, newtab;
           RETURN 'error';
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compare_new_old_full(oldtab text, newtab text, dist integer, ext_cond text) RETURNS text AS $$
    declare oldcount integer;
	declare newcount integer;
    declare dblcount integer;

    BEGIN
		execute 'update '||newtab||' set old_gid = null';
     -- совпадение по геометриям
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and ST_Equals(rr.geom,nrr.geom)) ) r where nr.gid=r.gid_new';
     -- совпадение по osm_id и геометриям с буфером dist
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and nrr.old_gid is null and nrr.osm_id=rr.osm_id and (ST_Within(nrr.geom, st_buffer(rr.geom, '||dist::text||')) or ST_Within(rr.geom, st_buffer(nrr.geom, '||dist::text||')))) ) r where nr.gid=r.gid_new';
     -- совпадение по геометриям с буфером dist
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and nrr.old_gid is null and ST_Within(nrr.geom, st_buffer(rr.geom, '||dist::text||')) and ST_Within(rr.geom, st_buffer(nrr.geom, '||dist::text||'))) ) r where nr.gid=r.gid_new';
     -- совпадение по osm_id
        execute 'update '||newtab||' nr set old_gid = r.gid_old from( select rr.gid as gid_old, nrr.gid as gid_new from '||oldtab||' rr join '||newtab||' nrr on (rr.gid <> nrr.gid and nrr.old_gid is null and nrr.osm_id=rr.osm_id) ) r where nr.gid=r.gid_new';

        execute 'select count(gid) from '||oldtab||' o where not exists (select gid from '||newtab||' n where n.old_gid=o.gid)' into oldcount;
        execute 'select count(gid) from '||newtab||' where old_gid is null' into newcount;
        execute 'with ogs as(select count(old_gid) ogs_count, old_gid from '||newtab||' group by old_gid ) select count(*) from ogs where  ogs_count > 1 ' into dblcount;

        RAISE NOTICE '% -> Есть в старой, отсутствует в новой: %. Есть в новой, нет в старой: %. Дублирование элементов: %',oldtab, oldcount::text, newcount::text, dblcount::text;
        return 'ok -> Есть в старой, отсутствует в новой: '|| oldcount::text||'. Есть в новой, нет в старой: '||newcount::text||'. Дублирование элементов: '||dblcount::text;
	EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ошибка для таблиц %, %',oldtab, newtab;
            RETURN 'error';
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compare_new_old_full_list(oldtab text, newtab text, dist integer, ext_cond text) RETURNS table(gid uuid, rtype text) AS
$$
	BEGIN
		return query execute 'select gid, ''old''::text as rtype  from '||oldtab||' o where not exists (select gid from '||newtab||' n where n.old_gid=o.gid)' ||
                             ' union ' ||
                             'select gid, ''new''::text as rtype from '||newtab||' where old_gid is null' ||
                             ' union ' ||
                             '(with ogs as(select count(old_gid) ogs_count, old_gid from '||newtab||' group by old_gid )' ||
                             ' select old_gid as gid, ''dbl''::text as rtype  from ogs where  ogs_count > 1) ' ||
                             'order by rtype' ;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION compare_new_old_list(oldtab text, newtab text, dist integer, ext_cond text) RETURNS table(gid uuid, rtype text) AS
$$
	BEGIN
        return query execute 'select gid, ''old''::text as rtype  from '||oldtab||' o where o.name is not null and not exists (select gid from '||newtab||' n where n.name is not null and n.old_gid=o.gid)' ||
                             ' union ' ||
                             'select gid, ''new''::text as rtype from '||newtab||' where name is not null and old_gid is null' ||
                             ' union ' ||
                             '(with ogs as(select count(old_gid) ogs_count, old_gid from '||newtab||' where name is not null group by old_gid )' ||
                             ' select old_gid as gid, ''dbl''::text as rtype  from ogs where  ogs_count > 1) ' ||
                             'order by rtype' ;
	END;
$$ LANGUAGE plpgsql;