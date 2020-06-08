
# movieTheatre makefile
# by Jim Maricondo
# v1.0 - 1/4/93 - coded (tC?)
# v1.0.1 - 1/9/93 1:19am - "-m .", ":", etc. (Jg?!)
# v1.0.2 - 2/16/93 8:54pm - t2common.rez.  (HB!??!)

movie.r: movie.rez 22/t2common.rez
   compile movie.rez keep=movie.r

movietheater: movie.d movie.r
   duplicate -d movie.d movietheater
   duplicate -r movie.r movietheater
   setfile -at $4004 -t $bc movietheater -m .
   cp movieTheater *:system:cdevs:twilight:MovieTheater
   22:beep
