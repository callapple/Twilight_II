
# Twilight II Worms UNIX MakeFile
# by Jim Maricondo
# v1.0 - 1/2/93 4:43pm

# First deal with all the dfork...

worms.d.root: worms.asm worms.mac 22/t2common.equ 22/dsdb.equ
   compile +w worms.asm keep=worms.d

worms.d: worms.d.root 22/random3.a.root
   link +w worms.d 22:random3.a keep=worms.d

# Now work with the rfork...

worms.r: worms.rez 22/t2common.rez
   compile worms.rez keep=worms.r

# Now put it together.

worms: worms.r worms.d
   duplicate -d worms.d worms
   duplicate -r worms.r worms
   setfile -at $4004 -t $bc worms -m .
   cp worms :jim1:system:cdevs:twilight:worms
   22:beep
