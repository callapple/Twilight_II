
	case	on
	keep	random2.c
	mcopy	random2.mac
	copy	22:t2common.equ
	copy	2:ainclude:e16.locator

init_random	Start
	PushWord #t2PrivGetProcs
	PushWord #stopAfterOne+sendToName
	PushLong #toT2String
	PushLong #8
	PushLong #dataOut
	_SendRequest
	jsl	set_random_seed
	rtl

toT2String     entry
	str	'DYA~Twilight II~'

dataOut	anop
	ds	2
set_random_seed entry
	ds	4
random	entry
	ds	4

	End