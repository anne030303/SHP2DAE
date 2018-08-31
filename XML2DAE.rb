class PolyModel
	def initialize(poly)
        poly_re = /<index>(?<index>.*)<\/index><ex_coor>(?<ex_coor>.*)<\/ex_coor><in_coors>(?<in_coors>.*)<\/in_coors><poly_index>(?<poly_index>.*)<\/poly_index><ID>(?<ID>.*)<\/ID>/
		poly_m = poly_re.match(poly)  
		@index = poly_m[:index]
		ex_coor = poly_m[:ex_coor]
		in_coors = poly_m[:in_coors]
		@poly_index = poly_m[:poly_index]
		@ID = poly_m[:ID]
		
		#設定地面高屬性名稱
		heightB_re = /<HeightB>(?<heightb>.*)<\/HeightB>/
		heightB_m = poly.match(heightB_re)
        @HeightB = heightB_m[:heightb]

		#設定建物高程屬性名稱
		height_re = /<HeightT>(?<height>.*)<\/HeightT>/
		height_m = poly.match(height_re)
        @Height = height_m[:height]

		
		coor_re = /<point>(.*?)<\/point>/
		ex_coor_m = ex_coor.scan(coor_re)
		@ex_coor_array = read_point(ex_coor_m)

		@in_coors_array = Array.new
		unless @in_coors == ""
			in_coors_re = /<in_coor>(.*?)<\/in_coor>/
			in_coors_m = in_coors.scan(in_coors_re)
			for in_coor in in_coors_m
				in_coor_m = in_coor[0].scan(coor_re)
				in_coor_array = read_point(in_coor_m)
				@in_coors_array << in_coor_array
			end
		end
		
		@imgwidth = (@ex_coor_array.max_by(&:first)[0]).m - (@ex_coor_array.min_by(&:first)[0]).m
		@imgheight = (@ex_coor_array.max_by(&:last)[1]).m - (@ex_coor_array.min_by(&:last)[1]).m
		@origin = [@ex_coor_array.min_by(&:first)[0],@ex_coor_array.max_by(&:last)[1]]
	end
	def read_point(coor_m)
		array = Array.new
		point_re = /<x>(?<x>.*)<\/x><y>(?<y>.*)<\/y>/
		for xy in coor_m
			point_m = point_re.match(xy[0])
			array << [point_m[:x].to_f,point_m[:y].to_f]
		end
		return array
	end
	def get_index
		@index
	end
	def get_ex_poly
		@ex_coor_array
	end
	def get_in_poly
		@in_coors_array
	end
    def get_poly_index
        @poly_index
    end
    def get_ID
        @ID
    end
    def get_HeightB
        @HeightB.to_f
    end
    def get_Height
        @Height.to_f
    end
	def get_imgWidth
		@imgwidth
	end
	def get_imgHeight
		@imgheight
	end
	def get_origin
		@origin
	end
	def draw_poly(poly,height,ent)
		points = []
		for xy in poly
			pt = Geom::Point3d.new((xy[0]-@origin[0]).m,(xy[1]-@origin[1]).m,height.m)
			points << pt
		end
		face = ent.add_face(points)
		return face
	end
end

mod = Sketchup.active_model
ent = mod.entities
mats = mod.materials

#設定輸出dae的參數
options_hash = {:triangulated_faces => true,
				:doublesided_faces => false,
				:edges => false,
				:author_attribution => true,
				:texture_maps => true,
				:selectionset_only => false,
				:preserve_instancing => false }

#模型文字檔路徑
filedir = "permanent_housing_xml_arcpy.txt"
#正射影像路徑
orthodir = "./ortho"


#將隨機貼圖影像加入Sketchup中
facadedir = "./facade"
facadefiles = Dir.glob(File.join(facadedir,"*.jpg"))
for facade in facadefiles
	facadename = File.basename(facade,".jpg")
	if mats[facadename].nil?
		mat = mats.add(facadename)
		mat.texture = facade
		imagewidth = mat.texture.image_width
		imageheight = mat.texture.image_height
		scale = 3.0 / imageheight
		width = (imagewidth * scale).m
		height = (imageheight * scale).m
		mat.texture.size = [width,height]
	end
end

#建立模型
File.open(filedir) do |f|
	f.each_line do |line|
		poly = PolyModel.new(line)
		face_ex = poly.draw_poly(poly.get_ex_poly,poly.get_HeightB,ent)
		unless poly.get_in_poly == []
			for poly_in in poly.get_in_poly
				face_in = poly.draw_poly(poly_in,poly.get_HeightB,ent)
				face_in.erase!
			end
		end

		if face_ex.normal.z == 1
			face_ex.pushpull((poly.get_Height).m, true)
		end
		if face_ex.normal.z == -1
			face_ex.pushpull(-(poly.get_Height).m, true)
		end
		
		#將正射屋頂影像加入Sketchup中
		orthoname = "img_#{poly.get_ID}_#{poly.get_poly_index}"
		orthofile = File.join(orthodir,"#{orthoname}.tif")
		if mats[orthoname].nil?
			mat = mats.add(orthoname)
			mat.texture = orthofile
			mat.texture.size = [poly.get_imgWidth,poly.get_imgHeight]
		end
		
		facade = mats[File.basename(facadefiles.sample,".jpg")]
		
		ent.each do |face|
			if face.is_a? Sketchup::Face
				if face.normal.z != 1#貼隨機貼面
					face_position = face.vertices[0].position
					pt_array = []
					pt_array[0] = Geom::Point3d.new(face_position)
					pt_array[1] = Geom::Point3d.new(0,0,0)
					on_front = true
					face.position_material(facade, pt_array, on_front)
				else#貼正射影像
					pt_array = []
					pt_array[0] = Geom::Point3d.new(0,0,0)
					pt_array[1] = Geom::Point3d.new(0,0,0)
					on_front = true
					face.position_material(mats[orthoname], pt_array, on_front)
				end
			end
		end
		mod.export "model_#{poly.get_ID}_#{poly.get_poly_index}.dae", options_hash	
		status = ent.clear!
		sleep(0.1)
	end
end


	
