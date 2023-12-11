# DDS01_update

1. Основной источник данных — ресурс OpenStreeMap. Поэтому с сайта http://download.geofabrik.de/russia/northwestern-fed-district.html скачиваем файл northwestern-fed-district-latest.osm.pbf
	Важно! Именно в pbf формате.
2. Скачанный файл содержит в себе данные на весь Северо-Западный Федеральный Округ. Необходимо обрезать по экстенту. Можно любым способом, который нравится, но самый быстрый (около 30 секунд)следующий:
   - Нужна консольная утилита osmosis  (https://wiki.openstreetmap.org/wiki/Osmosis)
   Через командную строку Windows запускаем вот такой строкой, заменив соответственно три пути к файлам:
   C:\_Workspace\distr\osmosis\bin\osmosis.bat --read-pbf file="C:\_Workspace\TASK\DDS_01\Fresh_osm_data\northwestern-fed-district-latest.osm.pbf" --bounding-box top=60.51 left=28.94 bottom=59.32 right=31.26 --write-pbf file="C:\_Workspace\TASK\DDS_01\Fresh_osm_data\saint-petesburg.osm.pbf"
   Это довольно грубая обрезка, по прямоугольнику. Позже можно будет обрезать многоульником.
3. Получившийся файл saint-petesburg.osm.pbf открываем при помощи QGIS. Выбираем три вида геометрии: points, multoplygons, lines.
4. У каждого из трёх слоёв в свойствах слоя, на вкладке Текст, указываем кодировку UTF-8.
5. Добавляем в проект QGIS многоугольник экстента _Extent.gpkg. И пока откладываем QGIS.
6. Открываем pgAdmin. Создаём новую БД
7. Дописываем к новой БД расширение postGIS
8. Возвращаемся к QGIS. Создаём подключение к новой  (из пункта 2)созданной БД, через QGIS
9. Через Python консоль открываем скрипт 00_extract_address_data.py
10. Указываем в USER_SETTINGS скрипта название базы данных  и название схемы.
11. Запускаем выполнение скрипта. Он обрезает данные по многоульнику, парсит адресную информацию из тегов по колонкам. Кроме адресной информации вытягивает множество других значений тегов. Исправляет геометрию в полигонах, перепроецирует данные, заливает их в БД c правильными названиями. Обработка занимает около часа.
12. Для проверки загружаем векторные данные из БД схемы public. Убеждаемся, что всё ок. Заливает исходные данные из локальных файлов в БД в 3 слоя planet_osm_*.
    Проверяем результат: в таблицах много объектов, в поле name не поломалась кодировка, все объекты лежат на СПБ, никуда не улетели, везде проекция 3857, есть адресные поля: housenumber, street, city, region и они кое-где заполнены.
13. Через pgAdmin выполняем 01_prepare_0_init.sql. Делает резервные копии предыдущих слоёв.
14. Выполняем 02_function.sql вспомогательные функции.
15. Выполняем 03_prepare_1.sql. Около 10 минут. По итогу в схеме osm появятся 28 слоёв с данными. 
	Если выполнение вылетает с ошибкой: "ERROR: ОШИБКА:  функция osm.uuid_generate_v4() не существует", 
	то в pgAdmin на свойствах расширения uuid-ossp, на вкладке Definition, необходимо указать схему osm или public.
16. Выполняем 04_prepare_2.sql. Около 20 минут.
17. Выполняем .\comparing\compare_old_new_functions.sql
18. Выполняем .\comparing\compare_old_new_init.sql
19. Выполняем 05_prepare_4.sql. Около 1 часа. Если ругается на "ERROR: ОШИБКА:  функция osm.uuid_generate_v4() не существует", то аналогично пункту 19 настроить на схему public.
20. Выполняем скрипты с функциями из папки utils
21. Выполняем скрипт 06_search_roads.sql. 15 мин
