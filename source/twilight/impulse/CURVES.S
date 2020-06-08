
* org 0
* lst off

*-------------------------------------------------
Curve_Table = *
 da Curve_Dya
 da Curve_Diamond
 da Curve_Pyramid
 da Curve_Fta
 da Curve_Cube
 da Curve_Car
 da Curve_Dya2D
 da Curve_CubeRev
 da Curve_Acs
 da Curve_AppleAlone
 da Curve_Apple
 da Curve_Acs2
 da Curve_Rebound
 da Curve_France
 da Curve_World
* da Curve_Tower
 da Curve_Ship
 da Curve_GS

 da 0 ; end of table
*-------------------------------------------------
Curve_GS
 da $0200 ; zoom
 da $280 ; zoom large shape mode
 da 6 ; max x
 da 6 ; max y
 da 6 ; max z
 da $FFF ; shape color
 da $666 ; anti aliasing color
 da $0000 ; perspective off

 dfb $80,$00,$00
 dfb $00,$01,$00
 dfb $09,$01,$00
 dfb $09,$00,$00
 dfb $00,$00,$00
 dfb $00,$00,$0B
 dfb $09,$00,$0B
 dfb $09,$00,$00

 dfb $80,$01,$00
 dfb $00,$01,$01
 dfb $09,$01,$01
 dfb $09,$01,$00

 dfb $80,$01,$01
 dfb $00,$04,$01
 dfb $09,$04,$01
 dfb $09,$01,$01

 dfb $80,$00,$0B
 dfb $00,$04,$0B
 dfb $09,$04,$0B
 dfb $09,$00,$0B

 dfb $80,$04,$01
 dfb $00,$04,$0B

 dfb $89,$04,$01
 dfb $09,$04,$0B

 dfb $80,$01,$01
 dfb $00,$03,$0B
 dfb $09,$03,$0B
 dfb $09,$01,$01

 dfb $80,$00,$00
 dfb $00,$00,$00

 dfb $80,$04,$01
 dfb $00,$0C,$01
 dfb $09,$0C,$01
 dfb $09,$04,$01

 dfb $81,$05,$01
 dfb $01,$0B,$01
 dfb $08,$0B,$01
 dfb $08,$05,$01
 dfb $01,$05,$01

 dfb $80,$04,$04
 dfb $00,$0C,$04
 dfb $09,$0C,$04
 dfb $09,$04,$04
 dfb $00,$04,$04

 dfb $80,$0C,$01
 dfb $00,$0C,$04

 dfb $80,$0B,$04
 dfb $00,$0B,$0B
 dfb $09,$0B,$0B
 dfb $09,$0B,$04

 dfb $89,$0C,$04
 dfb $09,$0C,$01

 dfb $80,$04,$0B
 dfb $00,$0B,$0B

 dfb $89,$04,$0B
 dfb $09,$0B,$0B

 hex FF

*=================================================
p = 4
*-------------------------------------------------
Curve_Fta DA $280 ; 571 ; Zoom $280
 da $352
 DA 22 ; Max_X
 DA 12 ; Max_Y
 DA 2 ; Max_Z
 DA $F00 ; Couleur
 DA $600 ; Anti-Aliasing  4
 DA $FFFF ; 0 ; Perspective On

 DFB $80+8,0,0,8,12,0
 DFB 12,12,0
 DFB 12,4,0
 DFB 23,4,0
 DFB 23,0,0
 DFB 8,0,0

 DFB $80+8,0,p,8,12,p
 DFB 12,12,p
 DFB 12,4,p
 DFB 23,4,p
 DFB 23,0,p
 DFB 8,0,p

 DFB $80+8,0,0,8,0,p
 DFB $80+8,12,0,8,12,p
 DFB $80+12,12,0,12,12,p
 DFB $80+12,4,0,12,4,p
 DFB $80+23,4,0,23,4,p
 DFB $80+23,0,0,23,0,p

 DFB $80+8,14,0,8,18,0
 DFB 18,18,0
 DFB 19,19,0
 DFB 19,26,0
 DFB 23,26,0
 DFB 23,18,0
 DFB 22,16,0
 DFB 21,15,0
 DFB 19,14,0
 DFB 8,14,0

 DFB $80+8,14,p,8,18,p
 DFB 18,18,p
 DFB 19,19,p
 DFB 19,26,p
 DFB 23,26,p
 DFB 23,18,p
 DFB 22,16,p
 DFB 21,15,p
 DFB 19,14,p
 DFB 8,14,p

 DFB $80+8,14,p,8,14,0
 DFB $80+8,18,p,8,18,0
 DFB $80+18,18,p,18,18,0
 DFB $80+19,19,p,19,19,0
 DFB $80+19,26,p,19,26,0
 DFB $80+23,26,p,23,26,0
 DFB $80+23,18,p,23,18,0
 DFB $80+22,16,p,22,16,0
 DFB $80+21,15,p,21,15,0
 DFB $80+19,14,p,19,14,0

 DFB $80+1,0,0,1,39,0
 DFB 19,44,0
 DFB 23,44,0
 DFB 23,28,0
 DFB 19,28,0
 DFB 8,31,0
 DFB 8,35,0
 DFB 19,32,0
 DFB 19,40,0
 DFB 5,36,0
 DFB 5,0,0
 DFB 1,0,0

 DFB $80+1,0,p,1,39,p
 DFB 19,44,p
 DFB 23,44,p
 DFB 23,28,p
 DFB 19,28,p
 DFB 8,31,p
 DFB 8,35,p
 DFB 19,32,p
 DFB 19,40,p
 DFB 5,36,p
 DFB 5,0,p
 DFB 1,0,p

 DFB $80+1,0,p,1,0,0
 DFB $80+1,39,p,1,39,0
 DFB $80+19,44,p,19,44,0
 DFB $80+23,44,p,23,44,0
 DFB $80+23,28,p,23,28,0
 DFB $80+19,28,p,19,28,0
 DFB $80+8,31,p,8,31,0
 DFB $80+8,35,p,8,35,0
 DFB $80+19,32,p,19,32,0
 DFB $80+19,40,p,19,40,0
 DFB $80+5,36,p,5,36,0
 DFB $80+5,0,p,5,0,0

 DFB $FF
*-------------------------------------------------
Curve_Dya

* setting 1 (ala FTA) - small, but stays onscreen: 571/22,12,2/col/$0004/0
* setting 2 (can't do) - impossible but cool: 600/$16,$9-A,$2/col/$0004/0
* setting 3 - cool, medium size: 600/10,12,2/$0004/0
* setting 4 - unknown but cool: 600/$14,12,8/$0004/0
* setting 5 - cool and LARGE! #1: 600/8,12,4/$0004/0

 da 600
 da $2b0
 da 8,12,4
 da $FFF ; color
 da $777 ; anti aliasing    888
 da 0 ;$FFFF ; perspective on

* D
 dfb $80+0,0,0
 dfb 8,0,0
 dfb 8,5,0
 dfb 5,8,0
 dfb 0,8,0
 dfb 0,0,0
 dfb $80+2,2,0
 dfb 6,2,0
 dfb 6,4,0
 dfb 4,6,0
 dfb 2,6,0
 dfb 2,2,0

* Y
 dfb $80+9,0,0
 dfb 11,0,0
 dfb 11,6,0
 dfb 14,9,0
 dfb 20,9,0
 dfb 20,11,0
 dfb 12,11,0
 dfb 10,9,0
 dfb 8,11,0
 dfb 0,11,0
 dfb 0,9,0
 dfb 6,9,0
 dfb 9,6,0
 dfb 9,0,0

* A
 dfb $80+12,0,0
 dfb 14,0,0
 dfb 14,2,0
 dfb 18,2,0
 dfb 18,0,0
 dfb 20,0,0
 dfb 20,8,0
 dfb 15,8,0
 dfb 12,5,0
 dfb 12,0,0
 dfb $80+14,4,0
 dfb 18,4,0
 dfb 18,6,0
 dfb 16,6,0
 dfb 14,4,0

* connections between normal plane and 3d plane
* D
 dfb $80+0,0,0
 dfb 0,0,p
 dfb $80+8,0,0
 dfb 8,0,p
 dfb $80+8,5,0
 dfb 8,5,p
 dfb $80+5,8,0
 dfb 5,8,p
 dfb $80+0,8,0
 dfb 0,8,p
 dfb $80+0,0,0
 dfb 0,0,p

 dfb $80+2,2,0
 dfb 2,2,p
 dfb $80+6,2,0
 dfb 6,2,p
 dfb $80+6,4,0
 dfb 6,4,p
 dfb $80+4,6,0
 dfb 4,6,p
 dfb $80+2,6,0
 dfb 2,6,p
 dfb $80+2,2,0
 dfb 2,2,p

* Y
 dfb $80+9,0,0
 dfb 9,0,p
 dfb $80+11,0,0
 dfb 11,0,p
 dfb $80+11,6,0
 dfb 11,6,p
 dfb $80+14,9,0
 dfb 14,9,p
 dfb $80+20,9,0
 dfb 20,9,p
 dfb $80+20,11,0
 dfb 20,11,p
 dfb $80+12,11,0
 dfb 12,11,p
 dfb $80+10,9,0
 dfb 10,9,p
 dfb $80+8,11,0
 dfb 8,11,p
 dfb $80+0,11,0
 dfb 0,11,p
 dfb $80+0,9,0
 dfb 0,9,p
 dfb $80+6,9,0
 dfb 6,9,p
 dfb $80+9,6,0
 dfb 9,6,p
 dfb $80+9,0,0
 dfb 9,0,p

* A
 dfb $80+12,0,0
 dfb 12,0,p
 dfb $80+14,0,0
 dfb 14,0,p
 dfb $80+14,2,0
 dfb 14,2,p
 dfb $80+18,2,0
 dfb 18,2,p
 dfb $80+18,0,0
 dfb 18,0,p
 dfb $80+20,0,0
 dfb 20,0,p
 dfb $80+20,8,0
 dfb 20,8,p
 dfb $80+15,8,0
 dfb 15,8,p
 dfb $80+12,5,0
 dfb 12,5,p
 dfb $80+12,0,0
 dfb 12,0,p
 dfb $80+14,4,0
 dfb 14,4,p
 dfb $80+18,4,0
 dfb 18,4,p
 dfb $80+18,6,0
 dfb 18,6,p
 dfb $80+16,6,0
 dfb 16,6,p
 dfb $80+14,4,0
 dfb 14,4,p

* 3d plane
 dfb $80+0,0,p
 dfb 8,0,p
 dfb 8,5,p
 dfb 5,8,p
 dfb 0,8,p
 dfb 0,0,p
 dfb $80+2,2,p
 dfb 6,2,p
 dfb 6,4,p
 dfb 4,6,p
 dfb 2,6,p
 dfb 2,2,p

 dfb $80+9,0,p
 dfb 11,0,p
 dfb 11,6,p
 dfb 14,9,p
 dfb 20,9,p
 dfb 20,11,p
 dfb 12,11,p
 dfb 10,9,p
 dfb 8,11,p
 dfb 0,11,p
 dfb 0,9,p
 dfb 6,9,p
 dfb 9,6,p
 dfb 9,0,p

 dfb $80+12,0,p
 dfb 14,0,p
 dfb 14,2,p
 dfb 18,2,p
 dfb 18,0,p
 dfb 20,0,p
 dfb 20,8,p
 dfb 15,8,p
 dfb 12,5,p
 dfb 12,0,p
 dfb $80+14,4,p
 dfb 18,4,p
 dfb 18,6,p
 dfb 16,6,p
 dfb 14,4,p

 hex FF
*-------------------------------------------------
Curve_Dya2D

 do 0
 da 600
 da 8,12,4
 da $c96 ; color   ff0
 da $643 ; anti aliasing 88/770
 da $FFFF ; perspective on
 fin

 DA $4c0 ; 571 ; Zoom $280
 da $532
 DA 14 ; Max_X  22
 DA 10 ; Max_Y  12
 DA 4 ; Max_Z   2
 DA $c96 ; Couleur ff0
 DA $643 ; Anti-Aliasing 660
 DA $FFFF ; 0 ; Perspective On

* D
 dfb $80+0,0,0
 dfb 8,0,0
 dfb 8,5,0
 dfb 5,8,0
 dfb 0,8,0
 dfb 0,0,0
 dfb $80+2,2,0
 dfb 6,2,0
 dfb 6,4,0
 dfb 4,6,0
 dfb 2,6,0
 dfb 2,2,0

* Y
 dfb $80+9,0,0
 dfb 11,0,0
 dfb 11,6,0
 dfb 14,9,0
 dfb 20,9,0
 dfb 20,11,0
 dfb 12,11,0
 dfb 10,9,0
 dfb 8,11,0
 dfb 0,11,0
 dfb 0,9,0
 dfb 6,9,0
 dfb 9,6,0
 dfb 9,0,0

* A
 dfb $80+12,0,0
 dfb 14,0,0
 dfb 14,2,0
 dfb 18,2,0
 dfb 18,0,0
 dfb 20,0,0
 dfb 20,8,0
 dfb 15,8,0
 dfb 12,5,0
 dfb 12,0,0
 dfb $80+14,4,0
 dfb 18,4,0
 dfb 18,6,0
 dfb 16,6,0
 dfb 14,4,0

 hex FF
*-------------------------------------------------
Curve_Cube DA $1000 ; $1000
 da $1ac0
 DA 2,2,2
 DA $000F
 DA $0006 ;4
 DA $FFFF ; Perspective On

 DFB $80+0,0,0,0,4,0
 DFB 4,4,0,4,0,0,0,0,0
 DFB $80+0,0,4,0,4,4
 DFB 4,4,4,4,0,4,0,0,4
 DFB $80+0,0,0,0,0,4
 DFB $80+0,4,0,0,4,4
 DFB $80+4,0,0,4,0,4
 DFB $80+4,4,0,4,4,4

 HEX FF

* DS \
*-------------------------------------------------
* (600)
Curve_Car da $2f1
 da $43b
 DA 16,16,16
 DA $F8A ;f00 //f8f
 DA $734 ;400/600  //737
 DA $FFFF ;0
 DFB $80+5,0,8,5,20,8,13,24,8,15,30,8,17,32,8
 DFB 23,32,8,23,0,8,5,0,8
 DFB $80+5,0,24,5,20,24,13,24,24,15,30,24,17,32,24
 DFB 23,32,24,23,0,24,5,0,24
 DFB $80+5,0,8,5,0,24,$80+5,20,8,5,20,24
 DFB $80+13,24,8,13,24,24,$80+15,30,8,15,30,24
 DFB $80+17,32,8,17,32,24,$80+23,32,8,23,32,24
 DFB $80+23,0,8,23,0,24
 DFB $80+9,0,10,9,0,14,15,0,14,15,0,10,9,0,10
 DFB $80+9,0,18,9,0,22,15,0,22,15,0,18,9,0,18
 DFB $80+20,21,6,20,27,6,26,27,6,26,21,6,20,21,6
 DFB $80+20,21,10,20,27,10,26,27,10,26,21,10,20,21,10
 DFB $80+20,21,22,20,27,22,26,27,22,26,21,22,20,21,22
 DFB $80+20,21,26,20,27,26,26,27,26,26,21,26,20,21,26
 DFB $80+20,2,6,20,8,6,26,8,6,26,2,6,20,2,6
 DFB $80+20,2,10,20,8,10,26,8,10,26,2,10,20,2,10
 DFB $80+20,2,22,20,8,22,26,8,22,26,2,22,20,2,22
 DFB $80+20,2,26,20,8,26,26,8,26,26,2,26,20,2,26

 DFB $FF
*-------------------------------------------------
Curve_CubeRev DA $1000 ;700 ; $1000
 da $15c0
 DA 2,2,3
 DA $F0F
 DA $606 ;404
 DA $FFFF ;0 ; Perspective On

 DFB $80+0,0,0,0,4,0
 DFB 4,4,0,4,0,0,0,0,0
 DFB $80+0,0,4,0,4,4
 DFB 4,4,4,4,0,4,0,0,4
 DFB $80+0,0,0,0,0,4
 DFB $80+0,4,0,0,4,4
 DFB $80+4,0,0,4,0,4
 DFB $80+4,4,0,4,4,4

 DFB $80+0,2,0
NPoint0 DFB 2,2,0
 DFB 4,2,0
NPoint1 DFB 4,2,2
 DFB 4,2,4
NPoint2 DFB 2,2,4
 DFB 0,2,4
Npoint3 DFB 0,2,2
 DFB 0,2,0

 DFB $80+2,0,0
Npoint0Bis DFB 2,2,0
 DFB 2,4,0
NPoint4 DFB 2,4,2
 DFB 2,4,4
NPoint2Bis DFB 2,2,4
 DFB 2,0,4
NPoint5 DFB 2,0,2
 DFB 2,0,0

 DFB $80,4,2
NPoint4Bis DFB 2,4,2
 DFB 4,4,2
NPoint1Bis DFB 4,2,2
 DFB 4,0,2
NPoint5Bis DFB 2,0,2
 DFB 0,0,2
NPoint3Bis DFB 0,2,2
 DFB 0,4,2
 HEX FF
*-------------------------------------------------
Curve_Acs DA $8E0 ;329 ; $800
 da $b33
 DA 7,2,2

 DA $bfb ;0f0
 DA $575 ;040/060
 DA $FFFF ;0 ; Perspective On

 DFB $80+4,0,0,4,4,0,4,4,4
 DFB 4,0,4,4,0,0
 DFB $80,2,2,4,0,0
 DFB $80,2,2,4,0,4
 DFB $80,2,2,4,4,0
 DFB $80,2,2,4,4,4

 DFB $80+0,8,0,0,8,4
 DFB 4,8,4,4,8,0,0,8,0
 DFB $80+0,8,0,0,6,0
 DFB 2,4,2,4,6,0,4,8,0
 DFB $80+0,8,4,0,6,4
 DFB 2,4,2,4,6,4,4,8,4
 DFB $80+0,6,0,0,6,4
 DFB 4,6,4,4,6,0,0,6,0

 DFB $80+2,9,0,2,9,4
 DFB 4,9,4,4,9,0,2,9,0
 DFB $80+2,9,0,2,12,0
 DFB 3,13,2,4,12,0,4,9,0
 DFB $80+2,9,4,2,12,4
 DFB 3,13,2,4,12,4,4,9,4
 DFB $80+2,12,4
 DFB 4,12,4,4,12,0,2,12,0

 DFB $80,13,0,0,13,4
 DFB 2,13,4,2,13,0,0,13,0

 DFB $80+2,13,4,2,12,4
 DFB $80+2,13,0,2,12,0

 DFB $80,13,0,0,10,0
 DFB 1,9,2,0,10,4,0,13,4
 DFB $82,13,0,2,10,0
 DFB 1,9,2,2,10,4,2,13,4
 DFB $82,10,4,0,10,4,0,10,0,2,10,0

 HEX FF
*-------------------------------------------------
 do 0
Curve_Damier DA $300 ; Was #1150
 DA 20,20,33
 DA $F0F
 DA $606 ;404
 DA 1 ; Perspective Off

 DFB $80,0,20,40,0,20
 DFB 40,40,20,0,40,20,0,0,20
 DFB $80+10,0,20
Point1 DFB 10,10,20
Point2 DFB 10,20,20
Point3 DFB 10,30,20,10,40,20
 DFB $80,30,20
Point3Bis DFB 10,30,20
Point6 DFB 20,30,20
Point9 DFB 30,30,20
 DFB 40,30,20
 DFB $80,20,20
Point2Bis DFB 10,20,20
Point5 DFB 20,20,20
Point8 DFB 30,20,20
 DFB 40,20,20
 DFB $80,10,20
Point1Bis DFB 10,10,20
Point4 DFB 20,10,20
Point7 DFB 30,10,20
 DFB 40,10,20
 DFB $80+20,0,20
Point4Bis DFB 20,10,20
Point5Bis DFB 20,20,20
Point6Bis DFB 20,30,20,20,40,20
 DFB $80+30,0,20
Point7Bis DFB 30,10,20
Point8Bis DFB 30,20,20
Point9Bis DFB 30,30,20,30,40,20
 HEX FF

Tbl_Point DA Point1+2
 DA Point2+2
 DA Point3+2
 DA Point4+2
 DA Point5+2
 DA Point6+2
 DA Point7+2
 DA Point8+2
 DA Point9+2

Tbl_PointBis DA Point1Bis+2
 DA Point2Bis+2
 DA Point3Bis+2
 DA Point4Bis+2
 DA Point5Bis+2
 DA Point6Bis+2
 DA Point7Bis+2
 DA Point8Bis+2
 DA Point9Bis+2
 fin
*-------------------------------------------------
Curve_AppleAlone DA $749 ; Etalon (990)
 da $a92
 DA 10 ; Max_X
 DA 8 ; Max_Y
 DA 1 ; Max_Z
 DA $0F0 ; Couleur
 DA $060 ; Anti-Aliasing 040
 DA $FFFF ;0 ; Perspective On

 DFB $80+4,10,0,3,10,0
 DFB 1,11,0,0,13,0
 DFB 1,13,0,3,12,0,4,10,0
 DFB 4,11,0,3,14,0,5,16,0,6,15,0
 DFB 8,14,0,11,14,0,12,16,0,14,15,0
 DFB 15,13,0,14,11,0,14,10,0,15,8,0
 DFB 15,7,0,13,5,0,11,4,0,6,4,0,4,5,0
 DFB 3,7,0,4,10,0

u = 2
 DFB $80+4,10,u,3,10,u
 DFB 1,11,u,0,13,u
 DFB 1,13,u,3,12,u,4,10,u
 DFB 4,11,u,3,14,u,5,16,u,6,15,u
 DFB 8,14,u,11,14,u,12,16,u,14,15,u
 DFB 15,13,u,14,11,u,14,10,u,15,8,u
 DFB 15,7,u,13,5,u,11,4,u,6,4,u,4,5,u
 DFB 3,7,u,4,10,u

 DFB $80+4,10,0,4,10,u
 DFB $80+3,10,0,3,10,u
 DFB $80+1,11,0,1,11,u
 DFB $80+0,13,0,0,13,u
 DFB $80+1,13,0,1,13,u
 DFB $80+3,12,0,3,12,u
 DFB $80+4,10,0,4,10,u
 DFB $80+4,11,0,4,11,u
 DFB $80+3,14,0,3,14,u
 DFB $80+5,16,0,5,16,u
 DFB $80+6,15,0,6,15,u
 DFB $80+8,14,0,8,14,u
 DFB $80+11,14,0,11,14,u
 DFB $80+12,16,0,12,16,u
 DFB $80+14,15,0,14,15,u
 DFB $80+15,13,0,15,13,u
 DFB $80+14,11,0,14,11,u
 DFB $80+14,10,0,14,10,u
 DFB $80+15,8,0,15,8,u
 DFB $80+15,7,0,15,7,u
 DFB $80+13,5,0,13,5,u
 DFB $80+11,4,0,11,4,u
 DFB $80+6,4,0,6,4,u
 DFB $80+4,5,0,4,5,u
 DFB $80+3,7,0,3,7,u
 DFB $80+4,10,0,4,10,u

 DFB %1111_1111
*-------------------------------------------------
Curve_Apple DA $383 ; Etalon (Was700) ($740)
 da $39f
 DA 10 ; Max_X
 DA 8 ; Max_Y
 DA 5 ; Max_Z
 DA $FF0 ; Couleur
 DA $660 ; Anti-Aliasing  440
 DA 0 ;1 ; Perspective Off

 DFB $80+4,10,0,3,10,0
 DFB 1,11,0,0,13,0
 DFB 1,13,0,3,12,0,4,10,0
 DFB 4,11,0,3,14,0,5,16,0,6,15,0
 DFB 8,14,0,11,14,0,12,16,0,14,15,0
 DFB 15,13,0,14,11,0,14,10,0,15,8,0
 DFB 15,7,0,13,5,0,11,4,0,6,4,0,4,5,0
 DFB 3,7,0,4,10,0
 DFB $80+9,1,4,9,3,10,9,5,4
 DFB $80+9,2,7,9,4,7
 DFB $80+9,6,1,9,6,7,9,8,7,9,9,6,9,9,5
 DFB 9,8,4,9,6,4
 DFB $80+9,10,1,9,10,7,9,12,7,9,13,6,9,13,5
 DFB 9,12,4,9,10,4
 DFB $80+9,14,4,9,16,4
 DFB $80+9,15,4,9,15,10,9,14,10
 DFB $80+9,20,5
 DFB 9,19,4,9,18,4,9,17,5,9,17,6,9,18,7
 DFB 9,19,7,9,20,6,9,17,6

 HEX FF
*-------------------------------------------------
Curve_Acs2 DA $32E ; Etalon - FIX (3460)
 da $32e
 DA 5 ; Max_X
 DA 2 ; Max_Y
 DA 5 ; Max_Z
 DA $F06 ; Couleur
 DA $603 ; Anti-Aliasing 403
 DA 0 ;1 ; Perspective Off

 DFB $80+2,1,0,4,4,0,0,2,0,4,0,0
 DFB $80+0,6,0,2,3,0,4,6,0,2,9,0,2,6,0,0,9,0
 DFB $80+2,5,5,2,1,0
 DFB $80+2,5,5,4,4,0
 DFB $80+2,5,5,0,2,0
 DFB $80+2,5,5,4,0,0
 DFB $80+2,5,5,0,6,0
 DFB $80+2,5,5,2,3,0
 DFB $80+2,5,5,4,6,0
 DFB $80+2,5,5,2,9,0
 DFB $80+2,5,5,2,6,0
 DFB $80+2,5,5,0,9,0

 HEX FF
*-------------------------------------------------
Curve_Rebound DA $390 ; Etalon ($300)
 da $400
 DA 20 ; Max_X
 DA 20 ; Max_Y
 DA 20 ; Max_Z
 DA $0FF ; Couleur
 DA $066 ; Anti-Aliasing 44
 DA 0 ;1 ; Perspective Off

r = 20
s = 40

 DFB $80+r,0,20,r,1,14
 DFB r,3,10,r,5,7,r,7,5,r,10,3,r,14,1,r,20,0
 DFB r,26,1,r,30,3,r,33,5,r,35,7,r,37,10,r,39,14,r,40,20
 DFB r,39,26,r,37,30,r,35,33,r,33,35,r,30,37,r,26,39
 DFB r,20,40,r,14,39,r,10,37,r,7,35,r,5,33,r,3,30,r,1,26
 DFB r,0,20
AltSol0 DFB r,20,20,r,40,20
 DFB $80+r,20,0
AltSol1 DFB r,20,20,r,20,40
AltObj0 DFB $80+s,24,24
AltObj1 DFB s,24,16
AltObj2 DFB s,16,16
AltObj3 DFB s,16,24
AltObj4 DFB s,24,24
AltBas0 DFB $80+s-4,20,20
AltObj5 DFB s,24,24
AltBas1 DFB $80+s-4,20,20
AltObj6 DFB s,24,16
AltBas2 DFB $80+s-4,20,20
AltObj7 DFB s,16,24
AltBas3 DFB $80+s-4,20,20
AltObj8 DFB s,16,16

 DFB $FF

Rebond_Obj DFB 0,0,1,3,3,6,9,11,14,17,19,17,14,11,9,6,3,3,1,0,0
Rebond_Sol DFB r,r,r,r,r,r,r-1,r-2,r-4,r-6,r-4,r-3,r-2,r-1,r,r+1
 DFB r+2,r+1,r,r,r,r,r
*-------------------------------------------------
Curve_France DA $364 ; Etalon $280 (556)
 da $45b
 DA 30 ; Max_X
 DA 30 ; Max_Y
 DA 12 ; Max_Z
 DA $Fa2 ; Couleur  fff
 DA $741 ; Anti-Aliasing 444/666
 DA 0 ;1 perspective off

i = 12

 DFB $80+59,30,i,58,27,i,53,27,i,52,26,i,51,24,i,50,22,i
 DFB 48,21,i,48,23,i,46,20,i,47,18,i,47,16,i,48,15,i
 DFB 49,15,i,49,12,i,48,13,i,46,14,i,42,14,i,42,8,i
 DFB 44,7,i,43,5,i,42,5,i,42,2,i,41,0,i,40,2,i,39,1,i
 DFB 39,2,i,38,0,i,36,2,i,37,3,i,36,6,i,35,7,i,35,8,i
 DFB 33,11,i,33,13,i,32,12,i,30,11,i,28,13,i,27,15,i
 DFB 24,16,i,18,19,i,21,16,i,16,16,i,8,14,i,7,13,i
 DFB 6,16,i,4,18,i,4,20,i,3,23,i,3,25,i,4,25,i,3,30,i
 DFB 1,32,i,1,34,i,2,38,i,3,36,i,8,38,i,8,39,i,10,41,i
 DFB 8,44,i,8,48,i,7,50,i,8,52,i,9,54,i,14,58,i,15,55,i
 DFB 17,54,i,20,54,i,21,52,i,22,54,i,24,54,i,26,52,i
 DFB 27,53,i,30,52,i,29,50,i,28,50,i,28,49,i,29,49,i
 DFB 32,50,i,36,52,i,38,54,i,42,54,i,48,56,i,48,50,i
 DFB 50,48,i,50,44,i,52,41,i,54,41,i,52,39,i,54,38,i
 DFB 55,36,i,56,34,i,57,34,i,57,33,i,59,30,i

 DFB $80+34,44,i,34,46,i+2,34,45,i+2,34,45,i+6
 DFB 34,43,i+6,34,43,i+2,34,42,i+2,34,44,i

 DFB $FF
*-------------------------------------------------
Curve_World DA $FA ; Etalon $296 ($280)
 da $154
 DA 50 ; Max_X
 DA 50 ; Max_Y
 DA 50 ; Max_Z
 DA $00F ; Couleur
 DA $006 ; Anti-Aliasing 004
 DA $FFFF ;0(on) ; 1(off)

 HEX B3130B370E1036081831071820033031
 HEX 00363E03404D0A3E510E415211455112
 HEX 4953144957174751184F4B124F4A0F4C
 HEX 4610513512582E185D301D5F341F603A
 HEX 195D3A2160332362332863362562382D
 HEX 633E306347315F412F62402B6249265D
 HEX 562A545B234A5725515B21495310414E
 HEX 0A3C530C324606263D100F33130BB02C
 HEX 642F2B632D25622A1E5F2728622F3064
 HEX 303164302C648B3D4F0A2B4F0D295211
 HEX 1F521312490C133A03243A012A2A0730
 HEX 18063A1B06482A0445320A4F3A0D5040
 HEX 084A400744450A3E4E09494115544910
 HEX 4E4A10484F134F4C1D594923613C2C5E
 HEX 49315F493660453C623A4161363F623A
 HEX 3B614141603E435E433E5E4748574C42
 HEX 515547515242495C3B475F3A43603B3E
 HEX 6244435E3E3E613B3963373A632E3B63
 HEX 303764293A63253B6223366224336223
 HEX 3062202D601C2C5F1D2E5F1A2E5E1B31
 HEX 5F1F31602133611D325F1B335F18315D
 HEX 192B5D172359152458172058131E5410
 HEX 24541128570D30540F3055122C580F32
 HEX 550C34520F3455123958113C570E3654
 HEX 0E3D520B3D4F8A491F0B4E240A4F2A08
 HEX 4A260A491FC5485A43465D3E455F4548
 HEX 5AC84F544D4B544949584B4B55484F54
 HEX C1623041623239633A36633A3C633241
 HEX 6230CC5D3250593A4B5C3C475F364C5D
 HEX 32E2402C6143305E4B345952365C4D32
 HEX 5F482C62402CCF400C55320F58341250
 HEX 410D4F400CBF5A164E52184F4D135347
 HEX 135943185F45265E482A5A4C245A4F2A
 HEX 56532A545526465D233F5A16B2320032
 HEX 3A01384002364705203F05212904292A
 HEX 012E25022D18073121033922033C2C01
 HEX 32320098245A18275C1E285F1B265D18
 HEX 245AFF
*-------------------------------------------------
 do 0
Curve_Tower DA $280 ;140 ; Etalon $280
 DA 124 ; Max_X
 DA 52 ; Max_Y
 DA 52 ; Max_Z
 DA $0FF ; Couleur
 DA $066 ; Anti-Aliasing  044
 DA 0 ;1(off)

 HEX 80000010000010001000001000000018
 HEX 30189000002830189000102830288000
 HEX 10183028D80000680000680010580010
 HEX 580000403018E80000503018E8001050
 HEX 3028D80010403028E800685800685800
 HEX 58680058680068503050D80068403050
 HEX D80058403040E8005850304080006800
 HEX 00581000581000680000681830508000
 HEX 58183040900058283040900068283050
 HEX 90201058201058205810205810201098
 HEX 1008241C0D2C2010BC2010441C0D5010
 HEX 08E01018591C2458202CD8203C591C44
 HEX 601050D01060441C593C2058AC205824
 HEX 1C591810608810500D1C4410203C9020
 HEX 2C0D1C24081018983018503018503050
 HEX 183050183018983028503028C0301840
 HEX 3050D03040183040A830502830189830
 HEX 18183418D03018503418D03050503450
 HEX 98305018345098341850341850345018
 HEX 3450183418983018246024A830183060
 HEX 24A83028306030983028246030D03018
 HEX 446024D03028446030C03028386030C0
 HEX 3018386024D03050446044C030503860
 HEX 44C03040386038D03040446038983050
 HEX 246044983040246038A83040306038A8
 HEX 3050306044A158214558214558452158
 HEX 45215821A46024446024446044246044
 HEX 246024B06024306044B86024386044A4
 HEX 6030446030A46038446038A460242464
 HEX 24C46024446424C46044446444A46044
 HEX 246444A4642444642444644424644424
 HEX 6424A460242CA02CC460243CA02CC460
 HEX 443CA03CA460442CA03CB06024349029
 HEX B86024349029C460303D9034C460383D
 HEX 9034B8604434903DB0604434903DA460
 HEX 38299034A46030299034ACA02C3CA02C
 HEX 3CA03C2CA03C2CA02C30E030BCA02C38
 HEX E030BCA03C38E038ACA03C30E038B490
 HEX 2934E030BD903438E034B4903D34E038
 HEX A9903430E034B0E02D30E039B8E02D38
 HEX E039ADE03039E030ADE03839E038ADE0
 HEX 2D39E02D39E0392DE0392DE02D2DE42D
 HEX B9E02D39E42DB9E03939E439ADE0392D
 HEX E439ADE42D39E42D39E4392DE4392DE4
 HEX 2DB0E43030E830B8E43038E830B8E438
 HEX 38E838B0E43830E838B0E83034EC34B8
 HEX E83034EC34B8E83834EC34B0E83834EC
 HEX 3434F834FF
 fin
*-------------------------------------------------
Curve_Ship DA $7EE ; Etalon $280 (640)
 da $a98
 DA 6 ; Max_X
 DA 8 ; Max_Y
 DA 4 ; Max_Z
 DA $7ae ; Couleur   f00
 DA $347 ; Anti-Aliasing  400/600
 DA $FFFF ;0(on)

 DFB $80+16,6,4,4,6,8,4,12,4,16,6,4,4,6,0,4,0,4
 DFB 16,6,4
 DFB $80+4,12,4,4,6,0
 DFB $80+4,0,4,4,6,8
 DFB $80+0,6,6,0,9,4,0,6,2,0,3,4,0,6,6
 DFB $80+0,9,4,4,12,4
 DFB $80+0,6,2,4,6,0
 DFB $80+0,3,4,4,0,4
 DFB $80+0,6,6,4,6,8
 DFB $FF
*-------------------------------------------------
Curve_Pyramid DA $1000 ; $1000
 da $1000
 DA 2,2,4
 DA $0bf2
 DA $0460
 DA $FFFF ; Perspective On

out1 = 5

 dfb $80+0,0,0
 dfb 4,0,0
 dfb 4,4,0
 dfb 0,4,0
 dfb 0,0,0
 dfb 2,2,out1
 dfb 0,4,0
 dfb $80+4,0,0,2,2,out1,4,4,0

 HEX FF
*-------------------------------------------------
Curve_Diamond DA $C00 ; $1000
 da $c00
 DA 2,2,6
 DA $04fa
 DA $0174
 DA $FFFF ; Perspective On

in = 0
middle = 4
out = 8

 dfb $80+0,0,middle
 dfb 4,0,middle
 dfb 4,4,middle
 dfb 0,4,middle
 dfb 0,0,middle
 dfb 2,2,out
 dfb 0,4,middle
 dfb $80+4,0,middle,2,2,out,4,4,middle
 dfb $80+0,0,middle,2,2,in,0,4,middle
 dfb $80+4,0,middle,2,2,in,4,4,middle

 HEX FF
*-------------------------------------------------

* sav curves.bin
