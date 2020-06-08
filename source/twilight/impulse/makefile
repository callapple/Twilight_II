
# impulse makefile
# by Jim Maricondo
# v1.0 - 1/1/93 - coded (tC)
# v1.0.1 - 1/9/93 1:17am 1:56am - enhanced greatly (jG!?)
# v1.0.2 - 2/16/93 8:55pm - t2common.rez.  (HB!??!)

impulse.r: impulse.rez 22/t2common.rez
   compile impulse.rez keep=impulse.r

impulse: impulse.d impulse.r
   duplicate -d impulse.d impulse
   duplicate -r impulse.r impulse
   setfile -at $4004 -t $bc impulse -m .
   setfile 22/impulse -m .
   cp impulse *:system:cdevs:twilight:impulse
   22:beep
