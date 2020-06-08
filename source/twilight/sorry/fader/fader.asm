         
	mcopy	fader.mac
	keep	fader.d
	copy	22:t2common.equ
	copy	2:ainclude:e16.memory
*-----------------------------------------------------------------------------*
debugSymbols	gequ  $BAD               ; Put in debugging symbols ?
*-----------------------------------------------------------------------------*
* Fader! V1.0b1- Unknown.: Original version - by Jim R Maricondo.
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

	aif t:debugSymbols="G",.begin
	mnote '## Note - Debug Symbols: OFF'
	ago .jet
.begin
 	mnote '## Note - Debug Symbols: ON'
.jet

	DefineStack
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
               tcd

               lda   <T2Message         ; Get which setup procedure to call.
	cmp	#BlankT2
	bne	n1
	brk	$00
	debug	'blank'
	jsr	MMStartUp
	jsr	MMShutDown
	brl	again

n1	cmp	#MakeT2
	bne	n2
	brk	$00
	debug	'make'
	jsr	MMStartUp
	jsr	MMShutDown
	brl	notSupported

n2	cmp	#LoadSetupT2
	bne	n3
	brk	$00
	debug	'loads'
	jsr	MMStartUp
	jsr	MMShutDown
	bra	notSupported

n3	cmp	#UnloadSetupT2
	bne	n4
	brk	$00
	debug	'unloads'
	jsr	MMStartUp
	jsr	MMShutDown
	bra	notSupported

n4	cmp	#KillT2
	bne	n5
	brk	$00
	debug	'kill'
	jsr	MMStartUp
	jsr	MMShutDown
	bra	notSupported

n5	cmp	#HitT2
	bne	n6
	brk	$00
	debug	'hit'
	jsr	MMStartUp
	jsr	MMShutDown
	bra	notSupported

n6	cmp	#SaveT2
	bne	notSupported
	brk	$00
	debug	'save'
	jsr	MMStartUp
	jsr	MMShutDown
	bra	notSupported

again          lda   [T2data1]	; movePtr
               beq   again

;               LongResult
;               PushLong #ErrLen
;               pei   <T2Data2+2	; memory ID
;               PushWord #attrLocked+attrNoCross+attrNoSpec
;               PushLong #0
;               _NewHandle
;	PullLong <T2Result

;	PushLong #ErrMsg
;	pei	<T2Result+2
;	pei	<T2Result
;	PushLong #ErrLen
;	_PtrToHand

notSupported	anop
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

;ErrMsg	dc	c'Attention: Foreground Fader Error!',h'0d'
;	dc	c'Unable to load ATF file! ($0039)',h'00'
;ErrEnd	anop
;ErrLen   	equ	ErrEnd-ErrMsg

MMStartUp	name
	~MMStartUp
	pla
	sta	ID
	rts
MMShutDown	name
	~MMShutDown ID
	rts

ID	ds	2

               End
*-----------------------------------------------------------------------------*
	