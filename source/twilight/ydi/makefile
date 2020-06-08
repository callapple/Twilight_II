
# Twilight II YouDrawIt UNIX MakeFile
# by Jim Maricondo
# v1.0 - 11/28/92 9:47pm
# v1.1 - 12/30/92 4:23pm
# v1.2 - 1/1/93 3:09pm

# First deal with all the dfork...

ydi.d.root: ydi.asm ydi.equ 22/t2common.equ 22/dsdb.equ 22/makepdp.asm
   compile +w ydi.asm keep=ydi.d

ydi.d: ydi.d.root
   link +w ydi.d keep=ydi.d

# Now work with the rfork...

ydi.r: ydi.rez 22/t2common.rez
   compile ydi.rez keep=ydi.r

# Now put it together.

youdrawit: ydi.r ydi.d
   duplicate -d ydi.d youdrawit
   duplicate -r ydi.r youdrawit
   setfile -at $4004 -t $bc youdrawit -m .
   cp youdrawit :jim1:system:cdevs:twilight:youdrawit
   22:beep
