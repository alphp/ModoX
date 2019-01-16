;─────────────────────────────────────────────────────────────────────────────
; ╔════════════════════════════════════════════════════════════════════════╗
; ║                    Libreria para gráficos en Modo X                    ║
; ║                  para QB y ASM (Mediante MACROS) por:                  ║
; ║                    Txampi Herrero, (c) Febrero 1996                    ║
; ╚════════════════════════════════════════════════════════════════════════╝
;─────────────────────────────────────────────────────────────────────────────
;   Constantes utilizadas en las funciones:

VGA     EQU 0A000h  ; VGA, Segmento de la memoria de video
ATC     EQU 3C0h    ; ATC, Registro índice/escritura
ATC1    EQU 3C1h    ; ATC, Registro de lectura
TSInd   EQU 3C4h    ; TS, Registro índice
TSDat   EQU 3C5h    ; TS, Registro de datos
DLP     EQU 3C7h    ; DAC, Dirección de lectura del pixel
DEP     EQU 3C8h    ; DAC, Dirección de escritura del pixel
VCP     EQU 3C9h    ; DAC, Valor del color del pixel
GDCInd  EQU 3CEh    ; GDC, Registro índice
GDCDat  EQU 3CFh    ; GDC, Registro de datos
CRTCInd EQU 3D4h    ; CRTC, Registro índice
CRTCDat EQU 3D5h    ; CRTC, Registro de datos
ISR1    EQU 3DAh    ; ISR1, Input Status Register 1
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Estructura de un Color RGB:

RGB     STRUC
		R   DW  ?
		G   DW  ?
		B   DW  ?
RGB     ENDS
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Estructura de la Cabecera PCX:

CabPCX  STRUC
	Formato DB  ?
	InfVer  DB  ?
	RLE     DB  ?
	BitsPix DB  ?
	Xmn     DW  ?
	Ymn     DW  ?
	Xmx     DW  ?
	Ymx     DW  ?
	DpiX    DW  ?
	DpiY    DW  ?
	MapCol  RGB 16 DUP(?)
	Reserv  DB  ?
	NPlanos DB  ?
	ByteLin DW  ?
	TipoPal DW  ?
	TamX    DW  ?
	TamY    DW  ?
	Relleno DB  54 DUP(?)
CabPCX  ENDS
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
Codigo      SEGMENT
			ASSUME  cs:Codigo
			PUBLIC  ModoX       ;DECLARE SUB ModoX ()
			PUBLIC  ModoTxt     ;DECLARE SUB ModoTxt ()
			PUBLIC  PonLongLin  ;DECLARE SUB PonLongLin (Long%)
			PUBLIC  LeeLongLin  ;DECLARE FUNCTION LeeLongLin% ()
			PUBLIC  PonPixel    ;DECLARE SUB PonPixel (X%, Y%, Col%)
			PUBLIC  LeePixel    ;DECLARE FUNCTION LeePixel% (X%, Y%)
			PUBLIC  ClsX        ;DECLARE SUB ClsX ()
			PUBLIC  Modo200Lin  ;DECLARE SUB Modo200Lin ()
			PUBLIC  Modo400Lin  ;DECLARE SUB Modo400Lin ()
			PUBLIC  LeeColor    ;DECLARE SUB LeeColor (n%, Col AS RGB)
			PUBLIC  PonColor    ;DECLARE SUB PonColor (n%, Col AS RGB)
			PUBLIC  LeePaleta   ;DECLARE SUB LeePaleta (Pal() AS RGB)
			PUBLIC  PonPaleta   ;DECLARE SUB PonPaleta (Pal() AS RGB)
			PUBLIC  ScrollGrf   ;DECLARE SUB ScrollGrf (X%, Y%)
			PUBLIC  ScrollTxt   ;DECLARE SUB ScrollTxt (X%, Y%)
			PUBLIC  Linea       ;DECLARE SUB Linea (X1%, Y1%, X2%, Y2%, Col%)
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Activar Modo X

;DECLARE SUB ModoX ()
ModoX       PROC    FAR
			push    es

			; Desconectamos la pantalla
			mov     dx,TSInd
			mov     al,01h
			out     dx,al
			inc     dx
			in      al,dx
			or      al,20h
			out     dx,al

			; Activar Modo 13h
			mov     ax,0013h
			int     10h

			; Desactivar Modo Chain 4 y Modo Par/Impar
			dec     dx
			mov     al,04h
			out     dx,al
			inc     dx
			in      al,dx
			and     al,0F7h
			or      al,04h
			out     dx,al

			;  Activamos los cuatro planos para la escritura
			dec     dx
			mov     ax,0F02h
			out     dx,ax

			;  Borramos la memoria de video
			mov     dx,VGA
			mov     es,dx
			mov     cx,-1
			xor     ax,ax
			rep     stosw

			; Desactivar Modo Doubleword
			mov     dx,CRTCInd
			mov     al,14h
			out     dx,al
			inc     dx
			in      al,dx
			and     al,0BFh
			out     dx,al

			; Activar Modo Byte
			dec     dx
			mov     al,17h
			out     dx,al
			inc     dx
			in      al,dx
			or      al,40h
			out     dx,al

			; Conectamos la pantalla
			mov     dx,TSInd
			mov     al,01h
			out     dx,al
			inc     dx
			in      al,dx
			and     al,0DFh
			out     dx,al

			pop     es
			ret
ModoX       ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Activar Modo Texto:

;DECLARE SUB ModoTxt ()
ModoTXT     PROC    FAR
			; Activar Modo Texto
			mov     ax,0003h
			int     10h
			ret
ModoTXT     ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Definir longitud de línea:

;DECLARE SUB PonLongLin (Long%)
PonLongLin  PROC    FAR
			push    bp
			mov     bp,sp

			mov     dx,CRTCInd
			mov     si,[bp + 6]
			mov     ax,[si]
			shr     ax,3
			mov     ah,al
			mov     al,13h
			out     dx,ax

			pop     bp
			ret     2
PonLongLin  ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Leer longitud de línea:

;DECLARE FUNCTION LeeLongLin% ()
LeeLongLin  PROC    FAR
			mov     dx,CRTCInd
			mov     ax,0013h
			out     dx,al
			inc     dx
			in      al,dx
			shl     ax,3
			ret
LeeLongLin  ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Escribir un Pixel en Modo X:

;DECLARE SUB PonPixel (X%, Y%, Col%)
PonPixel    PROC    FAR
			push    bp
			mov     bp,sp
			push    es

			mov     dx,TSInd
			mov     al,02h
			mov     si,[bp + 10]
			mov     cx,[si]
			and     cx,03h
			mov     ah,01h
			shl     ah,cl
			out     dx,ax

			mov     di,[si]
			shr     di,2
			call    LeeLongLin
			shr     ax,2
			mov     si,[bp + 8]
			mul     WORD PTR [si]
			add     di,ax

			mov     si,[bp + 6]
			mov     ax,[si]
			mov     dx,VGA
			mov     es,dx
			stosb

			pop     es
			pop     bp
			ret     6
PonPixel    ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;   Leer un Pixel en Modo X:

;DECLARE FUNCTION LeePixel% (X%, Y%)
LeePixel    PROC    FAR
			push    bp
			mov     bp,sp
			push    ds

			mov     dx,GDCInd
			mov     al,02h
			mov     si,[bp + 8]
			mov     cx,[si]
			and     cx,03h
			shl     ah,cl
			out     dx,ax

			mov     di,[si]
			shr     di,2
			call    LeeLongLin
			shr     ax,2
			mov     si,[bp + 6]
			mul     WORD PTR [si]
			add     di,ax
			mov     si,di

			mov     dx,VGA
			mov     ds,dx
			lodsb
			xor     ah,ah

			pop     ds
			pop     bp
			ret     4
LeePixel    ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;   Borra la pantalla en Modo X:

;DECLARE SUB ClsX ()
ClsX        PROC    FAR
			push    es

			;  Activamos los cuatro planos para la escritura
			mov     dx,TSInd
			mov     ax,0F02h
			out     dx,ax

			;  Borramos la memoria de video
			mov     dx,VGA
			mov     es,dx
			mov     cx,-1
			xor     ax,ax
			rep     stosw

			pop     es
			ret
ClsX        ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Establecer 200 líneas:

;DECLARE SUB Modo200Lin ()
Modo200Lin  PROC    FAR
			mov     dx,CRTCInd
			mov     al,09h
			out     dx,al
			inc     dx
			in      al,dx
			or      al,80h
			out     dx,al
			ret
Modo200Lin  ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Establecer 400 líneas:

;DECLARE SUB Modo400Lin ()
Modo400Lin  PROC    FAR
			mov     dx,CRTCInd
			mov     al,09h
			out     dx,al
			inc     dx
			in      al,dx
			and     al,70h
			out     dx,al
			ret
Modo400Lin  ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Leer un color:

;DECLARE SUB LeeColor (n%, Col AS RGB)
LeeColor    PROC    FAR
			push    bp
			mov     bp,sp

			mov     si,[bp + 8]
			mov     dx,DLP
			mov     al,[si]
			out     dx,al
			mov     dx,VCP
			mov     si,[bp + 6]
			xor     ax,ax
			in      al,dx
			mov     [si].R,ax
			in      al,dx
			mov     [si].G,ax
			in      al,dx
			mov     [si].B,ax

			pop     bp
			ret     4
LeeColor    ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Escribir un color:

;DECLARE SUB PonColor (n%, Col AS RGB)
PonColor    PROC    FAR
			push    bp
			mov     bp,sp

			mov     si,[bp + 8]
			mov     dx,DEP
			mov     al,[si]
			out     dx,al
			mov     dx,VCP
			mov     si,[bp + 6]
			mov     ax,[si].R
			out     dx,al
			mov     ax,[si].G
			out     dx,al
			mov     ax,[si].B
			out     dx,al

			pop     bp
			ret     4
PonColor    ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Leer la paleta:

;DECLARE SUB LeePaleta (Pal() AS RGB)
LeePaleta   PROC    FAR
			push    bp
			mov     bp,sp
			push    ds

			mov     di,[bp + 6]
			mov     si,[di]
			mov     ax,[di + 2]
			mov     ds,ax
			mov     dx,DLP
			xor     al,al
			out     dx,al

			xor     ax,ax
			xor     cl,cl
			mov     dx,VCP
LazoLP:     in      al,dx
			mov     [si].R,ax
			in      al,dx
			mov     [si].G,ax
			in      al,dx
			mov     [si].B,ax
			add     si,6
			dec     cl
			jnz     LazoLP
			pop     ds
			pop     bp
			ret     2
LeePaleta   ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Escribir la paleta:

;DECLARE SUB PonPaleta (Pal() AS RGB)
PonPaleta   PROC    FAR
			push    bp
			mov     bp,sp
			push    ds

			mov     di,[bp + 6]
			mov     si,[di]
			mov     ax,[di + 2]
			mov     ds,ax
			mov     dx,DEP
			xor     al,al
			out     dx,al

			xor     ax,ax
			xor     cl,cl
			mov     dx,VCP
LazoPP:     mov     ax,[si].R
			out     dx,al
			mov     ax,[si].G
			out     dx,al
			mov     ax,[si].B
			out     dx,al
			add     si,6
			dec     cl
			jnz     LazoPP
			pop     ds
			pop     bp
			ret     2
PonPaleta   ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Scroll Gráfico en Modo X:

;DECLARE SUB ScrollGrf (X%, Y%)
ScrollGrf   PROC    FAR
			push    bp
			mov     bp,sp

			mov     si,[bp + 8]
			mov     bx,[si]
			shr     bx,2
			call    LeeLongLin
			shr     ax,2
			mov     si,[bp + 6]
			mul     WORD PTR [si]
			add     bx,ax

			mov     dx,ISR1
WaitSG1:    in      al,dx
			test    al,08h
			jnz     WaitSG1

			mov     dx,CRTCInd
			mov     al,0Ch
			mov     ah,bh
			out     dx,ax
			inc     al
			mov     ah,bl
			out     dx,ax

			mov     dx,ISR1
WaitSG2:    in      al,dx
			test    al,08h
			jz      WaitSG2

			mov     dx,ATC
			mov     al,13h OR 20h
			out     dx,al
			mov     si,[bp + 8]
			mov     ax,[si]
			and     al,03h
			shl     al,1
			or      al,20h
			out     dx,al

			pop     bp
			ret     4
ScrollGrf   ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Scroll en Modo Texto:

;DECLARE SUB ScrollTxt (X%, Y%)
ScrollTxt   PROC    FAR
			push    bp
			mov     bp,sp

			mov     si,[bp + 6]
			mov     bx,[si]
			shr     bx,4
			call    LeeLongLin
			shr     ax,2
			mul     bx
			mov     bx,ax
			mov     si,[bp + 8]
			mov     ax,[si]
			mov     cx,9
			div     cx
			add     bx,ax

			mov     dx,ISR1
WaitST1:    in      al,dx
			test    al,08h
			jnz     WaitST1

			mov     dx,CRTCInd
			mov     al,0Ch
			mov     ah,bh
			out     dx,ax
			inc     al
			mov     ah,bl
			out     dx,ax

			mov     dx,ISR1
WaitST2:    in      al,dx
			test    al,08h
			jz      WaitST2

			mov     dx,CRTCInd
			mov     si,[bp + 6]
			mov     ah,[si]
			and     ah,0Fh
			mov     al,08h
			out     dx,ax

			mov     dx,ATC
			mov     al,13h OR 20h
			out     dx,al
			mov     si,[bp + 8]
			mov     ax,[si]
			div     cl
			dec     ah
			mov     al,ah
			or      al,20h
			out     dx,al

			pop     bp
			ret     4
ScrollTxt   ENDP
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;   Línea en Modo X, se dibuja mediante el algoritmo de Bresenham:

x       DW  ?
y       DW  ?
Vx      DW  ?
Vy      DW  ?
dxx     DW  ?
dyy     DW  ?
dxd     DW  ?
dyd     DW  ?
dxr     DW  ?
dyr     DW  ?
E       DW  ?
Er      DW  ?
Ed      DW  ?
Col     DW  ?
LongLin DW  ?

;DECLARE SUB Linea (X1%, Y1%, X2%, Y2%, Col%)
Linea       PROC    FAR
			push    bp
			mov     bp,sp
			push    es

			mov     dx,VGA
			mov     es,dx

			call    LeeLongLin
			shr     ax,2
			mov     cs:[LongLin],ax

			mov     cs:[dxx],1
			mov     cs:[dyy],1

			mov     si,[bp + 6]
			mov     ax,[si]
			mov     cs:[Col],ax
			mov     si,[bp + 10]
			mov     ax,[si]
			mov     si,[bp + 14]
			sub     ax,[si]
			mov     cs:[Vx],ax
			cmp     ax,0
			jge     Lin1
			neg     cs:[dxx]
			neg     cs:[Vx]
Lin1:       mov     ax,cs:[dxx]
			mov     cs:[dxd],ax

			mov     si,[bp + 8]
			mov     ax,[si]
			mov     si,[bp + 12]
			sub     ax,[si]
			mov     cs:[Vy],ax
			cmp     ax,0
			jge     Lin2
			neg     cs:[dyy]
			neg     cs:[Vy]
Lin2:       mov     ax,cs:[dyy]
			mov     cs:[dyd],ax

			mov     ax,cs:[Vx]
			cmp     ax,cs:[Vy]
			jl      Lin3
			mov     cs:[dyy],0
			jmp     Lin4
Lin3:       mov     bx,cs:[Vy]
			mov     cs:[Vx],bx
			mov     cs:[Vy],ax
			mov     cs:[dxx],0

Lin4:       mov     ax,cs:[dxx]
			mov     cs:[dxr],ax
			mov     ax,cs:[dyy]
			mov     cs:[dyr],ax

			mov     si,[bp + 14]
			mov     ax,[si]
			mov     cs:[x],ax
			mov     si,[bp + 12]
			mov     ax,[si]
			mov     cs:[y],ax

			mov     ax,cs:[Vy]
			shl     ax,1
			mov     cs:[Er],ax
			sub     ax,cs:[Vx]
			mov     cs:[E],ax
			sub     ax,cs:[Vx]
			mov     cs:[Ed],ax

			mov     cx,cs:[Vx]
			inc     cx
LinFor:     push    cx
			mov     dx,TSInd
			mov     al,02h
			mov     cx,cs:[x]
			and     cx,03h
			mov     ah,01h
			shl     ah,cl
			out     dx,ax

			mov     di,cs:[x]
			shr     di,2
			mov     ax,cs:[LongLin]
			mul     WORD PTR cs:[y]
			add     di,ax

			mov     ax,cs:[Col]
			stosb
			pop     cx

			cmp     cs:[E],0
			jl      Lin5
			mov     ax,cs:[dxd]
			add     cs:[x],ax
			mov     ax,cs:[dyd]
			add     cs:[y],ax
			mov     ax,cs:[Ed]
			add     cs:[E],ax
			jmp     Lin6
Lin5:       mov     ax,cs:[dxr]
			add     cs:[x],ax
			mov     ax,cs:[dyr]
			add     cs:[y],ax
			mov     ax,cs:[Er]
			add     cs:[E],ax
Lin6:       dec     cx
			jz      Lin7
			jmp     LinFor

Lin7:       pop     es
			pop     bp
			ret     10
Linea       ENDP
;─────────────────────────────────────────────────────────────────────────────
Codigo      ENDS
			END
