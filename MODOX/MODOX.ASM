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
			PUBLIC  ModoX           ;DECLARE SUB ModoX ()
			PUBLIC  ModoTxt         ;DECLARE SUB ModoTxt ()
			PUBLIC  PonLongLin      ;DECLARE SUB PonLongLin (Long%)
			PUBLIC  LeeLongLin      ;DECLARE FUNCTION LeeLongLin% ()
			PUBLIC  PonPixel        ;DECLARE SUB PonPixel (X%, Y%, Col%)
			PUBLIC  LeePixel        ;DECLARE FUNCTION LeePixel% (X%, Y%)
			PUBLIC  ClsX            ;DECLARE SUB ClsX ()
			PUBLIC  Modo200Lin      ;DECLARE SUB Modo200Lin ()
			PUBLIC  Modo400Lin      ;DECLARE SUB Modo400Lin ()
			PUBLIC  LeeColor        ;DECLARE SUB LeeColor (n%, Col AS RGB)
			PUBLIC  PonColor        ;DECLARE SUB PonColor (n%, Col AS RGB)
			PUBLIC  LeePaleta       ;DECLARE SUB LeePaleta (Pal() AS RGB)
			PUBLIC  PonPaleta       ;DECLARE SUB PonPaleta (Pal() AS RGB)
			PUBLIC  ScrollGrf       ;DECLARE SUB ScrollGrf (X%, Y%)
			PUBLIC  ScrollTxt       ;DECLARE SUB ScrollTxt (X%, Y%)
;─────────────────────────────────────────────────────────────────────────────

;─────────────────────────────────────────────────────────────────────────────
;  Activar Modo X

;DECLARE SUB ModoX ()
ModoX       PROC    FAR
			; Activar Modo 13h
			mov     ax,0013h
			int     10h

			; Desactivar Modo Chain 4 y Modo Par/Impar
			mov     dx,TSInd
			mov     al,04h
			out     dx,al
			inc     dx
			in      al,dx
			and     al,0F7h
			or      al,04h
			out     dx,al

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
			mul     ax,[si]
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
;  Leer un Pixel en Modo X:

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
			mul     ax,[si]
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
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;Borra la pantalla en Modo X:
;  Se implementa en ensamblador para aumentar la velocidad del código.

void ClsX (void)
{
	unsigned int n;

	;  Activamos los cuatro planos para la escritura
	mov     dx,TSInd
	mov     ax,0F02h
	out     dx,ax

	;  Borramos la memoria de video
	mov     dx,VGA
	mov     es,dx
	for (n = 0; n < 0xFFFF; n++)
	{
		pokeb(VGA, n, 0);
	}
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Establecer 200 líneas:

void Modo200Lin (void)
{
	mov     dx,CRTCInd
	mov     al,09h
	out     dx,al
	inc     dx
	in      al,dx
	or      al,80h
	out     dx,al
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) | 0x80);
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Establecer 400 líneas:

void Modo400Lin (void)
{
	mov     dx,CRTCInd
	mov     al,09h
	out     dx,al
	inc     dx
	in      al,dx
	and     al,70h
	out     dx,al
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) & 0x70);
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Leer un color:

void LeeColor (unsigned char n, struct RGB *Color)
{
	outportb (DLP, n);          ; Leemos el color número n
	Color->R = inportb (VCP);   ; Primero el Rojo (R)
	Color->G = inportb (VCP);   ; Segundo el Verde (G)
	Color->B = inportb (VCP);   ; Tercero el Azul (B)
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Escribir un color:

void PonColor (unsigned char n, struct RGB Color)
{
	outportb (DEP, n);          ; Escribimos el color número n
	outportb (VCP, Color.R);    ; Primero el Rojo (R)
	outportb (VCP, Color.G);    ; Segundo el Verde (G)
	outportb (VCP, Color.B);    ; Tercero el Azul (B)
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Leer la paleta:

void LeePaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DLP, 0);              ; Comenzamos por el color 0
	for (n = 0; n < 256; n++)       ; Leemos 256 colores
	{
		Pal[n].R = inportb (VCP);   ; Primero el Rojo (R)
		Pal[n].G = inportb (VCP);   ; Segundo el Verde (G)
		Pal[n].B = inportb (VCP);   ; Tercero el Azul (B)
	}
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Escribir la paleta:

void PonPaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DEP, 0);              ; Comenzamos por el color 0
	for (n = 0; n < 256; n++)       ; Escribimos 256 colores
	{
		outportb (VCP, Pal[n].R);   ; Primero el Rojo
		outportb (VCP, Pal[n].G);   ; Segundo el Verde
		outportb (VCP, Pal[n].B);   ; Tercero el Azul
	}
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Scroll Gráfico en Modo X:

void ScrollGrf (unsigned int x, unsigned int y)
{
	union Reg n;

	; Calculamos el desplazamiento vertical en bytes
	n.w = 160 * y + (x / 4);

	; Realizamos el Scroll vertical
	outportb (CRTCInd, 0x0C);   ; Dir. de inicio de línea (parte alta)
	outportb (CRTCDat, n.b.h);
	outportb (CRTCInd, 0x0D);   ; Dir. de inicio de línea (parte baja)
	outportb (CRTCDat, n.b.l);

	; Realizamos el Scroll horizontal                  */
	outportb (ATC, 0x13 | 0x20); ; Panning de píxelsles horizontal
	outportb (ATC, (2 * (x % 4)) | 0x20);
};
;────────────────────────────────────────────────────────────────────────────

;────────────────────────────────────────────────────────────────────────────
;  Scroll en Modo Texto:

void ScrollTxt (unsigned char x, unsigned char y)
{
	union Reg n;

	; Calculamos el desplazamiento vertical en bytes
	n.w = 160 * (y / 16) + (x / 9);
/*
	asm mov dx,03DAh
wait2:
	asm in al,dx
	asm test al,08h
	asm jnz wait2
*/
	; Realizamos el Scroll vertical
	outportb (CRTCInd, 0x0C);   ; Dir. de inicio de línea (parte alta)
	outportb (CRTCDat, n.b.h);
	outportb (CRTCInd, 0x0D);   ; Dir. de inicio de línea (parte baja)
	outportb (CRTCDat, n.b.l);
/*
	asm mov dx,03DAh
wait1:
	asm in al,dx
	asm test al,08h
	asm jz wait1
*/
	outportb (CRTCInd, 0x08);
	outportb (CRTCDat, y % 16);

	outportb (ATC, 0x13 | 0x20);
	outportb (ATC, ((x - 1) % 9) | 0x20);
};
;────────────────────────────────────────────────────────────────────────────

void Linea (int x1, int y1, int x2, int y2, unsigned char Color)
{
	int x, y, Vx, Vy;
	int dx = 1, dy = 1;
	int dxd, dyd, dxr, dyr;
	int i, E, Er, Ed;

	Vx = x2 - x1;
	if (Vx < 0)
	{
		dx = -dx;
		Vx = -Vx;
	}
	dxd = dx;

	Vy = y2 - y1;
	if (Vy < 0)
	{
		dy = -dy;
		Vy = -Vy;
	}
	dyd = dy;

	if (Vx >= Vy)
	{
		dy = 0;
	}
	else
	{
		dx = Vx; Vx = Vy; Vy = dx;
		dx = 0;
	}

	dxr = dx;
	dyr = dy;

	x = x1;
	y = y1;
	Er = 2 * Vy;
	Ed = 2 * Vy - 2 * Vx;
	E = 2 * Vy - Vx;

	for (i = 1; i < Vx + 1; i++)
	{
		PonPixel (x, y, Color);
		if (E >= 0)
		{
			x = x + dxd;
			y = y + dyd;
			E = E + Ed;
		}
		else
		{
			x = x + dxr;
			y = y + dyr;
			E = E + Er;
		}
	}
};

 rad 3.141592 / 180
void main (void)
{
	int x, y, a;
	ModoX ();
	PonLongLin (640);
	ClsX ();

	for (x = 0; x < 256; x++)       ; Escribimos 256 colores
	{
		PonPixel (x, 0, x);
		PonPixel (x, 1, x);
	}

	for (a = 0; a < 180; a = a + 2)
	{
		x = 72 * cos(a * rad); y = 60 * sin(a * rad);
		Linea (x + 160, 100 - y, 160-x, y + 100, a / 5 + 32);
	}

	getch();
	ModoTxt();
};

;────────────────────────────────────────────────────────────────────────────
;  Cálculo de los incrementos y decrementos de los valores del Scroll:
/*
unsigned int x, y;
	Para subir:
		y = 200 - ((200 + 1 - y) MOD (200 + 1))

	Para bajar:
		y = (y + 1) MOD (200 + 1)

	Para la derecha:
		x = (x + 1) MOD (320 + 1)

	Para la izquierda:
		x = 320 - ((320 + 1 - x) MOD (320 + 1))
*/
;────────────────────────────────────────────────────────────────────────────
