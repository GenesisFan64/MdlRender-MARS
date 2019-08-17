# ======================================================================
# OBJ TO MARS
# 
# STABLE
# ======================================================================

import sys

# -------------------------------------------------
# VALUE SIZES
# 
# Vertices: LONG
# Faces:    WORD
# Vertex:   WORD
# Header:   LONG (numof_vert, numof_faces)
# -------------------------------------------------

# ======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

SCALE_SIZE=0x100
FROM_BLENDER=False #True

# ======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

num_vert      = 0
has_img       = False

projectname   = sys.argv[1]
CONVERT_TEX=0

INCR_Y=0
if len(sys.argv) == 3:
  #CONVERT_TEX = sys.argv[2]
  INCR_Y = sys.argv[2]

list_vertices = list()
list_faces    = list()
model_file    = open("mdl/"+projectname+".obj","r")
material_file = open("mdl/"+projectname+".mtl","r")	# CHECK BELOW
out_vertices  = open(projectname+"_vert.bin","wb")	# vertices (points)
out_faces     = open(projectname+"_face.bin","wb")	# faces
#out_vertex    = open(projectname+"_vrtx.bin","wb")	# texture vertex
out_head      = open(projectname+"_head.bin","wb")	# header
out_mtrl      = open(projectname+"_mtrl.asm","w")

used_triangles= 0
used_quads    = 0
solidcolor    = 1
reading       = True
vertex_list   = list()

random_mode   = False
random_color  = 1
indx_color    = 0
mtrl_curr     = 0
mtrl_index    = 0

# ======================================================================
# -------------------------------------------------
# Getting data
# -------------------------------------------------

while reading:
  text=model_file.readline()
  if text=="":
    reading=False

  # ---------------------------
  # vertices
  # ---------------------------
  
  if text.find("v") == False: 
    a = text[2:]
    point = a.replace("\n","").split(" ")
    if point[0] != "":
      x=float(point[0])*SCALE_SIZE
      y=(float(point[1])*SCALE_SIZE)
      z=float(point[2])*SCALE_SIZE

      mars_x=int(x)*-1
      mars_z=int(z)
      mars_y=int(y)+(int(INCR_Y)*-1)
      
      #print(mars_x,mars_y,mars_z)
      
      #if FROM_BLENDER == True:		# Y pos
        #mars_y=(int(y*SCALE_SIZE)*-1)+int((SCALE_SIZE/2))
      #else:
        #mars_y=int(y*SCALE_SIZE)*-1

      # LONG
      out_vertices.write( bytes([
	      mars_x >> 24 & 0xFF,
	      mars_x >> 16 & 0xFF,
	      mars_x >> 8 & 0xFF,
	      mars_x & 0xFF,
	      mars_y >> 24 & 0xFF,
	      mars_y >> 16 & 0xFF,
	      mars_y >> 8 & 0xFF,
	      mars_y & 0xFF,
	      mars_z >> 24 & 0xFF,
	      mars_z >> 16 & 0xFF,
	      mars_z >> 8 & 0xFF,
	      mars_z & 0xFF
	      ]) )
      num_vert += 1
	
  # ---------------------------
  # vertex
  # ---------------------------
  
  if text.find("vt") == False:
    a = text[2:]
    point = a.replace("\n","").split(" ")
    
    b = float(point[2])-1
    a = b - b - b
    vertex_list.append(float(point[1]))
    vertex_list.append(a)
    vertex_list.append(0)
    vertex_list.append(0)

    ## if needed later
    #x=float(point[1])
    #y=float(point[2])
    #mars_x=int(x)
    #mars_y=int(y)
    #out_vertex.write( bytes([
	      #mars_x >> 24 & 0xFF,
	      #mars_x >> 16 & 0xFF,
	      #mars_x >> 8 & 0xFF,
	      #mars_x & 0xFF,
	      #mars_y >> 24 & 0xFF,
	      #mars_y >> 16 & 0xFF,
	      #mars_y >> 8 & 0xFF,
	      #mars_y & 0xFF,
	      #]) )

  # ---------------------------
  # MATERIAL check
  # ---------------------------
  
  if text.find("usemtl") == False:
    material_file.seek(0)
    mtlname = text[7:].rstrip('\r\n')
    
    a = mtlname[:8]
    
    if a == "None":
      has_img = False
      random_mode = True
      
    # SOLID COLOR
    elif a == "MARSINDX":
      a = mtlname.split("_")
      out_mtrl.write("\t dc.l "+str(a[1])+","+str(0)+"\n")
      indx_color = int(a[1])
      
      img_width = 1
      img_height = 1
      has_img = False
      random_mode = False

    # TEXTURE
    else:
      # MATERIAL FILE READ LOOP
      mtlread = True
      while mtlread:
        mtltext=material_file.readline()
        if mtltext=="":
            mtlread=False
      
        # Grab material section
        if mtltext.find("newmtl "+mtlname) == False:
            i = True
            while i:
              b = material_file.readline()
              if b=="":
                  i=False
                  
              # filename
              if b.find("map_Kd") == False:
                  tex_fname = b[7:].rstrip('\r\n')
                  tex_file = open(tex_fname,"rb")

                  # COPYPASTED
                  tex_file.seek(1)
                  color_type = ord(tex_file.read(1))
                  image_type = ord(tex_file.read(1))

                  if color_type == 1:
                    pal_start = ord(tex_file.read(1))
                    pal_start += ord(tex_file.read(1)) << 8
                    pal_len = ord(tex_file.read(1))
                    pal_len += ord(tex_file.read(1)) << 8
                    ignore_this = ord(tex_file.read(1))
                    has_pal = True
	
                  if image_type == 1:
                    img_xstart = ord(tex_file.read(1))
                    img_xstart += ord(tex_file.read(1)) << 8
                    img_ystart = ord(tex_file.read(1))
                    img_ystart += ord(tex_file.read(1)) << 8
                    img_width = ord(tex_file.read(1))
                    img_width += ord(tex_file.read(1)) << 8
                    img_height = ord(tex_file.read(1))
                    img_height += ord(tex_file.read(1)) << 8
	
                    img_pixbits = ord(tex_file.read(1))
                    img_type = ord(tex_file.read(1)) 
                    if (img_type >> 5 & 1) == False:
                    	print("ERROR: TOP LEFT images only")
                    	tex_file.close()
                    	quit()
                    has_img = True
                    random_mode = False
                    
			# register name
                    b = tex_fname.split("/")[-1:]
                    a = b[0].split(".")
                    outname = a[0]

                    if int(CONVERT_TEX) == True:
                      print("Converting material:",mtlname)
                      
                      output_file = open("mtrl/"+outname+"_pal.bin","wb")
                      d = pal_len
                      while d:
                        d -= 1

                        a = (ord(tex_file.read(1)) & 0xF8 ) << 7
                        a |= (ord(tex_file.read(1)) & 0xF8 ) << 2
                        a |= (ord(tex_file.read(1)) & 0xF8 ) >> 3
                        output_file.write( bytes([ ((a>>8)&0xFF) , (a&0xFF) ]))
                      output_file.close()
                      
                      art_file = open("mtrl/"+outname+".bin","wb")
                      b = img_height
                      e = 0
                      while b:
                        c = img_width
                        while c:
                            a = ord(tex_file.read(1))
                            art_file.write( bytes([a]) )
                            c -= 1
                        b -= 1
                        e += 1
                      art_file.close()

                  else:
                      print("IMAGE TYPE NOT SUPPORTED:",hex(image_type))
                      has_img = False
                      random_mode = False

                  out_mtrl.write("\t dc.l Textr_"+str(mtlname)+","+str(img_width)+"\n")
                  #mtrl_curr = mtrl_index
                  #mtrl_index += 1
                  tex_file.close()

  # ---------------------------
  # Faces
  # ---------------------------
  
  if text.find("f") == False:
    a = text[2:]
    point = a.split(" ")
    if len(point) == 3:
      x_curr=point[0].split("/")
      y_curr=point[1].split("/")
      z_curr=point[2].split("/")

      # Set material id and size
      if has_img == True:
        a = mtrl_curr
        b = 0x8000|3
      else:
        if random_mode == True:
          a = random_color
          random_color += (1 & 0xFF)
          if random_color == 0:
            random_color = 1
        else:
          a = indx_color
        b = 3
      out_faces.write( bytes([b>>8&0xFF,b&0xFF]) )      # NUMOF_POINTS
      out_faces.write( bytes([a>>8&0xFF,a&0xFF]) )      # TEXTURE ID

      # set texture
      if has_img == True:
        # TEXTURE POINTS
        x=int(x_curr[1])-1
        y=int(y_curr[1])-1
        z=int(z_curr[1])-1
        outx_l = x >> 8 & 0xFF
        outx_r = x & 0xFF
        outy_l = y >> 8 & 0xFF
        outy_r = y & 0xFF
        outz_l = z >> 8 & 0xFF
        outz_r = z & 0xFF
        out_faces.write(bytes([
	          outx_l,outx_r,
	          outy_l,outy_r,
	          outz_l,outz_r,
	          ]))
      
        c=(int(x_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height
      
        c=(int(y_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height
        
        c=(int(z_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height
      
      x=int(x_curr[0])-1
      y=int(y_curr[0])-1
      z=int(z_curr[0])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      ]))

      used_triangles += 1
      
    # QUAD
    if len(point) == 4:
      x_curr=point[0].split("/")
      y_curr=point[1].split("/")
      z_curr=point[2].split("/")
      q_curr=point[3].split("/")

      # Set material id and size
      if has_img == True:
        a = mtrl_curr
        b = 0x8000|4
      else:
        if random_mode == True:
          a = random_color
          random_color += (1 & 0xFF)
          if random_color == 0:
            random_color = 1
        else:
          a = indx_color
        b = 4
      out_faces.write( bytes([b>>8&0xFF,b&0xFF]) )      # NUMOF_POINTS
      out_faces.write( bytes([a>>8&0xFF,a&0xFF]) )      # TEXTURE ID

      # TEXTURE POINTS
      # (material only)
      if has_img == True:
        x=int(x_curr[1])-1
        y=int(y_curr[1])-1
        z=int(z_curr[1])-1
        q=int(q_curr[1])-1
        outx_l = x >> 8 & 0xFF
        outx_r = x & 0xFF
        outy_l = y >> 8 & 0xFF
        outy_r = y & 0xFF
        outz_l = z >> 8 & 0xFF
        outz_r = z & 0xFF
        outq_l = q >> 8 & 0xFF
        outq_r = q & 0xFF
        out_faces.write(bytes([
	        outx_l,outx_r,
	        outy_l,outy_r,
	        outz_l,outz_r,
	        outq_l,outq_r,
	        ]))

        # set texture
        c=(int(x_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height
      
        c=(int(y_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height
        
        c=(int(z_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height

        c=(int(q_curr[1])-1)*4
        a=img_width
        b=img_height
        vertex_list[c+2]=img_width
        vertex_list[c+3]=img_height

      x=int(x_curr[0])-1
      y=int(y_curr[0])-1
      z=int(z_curr[0])-1
      q=int(q_curr[0])-1
      outx_l = x >> 8 & 0xFF
      outx_r = x & 0xFF
      outy_l = y >> 8 & 0xFF
      outy_r = y & 0xFF
      outz_l = z >> 8 & 0xFF
      outz_r = z & 0xFF
      outq_l = q >> 8 & 0xFF
      outq_r = q & 0xFF
      out_faces.write(bytes([
	      outx_l,outx_r,
	      outy_l,outy_r,
	      outz_l,outz_r,
	      outq_l,outq_r,
	      ]))
        
      used_quads += 1

#======================================================================
# ----------------------------
# Vertex convert
# ----------------------------

cntr = len(vertex_list)
if cntr != 0:
  out_vertex = open(projectname+"_vrtx.bin","wb")	# texture vertex

  x_tx = 0
  while cntr:
    x_l = int(vertex_list[x_tx+2] * vertex_list[x_tx])
    x_r = int(vertex_list[x_tx+3] * vertex_list[x_tx+1])-1
    out_vertex.write( bytes([
    x_l>>8&0xFF,x_l&0xFF,
    x_r>>8&0xFF,x_r&0xFF]))
    x_tx += 4
    cntr -= 4

  # padding
  b = out_vertex.tell()
  a = b & 0xF
  if a != 0:
    a = 0x10 - a
    out_vertex.write(bytes(a))
  out_vertex.close()

# ----------------------------
# face padding
b = out_faces.tell()
a = b & 0xF
if a != 0:
  a = (0x10 - a)
  out_faces.write(bytes(a))
	
#======================================================================
# ----------------------------
# End
# ----------------------------

out_head.write( bytes([
	num_vert >> 24 & 0xFF,
	num_vert >> 16 & 0xFF,
	num_vert >> 8 & 0xFF,
	num_vert & 0xFF,
	used_triangles+used_quads >> 24 & 0xFF,
	used_triangles+used_quads >> 16 & 0xFF,
	used_triangles+used_quads >> 8 & 0xFF,
	used_triangles+used_quads & 0xFF
	]) )

print("Vertices:",num_vert)
print("   Faces:",used_triangles+used_quads)
print("Polygons:",used_triangles)
print("   Quads:",used_quads)
#print("Done.")

#print(mtrl_tag)

model_file.close()
material_file.close()
out_vertices.close()
out_faces.close()
out_head.close()
out_mtrl.close()
