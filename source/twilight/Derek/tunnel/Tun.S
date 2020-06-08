* Link the tunnel module.


filelen geq $133F
 asm Tunnel.t2
 lnk Tunnel.twlt.l
 lnk CIRCLES ;link in the compressed circles
 ds $1000



 typ RTL
 sav Tunnel.twlt
 end

 cmd auxtype Tunnel.twlt,$5457
