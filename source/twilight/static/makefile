
# static makefile
# by Jim Maricondo
# v1.0 - 2/7/93 3:21pm - coded.
# v1.0.1 - 2/16/93 8:55pm - t2common.rez.  (HB!??!)

static.r: static.rez 22/t2common.rez
   compile static.rez keep=static.r

static: static.r static.d
   duplicate -d static.d static
   duplicate -r static.r static
   setfile -at $4004 -t $bc static -m .
   cp static *:system:cdevs:twilight:static
   22:beep
