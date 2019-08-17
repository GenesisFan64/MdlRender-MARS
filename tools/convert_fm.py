#======================================================================
# .raw.pal to VDP
# 
# STABLE
#======================================================================

#======================================================================

import sys
import os.path
      
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

if len(sys.argv) == 1:
	print("ARGS: inputfile outputfile")
	exit()
	
if os.path.exists(sys.argv[1]) == False:
	print("File not found")
	exit()

input_file = open(sys.argv[1],"rb")
output_file = open(sys.argv[2],"wb")
input_file.seek(0)
output_file.seek(0)
working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

input_file.seek(0x40)
algor = ord(input_file.read(1))
feedb = ord(input_file.read(1))
a = algor&0x7 | ((feedb&0x7)<<3)
output_file.write(bytes([a]))

# ------------------
# Deptune/Multiple
# ------------------
e=0x0
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

# ------------------
# RateScaling/Attack
# ------------------
e=0x2
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

# ------------------
# LFO/first decay
# ------------------
e=0x3
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

# ------------------
# Second decay/Sustain
# ------------------
e=0x4
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

# ------------------
# First decay
# ------------------
e=0x5
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

# ------------------
# Total level
# ------------------
e=0x1
input_file.seek(e)
a = ord(input_file.read(1))
input_file.seek(e+0x20)
b = ord(input_file.read(1)) 
input_file.seek(e+0x10)
c = ord(input_file.read(1)) 
input_file.seek(e+0x30)
d = ord(input_file.read(1)) 
output_file.write(bytes([a,b,c,d]))

#reading=True
#while working:
  #while reading:
    #eof = input_file.read(1)
    #input_file.seek(-1,1)
    #if eof == "":
      #reading=False
      #break
    
    #r = ord(input_file.read(1))
    #output_file.write(chr(r))
  
  #working=False
    
# ----------------------------
# End
# ----------------------------

print("Done.")
input_file.close()
output_file.close()    
