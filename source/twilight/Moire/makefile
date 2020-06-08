
# Twilight II Moire UNIX MakeFile
# by Jim Maricondo
# v1.0 - 10/24/92 8:06pm
# v1.1 - 12/23/92 4:52pm
# v1.1.1 - 1/9/93 1:17am

# First deal with all the dfork...

moire.d.root: moire.cc moire.h 22/t2.h
   compile +w moire.cc keep=moire.d

moire.d: moire.d.root 22/random3.c.root
   link +w moire.d 22:random3.c keep=moire.d

# Now work with the rfork...

moire.r: moire.rez 22/t2common.rez
   compile moire.rez keep=moire.r

# Now put it together.

moire: moire.r moire.d
   duplicate -d moire.d moire
   duplicate -r moire.r moire
   setfile -at $4004 -t $bc moire -m .
   cp moire :jim1:system:cdevs:twilight:moire
   22:beep
