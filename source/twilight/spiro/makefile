
# Twilight II Spirographics UNIX MakeFile
# by Jim Maricondo
# v1.0 - 11/30/92 3:08pm
# v1.0.1 - 12/23/92 5:55pm
# v1.0.2 - 1/2/93 2:25pm
# v1.0.3 - 1/9/93 1:19am

# First deal with all the dfork...

spiro.d.root: spiro.cc spiro.h 22/t2.h
   compile +w spiro.cc keep=spiro.d

spiro.d: spiro.d.root 22/random3.c.root
   link +w spiro.d 22:random3.c keep=spiro.d

# Now work with the rfork...

spiro.r: spiro.rez 22/t2common.rez
   compile spiro.rez keep=spiro.r

# Now put it together.
# filetype spiro $bc $4004

spirographics: spiro.r spiro.d
   duplicate -d spiro.d spirographics
   duplicate -r spiro.r spirographics
   setfile -at $4004 -t $bc spirographics -m .
   cp spirographics :jim1:system:cdevs:twilight:spirographics
   22:beep
