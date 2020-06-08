
# Twilight II Strobe UNIX MakeFile
# by Jim Maricondo
# v1.0 - 1/2/93 5:48pm
# v1.0.1 - 1/9/93 1:19am

# First deal with all the dfork...

strobe.d.root: strobe.asm strobe.mac 22/t2common.equ 22/dsdb.equ
   compile +w strobe.asm keep=strobe.d

strobe.d: strobe.d.root 22/random3.a.root
   link +w strobe.d 22:random3.a keep=strobe.d

# Now work with the rfork...

strobe.r: strobe.rez 22/t2common.rez
   compile strobe.rez keep=strobe.r

# Now put it together.

strobe: strobe.r strobe.d
   duplicate -d strobe.d strobe
   duplicate -r strobe.r strobe
   setfile -at $4004 -t $bc strobe -m .
   cp strobe :jim1:system:cdevs:twilight:strobe
   22:beep
