
# Sound Patcher UNIX Makefile
# by Jim Maricondo
# v1.0 - 1/9/93 - coded (jG?!!)

patch.d: patch.asm
 asml patch.asm keep=patch.d

patch.r: patch.rez
 compile patch.rez keep=patch.r

patch: patch.d patch.r
 duplicate -d patch.d patch
 duplicate -r patch.r patch
 filetype patch exe
