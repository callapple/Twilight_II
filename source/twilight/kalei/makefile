
# Kalei makefile
# by Jim Maricondo
# v1.0 - 1/9/93 2:15pm - coded. (Jg?!)

kalei.r: kalei.rez 22/t2common.rez
   compile kalei.rez keep=kalei.r

kaleidoscope: kalei.r kalei.d
   duplicate -d kalei.d kaleidoscope
   duplicate -r kalei.r kaleidoscope
   setfile -at $4004 -t $bc kaleidoscope -m .
   cp kaleidoscope *:system:cdevs:twilight:kaleidoscope
   22:beep
