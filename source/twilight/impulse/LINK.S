
 nol ;turn listing off (NO List)
 ovr  ;always assemble

 asm impulse ;assemble the file

 lnk impulse.l

 typ EXE
 sav impulse.d ;useful for testing!

* typ $BC
* cmd auxtype impulse,$4004
