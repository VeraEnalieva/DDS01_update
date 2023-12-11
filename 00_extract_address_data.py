import processing
from qgis.core import *

# USER_SETTINGS
db = 'test08'
schema = 'public'


def clipping(fc):
    res = processing.run("native:clip", 
                            {
                            'INPUT':fc,
                            'OVERLAY':'_Extent',
                            'OUTPUT':'TEMPORARY_OUTPUT'
                            }
                            )
    return res['OUTPUT']
    


def reproject(fc):
    fc = processing.run("native:reprojectlayer", 
                {
                'INPUT':fc,
                'TARGET_CRS':QgsCoordinateReferenceSystem('EPSG:3857'),
                'OPERATION':'+proj=pipeline +step +proj=unitconvert +xy_in=deg +xy_out=rad +step +proj=webmerc +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84',
                'OUTPUT':'TEMPORARY_OUTPUT'
                }
                )
    return fc['OUTPUT']
    
    
def extract_addr_info(fc):
    # house number
    param = {
            'INPUT':fc,
            'FIELD_NAME':'addr:housenumber',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("other_tags", \'"addr:housenumber"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    house_number = processing.run("native:fieldcalculator", param)
    
    param = {
            'INPUT':house_number['OUTPUT'],
            'FIELD_NAME':'addr:housenumber',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("addr:housenumber", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    house_number = processing.run("native:fieldcalculator", param)

    # street name
    param = {
            'INPUT':house_number['OUTPUT'],
            'FIELD_NAME':'addr:street',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("other_tags", \'addr:street"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    street = processing.run("native:fieldcalculator", param)

    param = {
            'INPUT':street['OUTPUT'],
            'FIELD_NAME':'addr:street',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("addr:street", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    street = processing.run("native:fieldcalculator", param)

    # city name
    param = {
            'INPUT':street['OUTPUT'],
            'FIELD_NAME':'addr:city',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("other_tags", \'addr:city"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    city = processing.run("native:fieldcalculator", param)

    param = {
            'INPUT':city['OUTPUT'],
            'FIELD_NAME':'addr:city',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("addr:city", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    city = processing.run("native:fieldcalculator", param)

    # district name
    param = {
            'INPUT':city['OUTPUT'],
            'FIELD_NAME':'addr:district',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("other_tags", \'addr:district"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    district = processing.run("native:fieldcalculator", param)

    param = {
            'INPUT':district['OUTPUT'],
            'FIELD_NAME':'addr:district',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("addr:district", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    district = processing.run("native:fieldcalculator", param)


    # region name
    param = {
            'INPUT':district['OUTPUT'],
            'FIELD_NAME':'addr:region',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("other_tags", \'addr:region"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    region = processing.run("native:fieldcalculator", param)

    param = {
            'INPUT':region['OUTPUT'],
            'FIELD_NAME':'addr:region',
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':'string_to_array("addr:region", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    region = processing.run("native:fieldcalculator", param)

    return region['OUTPUT']
        
 

def load2postgres(fc, db, schema, table_name):
    processing.run("native:importintopostgis", 
                    {
                    'INPUT': fc,
                    'DATABASE':db,
                    'SCHEMA':'public',
                    'TABLENAME':table_name,
                    'PRIMARY_KEY':'',
                    'GEOMETRY_COLUMN':'geom',
                    'ENCODING':'UTF-8',
                    'OVERWRITE':True,
                    'CREATEINDEX':True,
                    'LOWERCASE_NAMES':True,
                    'DROP_STRING_LENGTH':False,
                    'FORCE_SINGLEPART':False})    
    
    
def save_as(fc, name):
    processing.run("gdal:convertformat", 
                        {
                        'INPUT':fc,
                        'CONVERT_ALL_LAYERS':False,
                        'OPTIONS':'',
                        'OUTPUT':name+'.gpkg'
                        })




def extract_any_tag(fc, tag):
    #if ':' in tag:
    #    tag = tag.replace(':', '_')
    param = {
            'INPUT':fc,
            'FIELD_NAME':tag,
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':f'string_to_array("other_tags", \'"{tag}"=>"\')[1]',
            'OUTPUT':'TEMPORARY_OUTPUT'}

    res_1 = processing.run("native:fieldcalculator", param)

    #tag2=tag.replace('\"', '')
    #print(tag, tag2)
    param = {
            'INPUT':res_1['OUTPUT'],
            'FIELD_NAME':tag,
            'FIELD_TYPE':2,
            'FIELD_LENGTH':0,
            'FIELD_PRECISION':0,
            'FORMULA':f'string_to_array("{tag}", \'"\')[0]',
            'OUTPUT':'TEMPORARY_OUTPUT'}
    res_2 = processing.run("native:fieldcalculator", param)
    
    return res_2['OUTPUT']
    
    
def field_prep_area(fc):
    print(fc)
    res = processing.run("native:refactorfields", 
                            {
                            'INPUT':fc,
                            'FIELDS_MAPPING':
                                [
                                {'expression': '"osm_id"','length': 0,'name': 'osm_id','precision': 0,'sub_type': 0,'type': 4,'type_name': 'int8'},
                                {'expression': '"osm_way_id"','length': 0,'name': 'osm_way_id','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"name"','length': 0,'name': 'name','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"type"','length': 0,'name': 'type','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"aeroway"','length': 0,'name': 'aeroway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"amenity"','length': 0,'name': 'amenity','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"admin_level"','length': 0,'name': 'admin_level','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"barrier"','length': 0,'name': 'barrier','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"boundary"','length': 0,'name': 'boundary','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"building"','length': 0,'name': 'building','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"craft"','length': 0,'name': 'craft','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"geological"','length': 0,'name': 'geological','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"historic"','length': 0,'name': 'historic','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"land_area"','length': 0,'name': 'land_area','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"landuse"','length': 0,'name': 'landuse','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"leisure"','length': 0,'name': 'leisure','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"man_made"','length': 0,'name': 'man_made','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"military"','length': 0,'name': 'military','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"natural"','length': 0,'name': 'natural','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"office"','length': 0,'name': 'office','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"place"','length': 0,'name': 'place','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"shop"','length': 0,'name': 'shop','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"sport"','length': 0,'name': 'sport','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"tourism"','length': 0,'name': 'tourism','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                                {'expression': '"other_tags"','length': 0,'name': 'other_tags','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'}
                                ],
                            'OUTPUT':'TEMPORARY_OUTPUT'
                            })
    return res['OUTPUT']



def field_prep_line(fc):
    res = processing.run("native:refactorfields", 
                    {
                    'INPUT':fc,
                    'FIELDS_MAPPING':
                        [
                        {'expression': '"osm_id"','length': 0,'name': 'osm_id','precision': 0,'sub_type': 0,'type': 4,'type_name': 'int8'},
                        {'expression': '"name"','length': 0,'name': 'name','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"highway"','length': 0,'name': 'highway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"waterway"','length': 0,'name': 'waterway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"aerialway"','length': 0,'name': 'aerialway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"barrier"','length': 0,'name': 'barrier','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"man_made"','length': 0,'name': 'man_made','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"railway"','length': 0,'name': 'railway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"z_order"','length': 0,'name': 'z_order','precision': 0,'sub_type': 0,'type': 2,'type_name': 'integer'},
                        {'expression': '"other_tags"','length': 0,'name': 'other_tags','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'}
                        ],
                    'OUTPUT':'TEMPORARY_OUTPUT'})
    return res['OUTPUT']
    


def field_prep_point(fc):
    res = processing.run("native:refactorfields", 
                    {'INPUT':fc,
                    'FIELDS_MAPPING':[
                        {'expression': '"osm_id"','length': 0,'name': 'osm_id','precision': 0,'sub_type': 0,'type': 4,'type_name': 'int8'},
                        {'expression': '"name"','length': 0,'name': 'name','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"barrier"','length': 0,'name': 'barrier','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"highway"','length': 0,'name': 'highway','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"ref"','length': 0,'name': 'ref','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"address"','length': 0,'name': 'address','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"is_in"','length': 0,'name': 'is_in','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"place"','length': 0,'name': 'place','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"man_made"','length': 0,'name': 'man_made','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'},
                        {'expression': '"other_tags"','length': 0,'name': 'other_tags','precision': 0,'sub_type': 0,'type': 10,'type_name': 'text'}
                        ],
                    'OUTPUT':'TEMPORARY_OUTPUT'})
    return res['OUTPUT']
    
    


print("Преобразование полей ....")
areas = field_prep_area('multipolygons')
lines = field_prep_line('lines')
points = field_prep_point('points')

print('Исправление геометриий ....')
areas = processing.run("native:fixgeometries", {'INPUT':areas,'METHOD':1,'OUTPUT':'TEMPORARY_OUTPUT'})
lines = processing.run("native:fixgeometries", {'INPUT':lines,'METHOD':1,'OUTPUT':'TEMPORARY_OUTPUT'})
points = processing.run("native:fixgeometries", {'INPUT':points,'METHOD':1,'OUTPUT':'TEMPORARY_OUTPUT'})

print('Обрезка по многоугольнику ....')
areas = clipping(areas['OUTPUT'])
points = clipping(points['OUTPUT'])
lines = clipping(lines['OUTPUT'])

print('Перепроецирование ....')
areas = reproject(areas)
points = reproject(points)
lines = reproject(lines)



print('Экстракт адресной информации из тегов ....')

areas = extract_addr_info(areas)
points = extract_addr_info(points)
lines = extract_addr_info(lines)
'''
areas = extract_any_tag(areas, "\"addr:housenumber\"")
areas = extract_any_tag(areas, "\"addr:street\"")
areas = extract_any_tag(areas, "\"addr:city\"")
areas = extract_any_tag(areas, "\"addr:district\"")
areas = extract_any_tag(areas, "\"addr:region\"")

points = extract_any_tag(points, "\"addr:housenumber\"")
points = extract_any_tag(points, "\"addr:street\"")
points = extract_any_tag(points, "\"addr:city\"")
points = extract_any_tag(points, "\"addr:district\"")
points = extract_any_tag(points, "\"addr:region\"")

lines = extract_any_tag(lines, "\"addr:housenumber\"")
lines = extract_any_tag(lines, "\"addr:street\"")
lines = extract_any_tag(lines, "\"addr:city\"")
lines = extract_any_tag(lines, "\"addr:district\"")
lines = extract_any_tag(lines, "\"addr:region\"")
'''
#print("Сохранение промежуточных результатов")
#save_as(areas, 'pre_multipolygons')
#save_as(points, 'pre_points')
#save_as(lines, 'pre_lines')


print("Прочие экстракты из тегов ....")
areas = extract_any_tag(areas, 'alt_name')
areas = extract_any_tag(areas, 'addr:flats')
areas = extract_any_tag(areas, 'building:levels')
areas = extract_any_tag(areas, 'construction')
areas = extract_any_tag(areas, 'disused')
areas = extract_any_tag(areas, 'highway')
areas = extract_any_tag(areas, 'layer')
areas = extract_any_tag(areas, 'official_status')
areas = extract_any_tag(areas, 'operator')
areas = extract_any_tag(areas, 'population')
areas = extract_any_tag(areas, 'railway')
areas = extract_any_tag(areas, 'ref')
areas = extract_any_tag(areas, 'religion')
areas = extract_any_tag(areas, 'service')
areas = extract_any_tag(areas, 'waterway')

points = extract_any_tag(points, 'amenity')
points = extract_any_tag(points, 'bridge')
points = extract_any_tag(points, 'building')
points = extract_any_tag(points, 'construction')
points = extract_any_tag(points, 'distance')
points = extract_any_tag(points, 'layer')
points = extract_any_tag(points, 'operator')
points = extract_any_tag(points, 'power')
points = extract_any_tag(points, 'railway')
points = extract_any_tag(points, 'religion')
points = extract_any_tag(points, 'service')
points = extract_any_tag(points, 'shop')
points = extract_any_tag(points, 'sport')
points = extract_any_tag(points, 'tourism')
points = extract_any_tag(points, 'tunnel')

lines = extract_any_tag(lines, 'admin_level')
lines = extract_any_tag(lines, 'area')
lines = extract_any_tag(lines, 'bay')
lines = extract_any_tag(lines, 'boundary')
lines = extract_any_tag(lines, 'bridge')
lines = extract_any_tag(lines, 'construction')
lines = extract_any_tag(lines, 'disused')
lines = extract_any_tag(lines, 'historic')
lines = extract_any_tag(lines, 'landuse')
lines = extract_any_tag(lines, 'lanes')
lines = extract_any_tag(lines, 'layer')
lines = extract_any_tag(lines, 'maxspeed')
lines = extract_any_tag(lines, 'natural')
lines = extract_any_tag(lines, 'oneway')
lines = extract_any_tag(lines, 'operator')
lines = extract_any_tag(lines, 'place')
lines = extract_any_tag(lines, 'power')
lines = extract_any_tag(lines, 'religion')
lines = extract_any_tag(lines, 'ref')
lines = extract_any_tag(lines, 'route')
lines = extract_any_tag(lines, 'service')
lines = extract_any_tag(lines, 'shop')
lines = extract_any_tag(lines, 'sport')
lines = extract_any_tag(lines, 'surface')
lines = extract_any_tag(lines, 'tourism')
lines = extract_any_tag(lines, 'tunnel')
lines = extract_any_tag(lines, 'width')



# Add tags: layer, operator, ref, religion, service, 
print('Загрузка данных в Postgres ....')
areas = load2postgres(areas, db, schema, 'planet_osm_polygon')
points = load2postgres(points, db, schema, 'planet_osm_point')
lines = load2postgres(lines, db, schema, 'planet_osm_line')

#     QgsProject.instance().addMapLayer(fc['OUTPUT']).setName(table_name)

print('Готово')


'''
Если нужно создать osm_old, для компарации старых данных и обновлённых,
заливка в БД старых данных с полем geom_uniq инструментов, который этот тип геометрии поддерживает

processing.run("gdal:importvectorintopostgisdatabaseavailableconnections", 
                    {
                    'DATABASE':db,
                    'INPUT':'postgres://dbname=\'dds01\' host=192.168.198.39 port=5432 user=\'v.enalieva\' password=\'U2QuQHrP\' sslmode=disable key=\'gid\' srid=3857 type=MultiPolygon checkPrimaryKeyUnicity=\'1\' table="osm"."roads" (geom)',
                    'SHAPE_ENCODING':'',
                    'GTYPE':13, # 8 = multipolygon, 13 = multicurve
                    'A_SRS':None,
                    'T_SRS':None,
                    'S_SRS':None,
                    'SCHEMA':'osm_old',
                    'TABLE':'roads',
                    'PK':'',
                    'PRIMARY_KEY':'',
                    'GEOCOLUMN':'geom',
                    'DIM':0,
                    'SIMPLIFY':'',
                    'SEGMENTIZE':'',
                    'SPAT':None,
                    'CLIP':False,
                    'WHERE':'',
                    'GT':'',
                    'OVERWRITE':True,
                    'APPEND':False,
                    'ADDFIELDS':False,
                    'LAUNDER':False,
                    'INDEX':False,
                    'SKIPFAILURES':False,
                    'PROMOTETOMULTI':True,
                    'PRECISION':True,
                    'OPTIONS':''
                    })
                    
print('Ready')                    


'''

