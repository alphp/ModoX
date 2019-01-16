DECLARE FUNCTION LeePixel% (x%, y%)
DECLARE SUB Division (Fila AS INTEGER)
DECLARE SUB Nombre (Archivo AS STRING)
DECLARE SUB ScrollGrf (x%, y%)
DECLARE SUB PonPaleta (Pal() AS ANY)
DECLARE SUB LongLin (x%)
DECLARE FUNCTION ResX% ()
DECLARE SUB PonPixel (x%, y%, Col%)
DECLARE SUB ModoTxt ()
DECLARE SUB ModoX ()
DECLARE SUB ClsX ()
DECLARE SUB LeeCabecera (Handle AS INTEGER, Cab AS ANY)
DECLARE FUNCTION Abre% (Archivo$)
DECLARE SUB LeePaletaPcx (Handle%, Pal() AS ANY)
DECLARE SUB VisImagenPcx (Handle%, Cab AS ANY)
'─────────────────────────────────────────────────────────────────────────────
' ╔════════════════════════════════════════════════════════════════════════╗
' ║                 Rutinas para gráficos en Modo X                        ║
' ║              Traducciones del Pascal a QBasic por:                     ║
' ║                 Txampi Herrero, (c) Febrero 1996                       ║
' ╚════════════════════════════════════════════════════════════════════════╝

'─────────────────────────────────────────────────────────────────────────────
'   Registros de la VGA:

CONST ATC = &H3C0       'ATC, Registro índice/escritura
CONST ATC1 = &H3C1      'ATC, Registro de lectura
CONST MOREsc = &H3C2    'MOR, Registro de escritura
CONST TSInd = &H3C4     'TS, Registro índice
CONST TSDat = &H3C5     'TS, Registro de datos
CONST DLP = &H3C7       'DAC, Dirección de lectura del pixel
CONST DEP = &H3C8       'DAC, Dirección de escritura del pixel
CONST VCP = &H3C9       'DAC, Valor del color del pixel
CONST MORLec = &H3CC    'MOR, Registro de lectura
CONST GDCInd = &H3CE    'GDC, Registro índice
CONST GDCDat = &H3CF    'GDC, Registro de datos
CONST CRTCInd = &H3D4   'CRTC, Registro índice
CONST CRTCDat = &H3D5   'CRTC, Registro de datos
CONST ISR1 = &H3DA      'ISR, Registro de Estado de Entrada
'─────────────────────────────────────────────────────────────────────────────

CONST CIERTO = -1
CONST FALSO = NOT CIERTO

'─────────────────────────────────────────────────────────────────────────────
'   Estructura necesaria para las operaciones de Colores:

TYPE RGB
	R AS INTEGER
	G AS INTEGER
	B AS INTEGER
END TYPE

'   Ejemplos:
'       -Definición de un color:
'           DIM Color AS RGB
'       -Definición de una paleta:
'           DIM Pal (0 TO 255) AS RGB
'─────────────────────────────────────────────────────────────────────────────

'─────────────────────────────────────────────────────────────────────────────
'  Cálculo de los incrementos y decrementos de los valores del Scroll:
'unsigned int x, y;
'    Para subir:
'        y = 200 - ((200 + 1 - y) MOD (200 + 1))
'
'    Para bajar:
'        y = (y + 1) MOD (200 + 1)
'
'    Para la derecha:
'        x = (x + 1) MOD (320 + 1)
'
'    Para la izquierda:
'        x = 320 - ((320 + 1 - x) MOD (320 + 1))
'─────────────────────────────────────────────────────────────────────────────

TYPE Cabecera
	formato AS STRING * 1
	InfVer AS STRING * 1
	RLE AS STRING * 1
	BitsPix AS STRING * 1
	Xmn AS INTEGER
	Ymn AS INTEGER
	Xmx AS INTEGER
	Ymx AS INTEGER
	DpiX AS INTEGER
	DpiY AS INTEGER
	MapCol AS STRING * 48
	Reserv AS STRING * 1
	NPlanos AS STRING * 1
	ByteLin AS INTEGER
	TipoPal AS INTEGER
	TamX AS INTEGER
	TamY AS INTEGER
	Relleno AS STRING * 54
END TYPE

DIM Handle AS INTEGER
DIM n AS INTEGER

DIM Cab AS Cabecera
DIM Pal(0 TO 255) AS RGB
DIM Archivo AS STRING

DIM Termina AS INTEGER
DIM x AS INTEGER, y AS INTEGER

INPUT "Imagen: ", Archivo
IF LEN(Archivo) THEN
	Nombre Archivo

	ON ERROR GOTO NoAbre
		Handle = FREEFILE
		OPEN Archivo FOR INPUT AS #Handle
		CLOSE #Handle
	ON ERROR GOTO 0

	Handle = Abre%(Archivo)

	LeeCabecera Handle, Cab

	ModoX
	LongLin 640

	LeePaletaPcx Handle, Pal()
	PonPaleta Pal()
	VisImagenPcx Handle, Cab

	Division 100
	OUT ATC, (&H10 OR &H20)
	OUT ATC, INP(ATC1) OR &H20

	CLOSE #Handle

	Termina = FALSO
	DO
		SELECT CASE INKEY$
			CASE CHR$(0) + "H"      'Subir
				y = 200 - ((200 + 1 - y) MOD (200 + 1))
				ScrollGrf x, y
			CASE CHR$(0) + "P"      'Bajar
				y = (y + 1) MOD (200 + 1)
				ScrollGrf x, y
			CASE CHR$(0) + "M"      'Derecha
				x = (x + 1) MOD (ResX% - 319)
				ScrollGrf x, y
			CASE CHR$(0) + "K"      'Izquierda
				x = ResX% - 320 - ((ResX% - 319 - x) MOD (ResX% - 319))
				ScrollGrf x, y
			CASE CHR$(27)
				Termina = CIERTO
			CASE ELSE
		END SELECT
	LOOP UNTIL Termina

	'ModoX
	'LongLin 320

	FOR n = 0 TO 255
		PonPixel n, 0, n
		PonPixel n, 1, n
	NEXT n

	DO: LOOP UNTIL INKEY$ <> ""

	ModoTxt

	PRINT "(c) Txampi Herrero, Marzo 1996"
ELSE
	PRINT "Sintaxis: VIS <imagen[.pcx]>"
END IF

SYSTEM

NoAbre:
	Codigo = ERR
	RESUME DameError

DameError:
	SELECT CASE Codigo
		CASE 52
			PRINT "Nombre o número de archivo incorrecto"
		CASE 53
			PRINT "Archivo no encontrado"
		CASE 64
			PRINT "Nombre de archivo incorrecto"
		CASE 68
			PRINT "Dispositivo no disponible"
		CASE 70
			PRINT "Permiso denegado"
		CASE 75
			PRINT "Error de acceso en camino/archivo"
		CASE 76
			PRINT "Camino no encontrado"
		CASE ELSE
			PRINT "Código de error:"; Codigo
	END SELECT
SYSTEM

FUNCTION Abre% (Archivo$)
	DIM Handle AS INTEGER

	Handle = FREEFILE
	OPEN Archivo$ FOR BINARY AS #Handle
	Abre% = Handle
END FUNCTION

'─────────────────────────────────────────────────────────────────────────────
'   Borra la pantalla en Modo X:
SUB ClsX
	DIM n AS INTEGER

'   Activamos los cuatro planos para la escritura
	OUT TSInd, &H2
	OUT TSDat, &HF

'   Borramos la memoria de video
	DEF SEG = &HA000
	FOR n = 0 TO 16000
		POKE n, 0
		POKE n + 16000&, 0
		POKE n + 32000&, 0
		POKE n + 48000, 0
	NEXT n
	DEF SEG
END SUB

SUB Division (Fila AS INTEGER)
	OUT CRTCInd, &H7
	OUT CRTCDat, ((Fila \ 8) AND 16) OR (INP(CRTCDat) AND &HEF)
	OUT CRTCInd, &H9
	OUT CRTCDat, INP(CRTCDat) AND &HBF OR ((Fila \ 4) AND 64)
	OUT CRTCInd, &H18
	OUT CRTCDat, (Fila * 2)
END SUB

SUB LeeCabecera (Handle AS INTEGER, Cab AS Cabecera)
	GET #Handle, 1, Cab
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Lee el color indicado:
SUB LeeColor (n%, Col AS RGB)
'   Leemos el color número n
	OUT DLP, n%

'   Leemos las componentes del color
	Col.R = INP(VCP)
	Col.G = INP(VCP)
	Col.B = INP(VCP)
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Lee la paleta activa y la guarda en la paleta indicada:
SUB LeePaleta (Pal() AS RGB)
	DIM n AS INTEGER

	OUT DLP, 0
	FOR n = 0 TO 255
		Pal(n).R = INP(VCP)
		Pal(n).G = INP(VCP)
		Pal(n).B = INP(VCP)
	NEXT n
END SUB

SUB LeePaletaPcx (Handle%, Pal() AS RGB)
	DIM Paleta AS STRING * 768
	DIM n AS INTEGER

	GET #Handle%, LOF(Handle%) - 767, Paleta

	FOR n = 0 TO 255
		Pal(n).R = ASC(MID$(Paleta, 3 * n + 1, 1)) \ 4
		Pal(n).G = ASC(MID$(Paleta, 3 * n + 2, 1)) \ 4
		Pal(n).B = ASC(MID$(Paleta, 3 * n + 3, 1)) \ 4
	NEXT n
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Lee un pixel en ModoX:
FUNCTION LeePixel% (x%, y%)
	DIM Despl AS LONG
	DIM Plano AS INTEGER
	DIM Col AS INTEGER

	Plano = x% MOD 4
	Despl = (ResX% \ 4) * y% + (x% \ 4)

	OUT GDCInd, &H4
	OUT GDCDat, Plano

	DEF SEG = &HA000
	Col = PEEK(Despl)
	DEF SEG
	LeePixel% = Col
END FUNCTION

SUB LongLin (x%)
	OUT CRTCInd, &H13
	OUT CRTCDat, (x% \ 8)
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Activa el modo de 200 líneas:
SUB Modo200Lin
	OUT CRTCInd, &H9
	OUT CRTCDat, (INP(CRTCDat) OR &H80)
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Activa el modo de 400 líneas:
SUB Modo400Lin
	OUT CRTCInd, &H9
	OUT CRTCDat, (INP(CRTCDat) AND &H70)
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Activa el modo de texto:
SUB ModoTxt
	SCREEN 0
	WIDTH 80
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Establece el Modo X y lo inicializa:
SUB ModoX
'   Activamos el modo de video 13h mediante la ROM BIOS
	SCREEN 13

'   Desactivamos el Modo Chain 4 y el Modo Par/Impar
	OUT TSInd, &H4
	OUT TSDat, (INP(TSDat) AND &HF7 OR &H4)

'   Desactivamos el Modo Doubleword
	OUT CRTCInd, &H14
	OUT CRTCDat, (INP(CRTCDat) AND &HBF)

'   Activamos el Modo Byte
	OUT CRTCInd, &H17
	OUT CRTCDat, (INP(CRTCDat) OR &H40)

'   Borramos la pantalla
	ClsX
END SUB

SUB Nombre (Archivo AS STRING)
	IF INSTR(Archivo, " ") THEN
		Archivo = LEFT$(Archivo, INSTR(Archivo, " ") - 1)
	END IF
	IF INSTR(Archivo, ".") = 0 THEN
		Archivo = Archivo + ".PCX"
	END IF
	Archivo = LEFT$(Archivo, INSTR(Archivo, ".") + 3)
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Escribe el color indicado:
SUB PonColor (n%, Col AS RGB)
'   Escribimos el color número n
	OUT DEP, n%

'   Escribimos las componentes del color
	OUT VCP, Col.R
	OUT VCP, Col.G
	OUT VCP, Col.B
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Establece la paleta indicada como la paleta activa:
SUB PonPaleta (Pal() AS RGB)
	DIM n AS INTEGER

	OUT DEP, 0

	FOR n = 0 TO 255
		OUT VCP, Pal(n).R
		OUT VCP, Pal(n).G
		OUT VCP, Pal(n).B
	NEXT n
END SUB

'─────────────────────────────────────────────────────────────────────────────
'   Escribe un pixel en ModoX:
SUB PonPixel (x%, y%, Col%)
	DIM Despl AS LONG
	DIM Plano AS INTEGER

	Plano = 2 ^ (x% MOD 4)
	Despl = (ResX% \ 4) * y% + (x% \ 4)

	OUT TSInd, &H2
	OUT TSDat, Plano

	DEF SEG = &HA000
	POKE Despl, Col%
	DEF SEG
END SUB

FUNCTION ResX%
	OUT CRTCInd, &H13
	ResX% = 8 * INP(CRTCDat)
END FUNCTION

'─────────────────────────────────────────────────────────────────────────────
'   Scroll Gráfico en Modo X:
SUB ScrollGrf (x%, y%)
	DIM n AS LONG

'   Calculamos el desplazamiento vertical en bytes
	n = (ResX% \ 4) * y% + (x% \ 4)

'   Realizamos el Scroll vertical
	OUT CRTCInd, &HC
	OUT CRTCDat, n \ 256    ' Dir. de inicio de línea (parte alta)
	OUT CRTCInd, &HD
	OUT CRTCDat, n MOD 256  ' Dir. de inicio de línea (parte baja)

'   Realizamos el Scroll horizontal
	'OUT ATC, (&H13 OR &H20)
	OUT ATC, &H33
	OUT ATC, ((2 * (x% MOD 4)) OR &H20) ' Panning de píxelsles horizontal
END SUB

SUB VisImagenPcx (Handle%, Cab AS Cabecera)
	DIM x AS INTEGER, y AS INTEGER
	DIM Plano AS INTEGER, OffSet AS LONG
	DIM Termina AS INTEGER
	DIM Col AS STRING * 1
	DIM Rep AS INTEGER
	DIM R AS INTEGER

	Termina = FALSO
	SEEK #Handle%, 129
	DEF SEG = &HA000
	y = Cab.Ymn
	DO
		x = Cab.Xmn
		DO
			IF SEEK(Handle%) = LOF(Handle%) - 768 THEN
				Termina = CIERTO
			ELSE
				GET #Handle%, , Col
				Rep = 1
				IF ASC(Col) > 192 THEN
					Rep = ASC(Col) AND &H3F
					GET #Handle%, , Col
				END IF
				FOR x = x TO Rep + x - 1
					PonPixel x, y, ASC(Col)
				NEXT x
			END IF
		LOOP UNTIL (x > Cab.Xmx) OR Termina
		y = y + 1
	LOOP UNTIL (y > Cab.Ymx) OR Termina OR INKEY$ <> ""
	DEF SEG
END SUB

