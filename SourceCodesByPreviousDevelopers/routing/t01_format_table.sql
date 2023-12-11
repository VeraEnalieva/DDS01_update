-- FUNCTION: public.t01_format_table(text, integer, integer)

-- DROP FUNCTION IF EXISTS public.t01_format_table(text, integer, integer);

CREATE OR REPLACE FUNCTION public.t01_format_table(
	tablename text,
	INOUT accedges integer,
	INOUT accnodes integer)
    RETURNS record
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    edgesCounter                     integer;
    nodesCounter                     integer;
    temptablename_noded              text := tablename || '_noded';
    temptablename_noded_vertices_pgr text := tablename || '_noded_vertices_pgr';
begin
    --                 подготовка колонок которые пригодятся
--                 это временные
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN idd integer';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN src integer';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN trg integer';
--                 эти будут нужны
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN name text';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN cost double precision';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN reverse_cost double precision';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN highway text';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN oneway text';
    execute 'ALTER TABLE ' || tempTableName_noded || ' ADD COLUMN maxspeed integer';

--              заполняю idd в edges
    execute 'update ' || tempTableName_noded || ' set idd=id + ' || accedges;

--                 узнаю количество записей в edges и обновляю на его основе edgesAccum
    execute 'select max(id) from ' || tempTableName_noded into edgesCounter;
    accedges := accedges + edgesCounter;
    raise notice '_____edges conuter_______%', edgesCounter;
    raise notice '_____accum edges conuter_______%', accedges;

--              создаю и заполняю idd в nodes
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' ADD COLUMN idd integer';
    execute 'update ' || temptablename_noded_vertices_pgr || ' set idd=id + ' || accnodes;

--              узнаю количество записей в nodes и обновляю на его основе nodesAccum
    execute 'select max(id) from ' || temptablename_noded_vertices_pgr into nodesCounter;
--         заполняю source target
    execute 'update ' || tempTableName_noded ||
            ' set src=source + ' || accnodes || ', trg=target + ' || accnodes;

    accnodes := accnodes + nodesCounter;
    raise notice '_____nodes conuter after_______%', nodesCounter;
    raise notice '_____accum nodes conuter after_______%', accnodes;

--                 перетаскиваю name, highway, oneway, maxspeed в таблицу noded
    execute 'UPDATE ' || tempTableName_noded || ' SET name = (SELECT name
                            FROM ' || tablename || ' WHERE id = old_id), highway = (SELECT highway
                            FROM ' || tablename || ' WHERE id = old_id), oneway = (SELECT oneway
                            FROM ' || tablename || ' WHERE id = old_id), maxspeed = (SELECT maxspeed
                            FROM ' || tablename || ' WHERE id = old_id)';

--     делаю таблицу из точек, содержащихся и в district table, и в inter
    execute 'create table ' || tablename || '_common_points (
                    distr_id integer,
                    inter_id integer
                )';

    execute 'insert into ' || tablename || '_common_points (
                select d.idd, i.id
                from ' || temptablename_noded_vertices_pgr || ' d
                         inner join routing.distr_roads0_inter_noded_vertices_pgr i on d.the_geom = i.the_geom
                );';
    execute 'create index ' || replace(tablename, '.', '_') || '_distr_id_index on ' || tablename ||
            '_common_points(distr_id)';
    execute 'create index ' || replace(tablename, '.', '_') || '_inter_id_index on ' || tablename ||
            '_common_points(inter_id)';

--                 удаление и переименование временных колонок
    execute 'ALTER TABLE ' || tempTableName_noded || ' DROP COLUMN id';
    execute 'ALTER TABLE ' || tempTableName_noded || ' DROP COLUMN source';
    execute 'ALTER TABLE ' || tempTableName_noded || ' DROP COLUMN target';
    execute 'ALTER TABLE ' || tempTableName_noded || ' DROP COLUMN old_id';
    execute 'ALTER TABLE ' || tempTableName_noded || ' DROP COLUMN sub_id';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' DROP COLUMN id';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' DROP COLUMN cnt';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' DROP COLUMN chk';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' DROP COLUMN ein';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' DROP COLUMN eout';

    execute 'ALTER TABLE ' || tempTableName_noded || ' RENAME COLUMN idd TO id';
    execute 'ALTER TABLE ' || tempTableName_noded || ' RENAME COLUMN src TO source';
    execute 'ALTER TABLE ' || tempTableName_noded || ' RENAME COLUMN trg TO target';
    execute 'ALTER TABLE ' || temptablename_noded_vertices_pgr || ' RENAME COLUMN idd TO id';
end;
$BODY$;

ALTER FUNCTION public.t01_format_table(text, integer, integer)
    OWNER TO postgres;
