
# Twilight II Tiler UNIX MakeFile
# by Jim Maricondo
# v1.0 - 10/24/92 8:24pm
# v1.1 - 12/13/92 4:40pm
# v1.1.1 - 12/23/92 4:55pm
# v1.1.2 - 12/29/92 9:41pm
# v1.1.3 - 1/2/93 3:20pm
# v1.1.4 - 1/9/93 1:19am

# First deal with all the dfork...

tiler.d.root: tiler.asm tiler.mac 22/t2common.equ 22/dsdb.equ 22/makepdp.asm
   compile +w tiler.asm keep=tiler.d

tiler.d: tiler.d.root 22/random3.a.root
   link +w tiler.d 22:random3.a keep=tiler.d

# Now work with the rfork...

tiler.r: tiler.rez 22/t2common.rez
   compile tiler.rez keep=tiler.r

# Now put it together.

tiler: tiler.r tiler.d
   duplicate -d tiler.d tiler
   duplicate -r tiler.r tiler
   setfile -at $4004 -t $bc tiler -m .
   cp tiler :jim1:system:cdevs:twilight:tiler
   22:beep
