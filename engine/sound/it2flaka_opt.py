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

if len(sys.argv) == 1:
	print("ARGS: inputfile [pattnumloop]")
	exit()
	
if os.path.exists(sys.argv[1]) == False:
	print("File not found")
	exit()
	
MASTERNAME = sys.argv[1][:-3]
input_file = open(sys.argv[1],"rb")
output_file = open(sys.argv[2]+"/"+MASTERNAME+".bin","wb")

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

working=True
zeroyes=False
zerocount=0

input_file.seek(0x20)
OrdNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
InsNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
SmpNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
#PatNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)

a = (OrdNum) + (InsNum*4) + (SmpNum*4)
OffPattList = 0xC0+a
input_file.seek(OffPattList)

can_loop = False
if len(sys.argv) > 3:
	can_loop = True
	loop_at = int(sys.argv[3])
	
#print ( hex(input_file.tell()) )

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

OrdNum -= 1
CurrPatt = 0
while OrdNum:
	if can_loop == True:
		if CurrPatt == loop_at:
			#print("LOOPING AT:",CurrPatt,"ADDR:",hex(output_file.tell()))
			print("LOOPING AT:",CurrPatt)
			output_file.write( bytes([0xFC]) )	#0xFE set loop
		
	# grab pattern data
	a = ord(input_file.read(1))
	a += ord(input_file.read(1)) << 8
	a += ord(input_file.read(1)) << 16
	a += ord(input_file.read(1)) << 24
	input_file.seek(a)
	
	#a = ord(input_file.read(1))
	#a += ord(input_file.read(1)) << 8
	#input_file.seek(6,True)
	#a = input_file.read(a)
	#output_file.write(a)
	
	patlen = ord(input_file.read(1))
	patlen |= ord(input_file.read(1)) << 8
	input_file.seek(6,True)
	while patlen:
		a = ord(input_file.read(1))
		if a == 0:
			if zeroyes == True:
				zerocnt += 1
				if zerocnt == 0x40:
					output_file.write(bytes([0x7F]))
					zerocnt = 1
					print("TODO")
					exit()
			else:
				zeroyes = True
				zerocnt = 1
		else:
			if zeroyes == True:
				zerocnt |= 0x40
				output_file.write(bytes([zerocnt]))
			output_file.write(bytes([a]))
			zeroyes = False
		patlen -= 1
	
	OffPattList += 4
	CurrPatt += 1
	input_file.seek(OffPattList)
	OrdNum -= 1

#print(hex(output_file.tell()))
output_file.write( bytes([0xFD]) )		#-1 end of track
		
# ----------------------------
# End
# ----------------------------

input_file.close()
output_file.close()    
