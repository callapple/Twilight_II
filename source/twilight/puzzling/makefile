
# Twilight II Puzzling UNIX MakeFile
# by Jim Maricondo
# v1.0 - 10/24/92 2:52pm
# v1.1 - 1/2/93 6:08pm
# v1.1.1 - 1/9/93 1:19am

# First deal with all the dfork...

puzzling.d.root: puzzling.asm puzzling.mac 22/t2common.equ 22/dsdb.equ 22/makepdp.asm
   compile +w puzzling.asm keep=puzzling.d

puzzling.d: puzzling.d.root 22/random3.a.root
   link +w puzzling.d 22:random3.a keep=puzzling.d

# Now work with the rfork...

puzzling.r: puzzling.rez 22/t2common.rez
   compile puzzling.rez keep=puzzling.r

# Now put it together.

puzzling: puzzling.r puzzling.d
   duplicate -d puzzling.d puzzling
   duplicate -r puzzling.r puzzling
   setfile -at $4004 -t $bc puzzling -m .
   cp puzzling :Jim1:system:cdevs:twilight:puzzling
   22:beep
