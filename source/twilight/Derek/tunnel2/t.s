
 nol ;turn listing off (NO List)
 ovr  ;always assemble

* Link the tunnel module.

* filelen geq $133F

 asm Tunnel.t2.2

 lnk Tunnel.twlt.l
 lnk Circles2

* lnk CIRCLES ;link in the compressed circles

 typ $BC
 sav */system/cdevs/twilight/Hypnotist
 cmd auxtype */system/cdevs/twilight/Hypnotist,$4004
