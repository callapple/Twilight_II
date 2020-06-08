
 rel
 dsk random3.c
 use random2.mac
 put 22:t2common.equ
 put 2:ainclude:e16.locator

init_random = *

rtlAddr equ 1
targetStr equ rtlAddr+3

 lda targetStr+2,s
 tax
 lda targetStr,s

 PushWord #t2PrivGetProcs
 PushWord #stopAfterOne+sendToName
 phx
 pha
 PushLong #8
 PushLong #dataOut
 _SendRequest
 jsl set_random_seed

 lda 1,s
 sta 1+4,s
 lda 2,s
 sta 2+4,s
 plx
 plx
 rtl

dataOut
 ds 2
set_random_seed = *
 ds 4
random = *
 ds 4
