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
