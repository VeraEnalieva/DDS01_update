-- FUNCTION: public.t01_set_maxspeed(text)

-- DROP FUNCTION IF EXISTS public.t01_set_maxspeed(text);

CREATE OR REPLACE FUNCTION public.t01_set_maxspeed(
	tablename text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
begin
    --         заполняю maxspeed. пока surface игнорирую, мб потом пригодится
    execute 'update ' || tablename || ' set maxspeed_int=110 where maxspeed = ''RU:motorway''';
    execute 'update ' || tablename || ' set maxspeed_int=60 where maxspeed = ''RU:urban''';
    execute 'update ' || tablename || ' set maxspeed_int=90 where maxspeed = ''RU:rural''';
    execute 'update ' || tablename || ' set maxspeed_int=20 where maxspeed = ''RU:living_street''';

    execute 'update ' || tablename || '
        set maxspeed_int=maxspeed::integer
        where maxspeed is not null
          and maxspeed not in (''RU:motorway'', ''RU:urban'', ''RU:rural'', ''RU:living_street'', ''signals'', ''yes'');';
    execute 'update ' || tablename || '
        set maxspeed_int=90
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''trunk''';
    execute '        update ' || tablename || '
        set maxspeed_int=110
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''motorway''';
    execute '        update ' || tablename || '
        set maxspeed_int=90
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''primary''';
    execute '        update ' || tablename || '
        set maxspeed_int=90
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''secondary''';
    execute '        update ' || tablename || '
        set maxspeed_int=60
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''tertiary''';
    execute '        update ' || tablename || '
        set maxspeed_int=60
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''unclassified'';';

    execute '        update ' || tablename || '
        set maxspeed_int=60
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''residential'';';
    execute '        update ' || tablename || '
        set maxspeed_int=90
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''primary_link'';';
    execute '        update ' || tablename || '
        set maxspeed_int=90
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''secondary_link'';';
    execute '        update ' || tablename || '
        set maxspeed_int=60
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''tertiary_link'';';
    execute '        update ' || tablename || '
        set maxspeed_int=110
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''motorway_link'';';
    execute '        update ' || tablename || '
        set maxspeed_int=20
        where (maxspeed is null or maxspeed in (''signals'', ''yes''))
          and highway = ''service'';';

--         по идее на этом моменте все maxspeed_int должны быть заполнены
    execute '        alter table ' || tablename || '
            drop column maxspeed;';
    execute '        alter table ' || tablename || '
            rename column maxspeed_int to maxspeed;';

    execute '        update ' || tablename ||
            ' set the_geom=st_reverse(the_geom), oneway=''yes'' where oneway = ''-1'';';
end;
$BODY$;

ALTER FUNCTION public.t01_set_maxspeed(text)
    OWNER TO postgres;
