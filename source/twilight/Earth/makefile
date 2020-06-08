
# Twilight II Earth UNIX MakeFile
# by Jim Maricondo
# v1.0 - 10/24/92 2:14pm
# v1.1 - 1/3/92 3:15pm
# v1.1.1 - 1/9/93 1:17am

# First deal with all the dfork...

earth.d.root: earth.asm earth.mac e1.15 e16.30 e31.42 22/t2common.equ 22/dsdb.equ
   compile +w earth.asm keep=earth.d

earth.d: earth.d.root
   link +w earth.d keep=earth.d

# Now work with the rfork...

earth.r: earth.rez
   compile earth.rez keep=earth.r

# Now put it together.

earth: earth.r earth.d
   duplicate -d earth.d earth
   duplicate -r earth.r earth
   setfile -at $4004 -t $bc earth -m .
   cp earth :jim1:system:cdevs:twilight:earth
   22:beep
