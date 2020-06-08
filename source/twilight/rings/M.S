
 nol ;turn listing off (NO List)
 ovr  ;always assemble

 asm rings ;assemble the file

 lnk rings.l
 lnk 5/misc
 lib 5
 typ EXE
 sav rings.d ;useful for testing!

* typ $BC
* cmd auxtype impulse,$4004
