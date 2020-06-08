
# dissolve makefile
# by Jim Maricondo
# v1.0 - 3/21/93 9:15pm - coded

dissolve.r: dissolve.rez 22/t2common.rez
   compile dissolve.rez keep=dissolve.r

dissolve: dissolve.r dissolve.d
   duplicate -d dissolve.d dissolve
   duplicate -r dissolve.r dissolve
   setfile -at $4004 -t $bc dissolve -m .
   cp dissolve *:system:cdevs:twilight:dissolve
   22:beep
