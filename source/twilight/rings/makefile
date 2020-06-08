
# static makefile
# by Jim Maricondo
# v1.0 - 5/23/93 12:39pm - coded.

rings.r: rings.rez 22/t2common.rez
   compile rings.rez keep=rings.r

rings: rings.r rings.d
   duplicate -d rings.d rings
   duplicate -r rings.r rings
   setfile -at $4004 -t $bc rings -m .
   cp rings *:system:cdevs:twilight:rings
   22:beep
