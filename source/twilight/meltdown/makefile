
# Twilight II Meltdown UNIX MakeFile
# by Jim Maricondo
# v1.0 - 1/3/93 2:13pm
# v1.0.1 - 1/9/93 1:17am
# v1.0.2 - 1/20/93 9:58pm

# First deal with all the dfork...

Meltdown.d.root: Meltdown.cc 22/t2.h
   compile +w Meltdown.cc keep=Meltdown.d

meltplot.c.root: meltplot.asm meltplot.mac
   compile +w meltplot.asm keep=meltplot.c

Meltdown.d: Meltdown.d.root 22/random3.c.root meltplot.c.root
   link +w Meltdown.d 22:random3.c meltplot.c keep=Meltdown.d

# Now work with the rfork...

Meltdown.r: Meltdown.rez 22/t2common.rez
   compile Meltdown.rez keep=Meltdown.r

# Now put it together.

Meltdown: Meltdown.r Meltdown.d
   duplicate -d Meltdown.d Meltdown
   duplicate -r Meltdown.r Meltdown
   setfile -at $4004 -t $bc Meltdown -m .
   cp Meltdown :jim1:system:cdevs:twilight:Meltdown
   22:beep
