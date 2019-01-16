//────────────────────────────────────────────────────────────────────────────
/*╔════════════════════════════════════════════════════════════════════════╗
  ║                 Rutinas para gráficos en Modo X                        ║
  ║                Traducciones del Pascal a C++ por:                      ║
  ║                 Txampi Herrero, (c) Febrero 1996                       ║
  ╚════════════════════════════════════════════════════════════════════════╝*/

#include "dos.h"
#include "math.h"
#include "conio.h"

//────────────────────────────────────────────────────────────────────────────
//  Constantes utilizadas en las funciones:

#define VGA     0xA000  // VGA, Segmento de la memoria de video (Gráfica)
#define TXT     0xB800  // VGA, Segmento de la memoria de video (Texto)
#define ATC     0x3C0   // ATC, Registro índice/escritura
#define ATC1    0x3C1   // ATC, Registro de lectura
#define TSInd   0x3C4   // TS, Registro índice
#define TSDat   0x3C5   // TS, Registro de datos
#define DLP     0x3C7   // DAC, Dirección de lectura del pixel
#define DEP     0x3C8   // DAC, Dirección de escritura del pixel
#define VCP     0x3C9   // DAC, Valor del color del pixel
#define GDCInd  0x3CE   // GDC, Registro índice
#define GDCDat  0x3CF   // GDC, Registro de datos
#define CRTCInd 0x3D4   // CRTC, Registro índice
#define CRTCDat 0x3D5   // CRTC, Registro de datos
#define ISR1    0x3DA   // ISR1, Input Status Register 1

#define CIERTO  -1
#define FALSO   0
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Estructura de un Color RGB:

struct RGB
{
	unsigned char R, G, B;
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Estructura de un registro word con acceso directo al byte alto y bajo:

struct BReg
{
	unsigned char l, h;
};

union Reg
{
	unsigned int w;
	struct BReg b;
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Estructura de la Cabecera PCX:

struct CabPCX
{
	unsigned char Formato;
	unsigned char InfVer;
	unsigned char RLE;
	unsigned char BitsPix;
	unsigned int Xmn;
	unsigned int Ymn;
	unsigned int Xmx;
	unsigned int Ymx;
	unsigned int DpiX;
	unsigned int DpiY;
	struct RGB MapCol[16];
	unsigned char Reserv;
	unsigned char NPlanos;
	unsigned int ByteLin;
	unsigned int TipoPal;
	unsigned int TamX;
	unsigned int TamY;
	unsigned char Relleno[54];
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Prototipos de las funciones:

void ModoX (void);
void ModoTxt (void);
void PonLongLin (unsigned int Long);
unsigned int LeeLongLin (void);
void PonPixel (unsigned int x, unsigned int y, unsigned char Color);
unsigned char LeePixel (unsigned int x, unsigned int y);
void ClsX (void);
void Modo200Lin (void);
void Modo400Lin (void);
void LeeColor (unsigned char n, struct RGB *Color);
void PonColor (unsigned char n, struct RGB Color);
void LeePaleta (struct RGB Pal[]);
void PonPaleta (struct RGB Pal[]);
void ScrollGrf (unsigned int x, unsigned int y);
void ScrollTxt (unsigned int x, unsigned int y);
//────────────────────────────────────────────────────────────────────────────
void LlenaPantalla (void);

//────────────────────────────────────────────────────────────────────────────
//  Activar Modo X

void ModoX (void)
{
	unsigned int n;

	//  Desconectamos la pantalla
	outportb(TSInd,0x01);
	outportb(TSDat,inportb(TSDat) | 0x20);

	// Activar Modo 13h
	union REGS Registros;
	Registros.x.ax = 0x0013;
	int86 (0x10, &Registros, &Registros);

	// Desactivar Modo Chain 4 y Modo Par/Impar
	outportb (TSInd, 0x04);
	outportb (TSDat, (inportb (TSDat) & 0xF7) | 0x04);

	//  Activamos los cuatro planos para la escritura
	outportb(TSInd,0x02);
	outportb(TSDat,0x0F);

	//  Borramos la memoria de video
	for (n = 0; n < 0xFFFF; n++)
	{
		pokeb(VGA, n, 0);
	}

	// Desactivar Modo Doubleword
	outportb (CRTCInd, 0x14);
	outportb (CRTCDat, inportb (CRTCDat) & 0xBF);

	// Activar Modo Byte
	outportb (CRTCInd, 0x17);
	outportb (CRTCDat, inportb (CRTCDat) | 0x40);

	//  Conectamos la pantalla
	outportb(TSInd,0x01);
	outportb(TSDat,inportb(TSDat) & 0xDF);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Activar Modo Texto:

void ModoTxt (void)
{
	// Activar Modo Texto
	union REGS Registros;
	Registros.x.ax = 0x0003;
	int86 (0x10, &Registros, &Registros);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Definir longitud de línea:

void PonLongLin (unsigned int Long)
{
	outportb (CRTCInd, 0x13);
	outportb (CRTCDat, Long / 8);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Leer longitud de línea:

unsigned int LeeLongLin (void)
{
	outportb (CRTCInd, 0x13);
	return (inportb (CRTCDat) * 8);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Escribir un Pixel en Modo X:

void PonPixel (unsigned int x, unsigned int y, unsigned char Color)
{
	unsigned int Despl;
	unsigned char Plano;

	Plano = 1 << (x % 4);
	Despl = (LeeLongLin () / 4) * y + (x / 4);

	outportb (TSInd, 0x02);
	outportb (TSDat, Plano);
	pokeb (VGA, Despl, Color);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Leer un Pixel en Modo X:

unsigned char LeePixel (unsigned int x, unsigned int y)
{
	unsigned int Despl;
	unsigned char Plano;

	Plano = x % 4;
	Despl = (LeeLongLin () / 4) * y + (x / 4);

	outportb (GDCInd, 0x02);
	outportb (GDCDat, Plano);
	return (peekb (VGA, Despl));
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//Borra la pantalla en Modo X:
//  Se implementa en ensamblador para aumentar la velocidad del código.

void ClsX (void)
{
	unsigned int n;

	//  Activamos los cuatro planos para la escritura
	outportb(TSInd,0x02);
	outportb(TSDat,0x0F);

	//  Desconectamos la pantalla
	outportb(TSInd,0x01);
	outportb(TSDat,inportb(TSDat) | 0x20);

	//  Borramos la memoria de video
	for (n = 0; n < 0xFFFF; n++)
	{
		pokeb(VGA, n, 0);
	}

	//  Conectamos la pantalla
	outportb(TSInd,0x01);
	outportb(TSDat,inportb(TSDat) & 0xDF);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Establecer 200 líneas:

void Modo200Lin (void)
{
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) | 0x80);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Establecer 400 líneas:

void Modo400Lin (void)
{
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) & 0x70);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Leer un color:

void LeeColor (unsigned char n, struct RGB *Color)
{
	outportb (DLP, n);          // Leemos el color número n
	Color->R = inportb (VCP);   // Primero el Rojo (R)
	Color->G = inportb (VCP);   // Segundo el Verde (G)
	Color->B = inportb (VCP);   // Tercero el Azul (B)
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Escribir un color:

void PonColor (unsigned char n, struct RGB Color)
{
	outportb (DEP, n);          // Escribimos el color número n
	outportb (VCP, Color.R);    // Primero el Rojo (R)
	outportb (VCP, Color.G);    // Segundo el Verde (G)
	outportb (VCP, Color.B);    // Tercero el Azul (B)
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Leer la paleta:

void LeePaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DLP, 0);              // Comenzamos por el color 0
	for (n = 0; n < 256; n++)       // Leemos 256 colores
	{
		Pal[n].R = inportb (VCP);   // Primero el Rojo (R)
		Pal[n].G = inportb (VCP);   // Segundo el Verde (G)
		Pal[n].B = inportb (VCP);   // Tercero el Azul (B)
	}
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Escribir la paleta:

void PonPaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DEP, 0);              // Comenzamos por el color 0
	for (n = 0; n < 256; n++)       // Escribimos 256 colores
	{
		outportb (VCP, Pal[n].R);   // Primero el Rojo
		outportb (VCP, Pal[n].G);   // Segundo el Verde
		outportb (VCP, Pal[n].B);   // Tercero el Azul
	}
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Scroll Gráfico en Modo X:

void ScrollGrf (unsigned int x, unsigned int y)
{
	union Reg n;

	// Calculamos el desplazamiento vertical en bytes
	n.w = (LeeLongLin () / 4) * y + (x / 4);

	do {} while (inportb(ISR1) & 0x08);

	// Realizamos el Scroll vertical
	outportb (CRTCInd, 0x0C);   // Dir. de inicio de línea (parte alta)
	outportb (CRTCDat, n.b.h);
	outportb (CRTCInd, 0x0D);   // Dir. de inicio de línea (parte baja)
	outportb (CRTCDat, n.b.l);

	do {} while (~inportb(ISR1) & 0x08);

	// Realizamos el Scroll horizontal
	outportb (ATC, 0x13 | 0x20); // Panning de píxelsles horizontal
	outportb (ATC, (2 * (x % 4)) | 0x20);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
//  Scroll en Modo Texto:

void ScrollTxt (unsigned int x, unsigned int y)
{
	union Reg n;

	// Calculamos el desplazamiento vertical en bytes
	n.w = (LeeLongLin () / 4) * (y / 16) + (x / 9);

	do {} while (inportb(ISR1) & 0x08);

	// Realizamos el Scroll vertical
	outportb (CRTCInd, 0x0C);   // Dir. de inicio de línea (parte alta)
	outportb (CRTCDat, n.b.h);
	outportb (CRTCInd, 0x0D);   // Dir. de inicio de línea (parte baja)
	outportb (CRTCDat, n.b.l);

	do {} while (~inportb(ISR1) & 0x08);

	outportb (CRTCInd, 0x08);
	outportb (CRTCDat, y % 16);

	outportb (ATC, 0x13 | 0x20);
	outportb (ATC, ((x % 9) -1) | 0x20);
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
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
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
#define rad 3.141592 / 180

void main (void)
{
	int x, y, a, Termina = FALSO;

	ModoX ();
	PonLongLin (640);

	for (x = 0; x < 256; x++)       // Escribimos 256 colores
	{
		PonPixel (x, 0, x);
		PonPixel (x, 1, x);
	}

	for (a = 0; a < 180; a = a + 2)
	{
		x = 72 * cos(a * rad); y = 60 * sin(a * rad);
		Linea (x + 160, 100 - y, 160-x, y + 100, a / 5 + 32);
	}

	getch ();

	for (x = 0; x < 200; x++)
	{
		ScrollGrf (x, x);
	}

	ModoTxt();

	PonLongLin (640);

	LlenaPantalla ();

	x = 0; y = 0;

	do
	{
		switch (getch ())
		{
			// Subir
			case 'H':
				y = (y + 1) % (25 * 16 + 1);
				ScrollTxt (x, y);
				break;

			// Bajar
			case 'P':
				y = (25 * 16) - ((25 * 16 + 1 - y) % (25 * 16 + 1));
				ScrollTxt (x, y);
				break;

			// Derecha
			case 'M':
				x = (x + 1) % (80 * 9 + 1);
				ScrollTxt (x, y);
				break;

			// Izquierda
			case 'K':
				x = (80 * 9) - ((80 * 9 + 1 - x) % (80 * 9 + 1));
				ScrollTxt (x, y);
				break;

			case 27:
				Termina = CIERTO;
				break;
			default:;
		}
	}
	while (~Termina);

	ModoTxt ();
};
//────────────────────────────────────────────────────────────────────────────

//────────────────────────────────────────────────────────────────────────────
void LlenaPantalla (void)
{
	int n;

	for (n = 0; n < (160 * 50); n++)
	{
		if (n % 10)
		{
			pokeb (TXT, 2 * n, '-');
		}
		else
		{
			if (n % 160)
			{
				pokeb (TXT, 2 * n, ((n % 160) / 10) % 10 + '0');
			}
			else
			{
				pokeb (TXT, 2 * n, (n / 160) % 10 + '0');
			}
		}
	}
}
//────────────────────────────────────────────────────────────────────────────
