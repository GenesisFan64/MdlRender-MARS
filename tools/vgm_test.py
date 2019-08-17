#======================================================================
# PYTHON BASE
#======================================================================

import sys
import os.path

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------
      
#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

if os.path.exists(sys.argv[1]) == False:
	print("File not found")
	exit()
	
input_file = open(sys.argv[1],"rb")
input_file.seek(0x40)

#output_file = open(sys.argv[2],"wb")
#output_file.write("no pues, al rato")

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

working=True

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

while working:
	a = ord(input_file.read(1))
	if a == 0x4F:
		print("GG Stereo")
		input_file.seek(1,True)
		
	elif a == 0x50:
		b = ord(input_file.read(1))
		print("PSG",hex(b))
		
	elif a == 0x52:
		b = ord(input_file.read(1))
		c = ord(input_file.read(1))
		print("FM REG 1",hex(b),hex(c))
		
	elif a == 0x53:
		b = ord(input_file.read(1))
		c = ord(input_file.read(1))
		print("FM REG 2",hex(b),hex(c))
		
	elif a == 0x61:
		b = ord(input_file.read(1))
		c = ord(input_file.read(1))<<8
		print("Timer",hex(b|c))
		
	elif a == 0x62:
		print("Timer 60",hex(b|c))
		
	elif a == 0x63:
		print("Timer 60",hex(b|c))
		
	elif a == 0x66:
		print("END OF FILE")
		working = False
		
	elif a == 0x67:
		b = ord(input_file.read(1)) #ignore
		b = ord(input_file.read(1)) # TYPE
		c = ord(input_file.read(1))
		c += ord(input_file.read(1)) << 8
		c += ord(input_file.read(1)) << 16
		c += ord(input_file.read(1)) << 24
		print("DATA BLOCK",hex(c))
		input_file.seek(c,True)
		print("HERE:",hex(input_file.tell()))
	
	elif a == 0xE0:
		b = ord(input_file.read(1))
		b += ord(input_file.read(1)) << 8
		b += ord(input_file.read(1)) << 16
		b += ord(input_file.read(1)) << 24
		print("DATA SEEK",hex(b))
		
	elif a >= 0x80:
		print("DAC SAMPLE",hex(a))
		
	elif a >= 0x70:
		b = int(a)&0xF + 1
		print("TIMER quick",hex(b))
		
		
	else:
		print("NO CONOSCO ESTE VAL",hex(a),"(",hex(input_file.tell()-1),")")
		working = False


# ----------------------------
# End
# ----------------------------

input_file.close()
#output_file.close()    
