
# Twilight II Universe UNIX MakeFile
# by Jim Maricondo
# v1.0 - 10/24/92 8:38pm
# v1.1 - 1/2/93 2:32pm 3:18pm
# v1.1.1 - 1/9/93 1:19am
# v1.1.2 - 2/16/93 8:55pm - t2common.rez.  (HB!??!)

# First deal with all the dfork...

Universe.d.root: Universe.asm Universe.mac 22/t2common.equ 22/dsdb.equ 22/makepdp.asm
   compile +w Universe.asm keep=Universe.d

Universe.d: Universe.d.root 22/random3.a.root
   link +w Universe.d 22:random3.a keep=Universe.d

# Now work with the rfork...

Universe.r: Universe.rez 22/t2common.rez
   compile Universe.rez keep=Universe.r

# Now put it together.

Universe: Universe.r Universe.d
   duplicate -d Universe.d Universe
   duplicate -r Universe.r Universe
   setfile -at $4004 -t $bc universe -m .
   cp Universe :jim1:system:cdevs:twilight:Universe
   22:beep
