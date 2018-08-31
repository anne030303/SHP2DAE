# coding: utf-8
# ### 將地形圖中的永久性房屋的SHP檔轉成XML檔，讓SketchUp匯入
import geopandas as gpd
import os
import codecs
import glob

permanent_housing_path = r'.\arcpy\Build.shp'
output_path = r'.\rb'
dirname = os.path.basename(os.path.dirname(permanent_housing_path))
permanent_housing_dir = os.path.dirname(permanent_housing_path)
permanent_housing_data = gpd.read_file(permanent_housing_path)
permanent_housing_xml = codecs.open(os.path.join(output_path,'permanent_housing_xml_%s.txt' % (dirname)),'w', "utf-8")
for i in permanent_housing_data.iterrows():
    ex_coor = list(i[1].geometry.exterior.coords)
    in_coor = list(i[1].geometry.interiors)
    permanent_housing_xml.write('<poly>')
    permanent_housing_xml.write('<index>'+str(i[0])+'</index>')
    permanent_housing_xml.write('<ex_coor>')
    for xy in ex_coor:
        permanent_housing_xml.write('<point>')
        permanent_housing_xml.write('<x>'+str(xy[0])+'</x>')
        permanent_housing_xml.write('<y>'+str(xy[1])+'</y>')
        permanent_housing_xml.write('</point>')
    permanent_housing_xml.write('</ex_coor>')
    permanent_housing_xml.write('<in_coors>')
    for poly in in_coor:
        permanent_housing_xml.write('<in_coor>')
        for xy in poly.coords:
            permanent_housing_xml.write('<point>')
            permanent_housing_xml.write('<x>'+str(xy[0])+'</x>')
            permanent_housing_xml.write('<y>'+str(xy[1])+'</y>')
            permanent_housing_xml.write('</point>')
        permanent_housing_xml.write('</in_coor>')
    permanent_housing_xml.write('</in_coors>')
    permanent_housing_xml.write('<DocName>'+i[1].DocName+'</DocName>')
    permanent_housing_xml.write('<Floor>'+i[1].Floor+'</Floor>')
    permanent_housing_xml.write('<Height>'+str(i[1].Height)+'</Height>')
    permanent_housing_xml.write('<HouseB>'+str(i[1].HouseB)+'</HouseB>')
    permanent_housing_xml.write('<HouseT>'+str(i[1].HouseT)+'</HouseT>')
    permanent_housing_xml.write('<HouseType>'+i[1].HouseType+'</HouseType>')
    permanent_housing_xml.write('<SheetName>'+i[1].SheetName+'</SheetName>')
    permanent_housing_xml.write('<SheetNum>'+i[1].SheetNum+'</SheetNum>')
    permanent_housing_xml.write('<TextString>'+i[1].TextString+'</TextString>')
    permanent_housing_xml.write('</poly>\n')
del permanent_housing_xml