
# Twilight II Spirographics UNIX MakeFile
# by Jim Maricondo
# v1.0 - 18 Jul 93 6:22pm

# First deal with all the dfork...

ball.d.root: ball.cc config.cc 22/t2.h
   compile +w ball.cc keep=ball.d

ball.d: ball.d.root ball.d.a
   link +w ball.d keep=ball.d

# Now work with the rfork...

ball.r: ball.rez 22/t2common.rez
   compile ball.rez keep=ball.r

# Now put it together.
# filetype ball $bc $4004

ballgraphics: ball.r ball.d
   duplicate -d ball.d ball
   duplicate -r ball.r ball
   setfile -at $4004 -t $bc ball -m .
   cp ball *:system:cdevs:twilight:ball
   22:beep
