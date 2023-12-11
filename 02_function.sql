-- FUNCTION: public.geonim(text, text, text)

-- DROP FUNCTION public.geonim(text, text, text);

CREATE OR REPLACE FUNCTION public.geonim(
	gtype text,
	gpart text,
	i text)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
declare regexp text;
declare fgtype text;
BEGIN
		fgtype = lower(gtype);
		regexp = '((^|\s)(';
		if fgtype = 'region' then
			regexp = regexp||'[о]((круг)|(бласть))|район';
		elsif fgtype = 'settlement' then
			regexp = regexp||'в/ч|д(еревня|\.|нп|нт|пк)|(жилг|г)ород(ок)?|(жилм|м)ассив|к(м|(п|от(т)?еджный\sпос[её]лок)|оллективный\s[сc]ад)|(малоэтажный\s)?ж(к|илой\sкомплекс)|м(ассив|икрорайон)|о(т|оаз|нт|город(ы|ничество))|п(арклесхоз|ос(е|ё)лок)|[cс](т|нт(\s\((днт|ко|кс)\))?|нп|(адоводство|дт))|т(с(н|ж)|ерритория)|участок';
		elsif fgtype = 'street' then
			regexp = regexp||'аллея|бульвар|в(ал|ъезд)|доро(га|жка)|заезд|кольцо|лини(и|я)|мост(ик)?|набережная|п(арк|ереезд|ереулок|лощадка|лощадь|роезд|роспект|роулок|утепровод)|разъезд|с(квер|пуск)|т(оннель|упик)|ул(\.|ица)|шоссе';
		elsif fgtype ='water' then
			regexp = regexp||'водовод|канал|(оз(\.|еро))|пруд|(р(\.|е(ч)?ка|уче(й|[её]к)))';
		end if;
		regexp = regexp||')([\s\.\-\,]|$))';

		if lower(gpart)='name' then
          RETURN replace(replace(trim(both ' «»"''' from regexp_replace(i, regexp, ' ', 'ig')), '  ', ' '), '  ', ' ');
		else
          RETURN trim(both '.-, ' from substring(lower(i) from regexp));
		end if;
END;
$BODY$;

ALTER FUNCTION public.geonim(text, text, text)
    OWNER TO postgres;

-- FUNCTION: public.geonim_compare(text, text, text)

-- DROP FUNCTION public.geonim_compare(text, text, text);

CREATE OR REPLACE FUNCTION public.geonim_compare(
	gtype text,
	i1 text,
	i2 text)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
declare regexp text;
declare fgtype text;
BEGIN
        RETURN (geonim_name(gtype, lower(i1)) = geonim_name(gtype, lower(i2)) and geonim_type(gtype, i1) = geonim_type(gtype, i2));
END;
$BODY$;

ALTER FUNCTION public.geonim_compare(text, text, text)
    OWNER TO postgres;

-- FUNCTION: public.geonim_name(text, text)

-- DROP FUNCTION public.geonim_name(text, text);

CREATE OR REPLACE FUNCTION public.geonim_name(
	gtype text,
	i text)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
declare regexp text;
declare fgtype text;
BEGIN
		fgtype = lower(gtype);
		regexp = '((^|\s)(';
		if fgtype = 'reg' then
			regexp = regexp||'[о]((круг)|(бласть))|район';
		elsif fgtype = 'set' then
			regexp = regexp||'в/ч|д(еревня|\.|нп|нт|пк)|(жилг|г)ород(ок)?|(жилм|м)ассив|к(м|(п|от(т)?еджный\sпос[её]лок)|оллективный\s[сc]ад)|(малоэтажный\s)?ж(к|илой\sкомплекс)|м(ассив|икрорайон)|о(т|оаз|нт|город(ы|ничество))|п(арклесхоз|ос[её]лок)|[cс](т|нт(\s\((днт|ко|кс)\))?|нп|(адоводство|дт))|т(с(н|ж)|ерритория)|участок';
		elsif fgtype = 'str' then
			regexp = regexp||'аллея|бульвар|в(ал|ъезд)|доро(га|жка)|заезд|кольцо|лини(и|я)|мост(ик)?|набережная|п(арк|ереезд|ереулок|лощадка|лощадь|роезд|роспект|роулок|утепровод)|разъезд|с(квер|пуск)|т(оннель|упик)|ул(\.|ица)|шоссе';
		elsif fgtype ='water' then
			regexp = regexp||'водовод|канал|(оз(\.|еро))|пруд|(р(\.|е(ч)?ка|уче(й|[её]к)))';
		elsif fgtype ='isl' then
			regexp = regexp||'остров(ок)?';
		end if;
		regexp = regexp||')([\s\.\-\,]|$))';

        RETURN replace(replace(trim(both ' «»"''' from regexp_replace(i, regexp, ' ', 'ig')), '  ', ' '), '  ', ' ');
END;
$BODY$;

ALTER FUNCTION public.geonim_name(text, text)
    OWNER TO postgres;

-- FUNCTION: public.geonim_type(text, text)

-- DROP FUNCTION public.geonim_type(text, text);

CREATE OR REPLACE FUNCTION public.geonim_type(
	gtype text,
	i text)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
declare regexp text;
declare fgtype text;
BEGIN
		fgtype = lower(gtype);
		regexp = '((^|\s)(';
		if fgtype = 'reg' then
			regexp = regexp||'[о]((круг)|(бласть))|район';
		elsif fgtype = 'set' then
			regexp = regexp||'в/ч|д(еревня|\.|нп|нт|пк)|(жилг|г)ород(ок)?|(жилм|м)ассив|к(м|(п|от(т)?еджный\sпос[её]лок)|оллективный\s[сc]ад)|(малоэтажный\s)?ж(к|илой\sкомплекс)|м(ассив|икрорайон)|о(т|оаз|нт|город(ы|ничество))|п(арклесхоз|ос[её]лок)|[cс](т|нт(\s\((днт|ко|кс)\))?|нп|(адоводство|дт))|т(с(н|ж)|ерритория)|участок';
		elsif fgtype = 'str' then
			regexp = regexp||'аллея|бульвар|в(ал|ъезд)|доро(га|жка)|заезд|кольцо|лини(и|я)|мост(ик)?|набережная|п(арк|ереезд|ереулок|лощадка|лощадь|роезд|роспект|роулок|утепровод)|разъезд|с(квер|пуск)|т(оннель|упик)|ул(\.|ица)|шоссе';
		elsif fgtype ='water' then
			regexp = regexp||'водовод|канал|(оз(\.|еро))|пруд|(р(\.|е(ч)?ка|уче(й|[её]к)))';
		elsif fgtype ='isl' then
			regexp = regexp||'остров(ок)?';
		end if;
		regexp = regexp||')([\s\.\-\,]|$))';

        RETURN trim(both '.-, ' from substring(lower(i) from regexp));
END;
$BODY$;

ALTER FUNCTION public.geonim_type(text, text)
    OWNER TO postgres;

CREATE OR REPLACE FUNCTION public.area50(
	geom1 geometry,
	geom2 geometry)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
BEGIN
  RETURN ((st_area(geom2) > 0) and (st_area(st_intersection(geom1, geom2))/st_area(geom2)) > 0.50);
END;
$BODY$;

ALTER FUNCTION public.area50(geometry, geometry)
    OWNER TO postgres;

CREATE OR REPLACE FUNCTION public.length50(
	geom1 geometry,
	geom2 geometry)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
BEGIN
  RETURN ((st_length(geom2) > 0) and (st_length(st_intersection(geom1, geom2))/st_length(geom2)) > 0.50);
END;
$BODY$;

ALTER FUNCTION public.length50(geometry, geometry)
    OWNER TO postgres;

CREATE OR REPLACE FUNCTION public.contains50(
	geom1 geometry,
	geom2 geometry)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
declare
    geom_type text;
BEGIN
  geom_type := geometrytype(geom2);
  if geom_type in ('POINT','MULTIPOINT') then
    RETURN st_contains(geom1, geom2);
  elseif geom_type in ('LINESTRING','MULTILINESTRING') then
    RETURN ((st_length(geom2) > 0) and (st_length(st_intersection(geom1, geom2))/st_length(geom2)) > 0.50);
  elseif geom_type in ('POLYGON','MULTIPOLYGON') then
    RETURN ((st_area(geom2) > 0) and (st_area(st_intersection(geom1, geom2))/st_area(geom2)) > 0.50);
  else
    return false;
  end if;
END;
$BODY$;

ALTER FUNCTION public.contains50(geometry, geometry)  OWNER TO postgres;

create or replace function contains50(geom1 geometry, geom2 geometry, errmsg text) returns boolean
    language plpgsql
as
$$
declare
    geom_type text;
BEGIN
  geom_type := geometrytype(geom2);
  if geom_type in ('POINT','MULTIPOINT') then
    RETURN st_contains(geom1, geom2);
  elseif geom_type in ('LINESTRING','MULTILINESTRING') then
    RETURN ((st_length(geom2) > 0) and (st_length(st_intersection(geom1, geom2))/st_length(geom2)) > 0.50);
  elseif geom_type in ('POLYGON','MULTIPOLYGON') then
    RETURN ((st_area(geom2) > 0) and (st_area(st_intersection(geom1, geom2))/st_area(geom2)) > 0.50);
  else
    return false;
  end if;
EXCEPTION WHEN OTHERS THEN
RAISE NOTICE '%', errmsg;
        RETURN false;
END;
$$;

alter function contains50(geometry, geometry, text) owner to postgres;

-- for searchroads

CREATE OR REPLACE function t01_format_addr_city(town character varying) returns character varying
    language plpgsql
as
$$
begin
    if town ilike '%Санкт-Петербург%'
    then
        town := regexp_replace(town,',[а-яА-я]+ район','');
        town := regexp_replace(town, '(,Санкт-Петербург)+',',СПб');
        town := regexp_replace(town, 'Санкт-Петербург,СПб','Санкт-Петербург');
    elsif town ilike '%Ленинградская область%'
    then
        town := replace(town,'Ленинградская область','ЛО');
    end if;
    return replace(town,',',', ');
end;
$$;

alter function t01_format_addr_city(varchar) owner to postgres;


-- принимает массив геометрий кусков улицы
-- возвращает геометрию точки, примерный центр для этого массива
CREATE OR REPLACE function t01_getpoint(geom_list geometry[]) returns geometry
    language plpgsql
as
$$
declare

    max_geom geometry := geom_list[1];
    max_type text;
    i        geometry;

begin

    foreach i in array geom_list

        loop

            if st_length(st_longestline(i, i)) > st_length(st_longestline(max_geom, max_geom))
            then
                max_geom := i;
            end if;


        end loop;

    max_type = geometrytype(max_geom);

    if max_type = 'LINESTRING'
    then
        max_geom := st_lineinterpolatepoint(max_geom, 0.5);
    elseif max_type = 'MULTILINESTRING'
    then
        i = st_linemerge(max_geom);
        if geometrytype(i) = 'LINESTRING'
        then
            max_geom := st_lineinterpolatepoint(st_linemerge(max_geom), 0.5);
        else
            if st_distance(max_geom, st_centroid(max_geom)) < 1
            then
                max_geom := st_centroid(max_geom);
            else
                max_geom := st_pointonsurface(max_geom);
            end if;
        end if;
    elseif max_type in ('POLYGON', 'MULTIPOLYGON')
    then
        if st_contains(max_geom, st_centroid(max_geom))
        then
            max_geom := st_centroid(max_geom);
        else
            max_geom := st_pointonsurface(max_geom);
        end if;
    else
        max_geom := st_pointonsurface(max_geom);
    end if;


    return max_geom;

end;

$$;

alter function t01_getpoint(geometry[]) owner to postgres;


CREATE OR REPLACE function t01_namenumutils_create_uuid_string(arr uuid[], OUT result text) returns text
    language plpgsql
as
$$
declare
    iter integer;
begin
    result := '''';
    for iter in 1..array_length(arr, 1)
        loop
            if iter < array_length(arr, 1) then
                result := concat(result, arr[iter], ''', ''');
            else
                result := concat(result, arr[iter], '''');
            end if;
        end loop;
end;
$$;

alter function t01_namenumutils_create_uuid_string(uuid[], out text) owner to postgres;

CREATE OR REPLACE function t_intersection(geom1 geometry, geom2 geometry, tipe integer) returns geometry
    language plpgsql
as
$$
    --находит пересечение геометрий, и если результат GEOMETRYCOLLECTION извлекает указаный тип 1 == POINT, 2 == LINESTRING, 3 == POLYGON
declare
    res geometry;
    geom_type varchar(256);
begin
    res := st_intersection(geom1, geom2);
    geom_type := geometrytype(res);
    if geom_type = 'GEOMETRYCOLLECTION'
    then res := ST_MULTI(ST_CollectionExtract(res, tipe));
    end if;
    return res;
exception when others then return false;

end;

$$;

alter function t_intersection(geometry, geometry, integer) owner to postgres;



CREATE OR REPLACE function t01_namenum_maker(condition text) returns void
    language plpgsql
as
$$
declare
    gids       uuid[];
    elem       uuid;
    neig       uuid[];
    temp_neig  uuid[];
    rand_value int;
    nanenum int := 1;
begin

    select coalesce(max(namenum),1) from addr.search_roads into nanenum;

    if condition is not null then
        condition := 'and ' || condition;
    else
        condition := '';
    end if;
    execute 'select array_agg(gid) from addr.search_roads where namenum is null ' || condition into gids;

    while array_length(gids, 1) > 0
        loop
            elem := gids[1];
            neig := array_append(neig, elem);
            temp_neig := array_append(temp_neig, elem);

            while temp_neig is not null and array_length(temp_neig, 1) > 0
                loop
                    -- поиск соседей для элементов neig
                    execute 'with temp as(select name, geom, tipe from addr.search_roads where gid in (' ||
                            t01_namenumutils_create_uuid_string(temp_neig) || '))
                    select array_agg(distinct r.gid) from addr.search_roads r inner join temp on (r.gid not in (' ||
                            t01_namenumutils_create_uuid_string(neig) ||
                            ') and r.name ilike temp.name and r.tipe = temp.tipe and st_distance(temp.geom, r.geom) < 500)'
                        into temp_neig;
                    if temp_neig is not null then
                        neig := array_cat(neig, temp_neig);
                    end if;
                end loop;
            -- namenum setting
            rand_value := nanenum;
            nanenum := nanenum +1;
            execute 'update addr.search_roads set namenum = $1 where gid in (' ||
                    t01_namenumutils_create_uuid_string(neig) || ')' using rand_value;

            -- deleting temp arrays
            while array_length(neig, 1) > 0
                loop
                    gids := array_remove(gids, neig[1]);
                    neig := array_remove(neig, neig[1]);
                end loop;
        end loop;
end
$$;

alter function t01_namenum_maker(text) owner to postgres;

--проверяет можно ли считать что полигон содержит какую-либо геометрию.
-- учитывается длина входящего куска дороги, процент площади полигона....

CREATE OR REPLACE function t_polygon_is_contains(polygon geometry, some_geom geometry) returns boolean
    language plpgsql
as
$$
declare
    res boolean := false;
    lmt float4 :=0.025;
    some_geom_type varchar(256);
begin
    some_geom_type := geometrytype(some_geom);
    if some_geom_type = 'GEOMETRYCOLLECTION'
    then some_geom := ST_MULTI(ST_CollectionExtract(some_geom, 3));
    end if;
    res := st_intersects(polygon, some_geom) and (st_contains(polygon, some_geom) or st_contains(some_geom, polygon)
        or (some_geom_type in ('LINESTRING','MULTILINESTRING') and st_length(st_intersection(some_geom, polygon)) > 5)
        or (some_geom_type in ('POLYGON','MULTIPOLYGON')  and st_area(st_intersection(some_geom,polygon)) / st_area(some_geom) > lmt)
        );
    return res;
exception when others then return false;

end;

$$;

alter function t_polygon_is_contains(geometry, geometry) owner to postgres;

