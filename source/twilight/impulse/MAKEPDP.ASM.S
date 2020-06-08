
*-----------------------------------------------------------------------------*
* makePdp.  V1.00 - 12/08/91 by JRM.
*
* Dereference handle (make a pointer) on the stack.
*
* Inputs:
*
* |previous contents|
* |-----------------|
* |     handle      |  Long - Handle to dereference.
* |-----------------|
* |     rtsAddr     |  Word - Return address.
* |-----------------|
*
* Outputs:
*
* |                 |
* |previous contents|
* |-----------------|
* |     pointer     |  Long - Dereferenced handle.
* |-----------------|
* |     rtsAddr     |  Word - Return address.
* |-----------------|
*

makePdp = *

DP = 1
TheHandle = DP+2

 plx  ; yank return address
 phd
 tsc
 tcd
 ldy #2
 lda [TheHandle],y
 tay
 lda [TheHandle]
 sta <TheHandle
 sty <TheHandle+2
 phx  ; push back return address
 rts
