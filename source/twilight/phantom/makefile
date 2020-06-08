
# Twilight II Strobe UNIX MakeFile
# by Jim Maricondo
# v1.0 - 2/19/93 8:36pm

# First deal with all the dfork...

phantom.d.root: phantom.asm phantom.mac 22/t2common.equ 22/dsdb.equ
   compile +w phantom.asm keep=phantom.d

phantom.d: phantom.d.root
   link +w phantom.d keep=phantom.d

# Now work with the rfork...

phantom.r: phantom.rez 22/t2common.rez
   compile phantom.rez keep=phantom.r

# Now put it together.

phantom: phantom.r phantom.d
   duplicate -d phantom.d phantom
   duplicate -r phantom.r phantom
   setfile -at $4004 -t $bc phantom -m .
   duplicate phantom :jim1:system:cdevs:twilight:phantom
   22:beep
