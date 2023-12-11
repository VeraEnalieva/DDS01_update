alter table osm.forts add column if not exists old_gid uuid;
alter table osm.cemetery add column if not exists old_gid uuid;
alter table osm.settlements add column if not exists old_gid uuid;
alter table osm.water add column if not exists old_gid uuid;
alter table osm.water_line add column if not exists old_gid uuid;
alter table osm.bridges add column if not exists old_gid uuid;
alter table osm.regions add column if not exists old_gid uuid;
alter table osm.parks add column if not exists old_gid uuid;
alter table osm.reserve_parks add column if not exists old_gid uuid;
alter table osm.square add column if not exists old_gid uuid;
alter table osm.railway_platform add column if not exists old_gid uuid;
alter table osm.island add column if not exists old_gid uuid;
alter table osm.highways add column if not exists old_gid uuid;
alter table osm.roads add column if not exists old_gid uuid;
alter table osm.milestone_point add column if not exists old_gid uuid;
alter table osm.buildings add column if not exists old_gid uuid;
alter table osm.railway_point add column if not exists old_gid uuid;


select compare_new_old_full('osm_old.regions','osm.regions',10,'');
select compare_new_old_full_list('osm_old.regions','osm.regions', 10,'');
update osm.regions set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.settlements','osm.settlements', 29,''); -- 100  радиус буфера при поиске геометрических дубликатов
select compare_new_old_full_list('osm_old.settlements','osm.settlements', 29,'');  -- 100
update osm.settlements set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.bridges','osm.bridges', 10,'');
select compare_new_old_full_list('osm_old.bridges','osm.bridges', 10,'');
update osm.bridges set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.square','osm.square', 10,'');
select compare_new_old_full_list('osm_old.square','osm.square', 10,'');
update osm.square set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.parks','osm.parks', 50,'');
select compare_new_old_full_list('osm_old.parks','osm.parks', 50,'');
update osm.parks set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.reserve_parks','osm.reserve_parks', 100,'');
select compare_new_old_full_list('osm_old.reserve_parks','osm.reserve_parks', 100,'');
update osm.reserve_parks set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.island','osm.island', 10,'');  -- 100
select compare_new_old_full_list('osm_old.island','osm.island', 10,'');  -- 100
update osm.island set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.forts','osm.forts', 100,'');
select compare_new_old_full_list('osm_old.forts','osm.forts', 100,'');
update osm.forts set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.cemetery','osm.cemetery', 100,'');
select compare_new_old_full_list('osm_old.cemetery','osm.cemetery', 100,'');
update osm.cemetery set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.water','osm.water', 15,'');  -- 50
select compare_new_old_full_list('osm_old.water','osm.water', 15,'');  -- 50
update osm.water set gid = old_gid where old_gid is not null;
/* ----------    нет в схеме old
select compare_new_old_full('osm_old.railway_platform','osm.railway_platform', 100,'');
select compare_new_old_full_list('osm_old.railway_platform','osm.railway_platform', 100,'');
update osm.railway_platform set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.water_line','osm.water_line', 5,'');
select compare_new_old_full_list('osm_old.water_line','osm.water_line', 5,'');
update osm.water_line set gid = old_gid where old_gid is not null;
*/
select compare_new_old_full('osm_old.highways','osm.highways', 5,'');
select compare_new_old_full_list('osm_old.highways','osm.highways', 5,'');
update osm.highways set gid = old_gid where old_gid is not null;

select compare_new_old_full('osm_old.roads','osm.roads', 5,'');
select compare_new_old_full_list('osm_old.roads','osm.roads', 5,'');
update osm.roads set gid = old_gid where old_gid is not null;