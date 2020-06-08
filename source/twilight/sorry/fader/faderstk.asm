
	mcopy	fader.mac
	keep	fader.d
	copy	..t2common.equ
*-----------------------------------------------------------------------------*
*debugSymbols	gequ  $BAD               ; Put in debugging symbols ?
*-----------------------------------------------------------------------------*
* Fader! V1.0b1-  Unknown: Original version - by Jim R Maricondo.
*        V1.0b2- 05/10/92: Updated for Generation 2 Module Format. (d31)
*        V1.0b3- 05/14/92: Updated to use new T2ModuleFlags bits. (d32)
*
* Fade screen out.  Wait until user activity.  Fade screen in.
*
* Inputs:
*
* |previous contents|
* |-----------------|
* |    T2Result     |  Long - Result space.  (currently reserved)
* |-----------------|
* |    T2Message    |  Word - Action to perform.
* |-----------------|
* |     T2data1     |  Long - Action specific input.
* |-----------------|
* |     T2data2     |  Long - Action specific input.
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*
* Outputs:
*
* |previous contents|
* |-----------------|
* |    T2Result     |  Long - Result space.  (reserved at this time)
* |-----------------|
* |     rtlAddr     |  3 bytes - Return address.
* |-----------------|
*

Fader          Start
	kind  $1000	; no special memory
               debug 'Fader'

	mnote ''
	aif t:debugSymbols="G",.begin
	mnote '## Note - Debug Symbols: OFF'
	ago .jet
.begin
 	mnote '## Note - Debug Symbols: ON'
.jet

	DefineStack
oldBorder      word
stkFrameSize   EndLocals
dpageptr       word
dbank          byte
rtlAddr	block	3
T2data2	long
T2data1	long
T2message	word
T2result	long

               phb
               phd
               tsc
               sec
               sbc   #stkFrameSize
               tcs
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#BlankT2
	bne	notSupported

	lda	CLOCKCTL
	and	#$FFF0
	sta	CLOCKCTL

again          lda   [T2data1]	; movePtr
               beq   again

notSupported   tsc
               clc
               adc   #stkFrameSize
               tcs
               pld
               plb
               lda   1,s
               sta   1+10,s
               lda   2,s
               sta   2+10,s
               tsc
               clc
               adc   #10
               tcs
               clc
               rtl

               End
*-----------------------------------------------------------------------------*
	