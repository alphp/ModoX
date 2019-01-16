'$INCLUDE: 'modox.bi'

DECLARE SUB EspNoReen ()
DECLARE SUB ScrollTxtx (X%, Y%)
DECLARE SUB LlenaPantalla ()
DECLARE SUB EspReen ()
DECLARE SUB PanH (n AS INTEGER)
DECLARE SUB PanV (n AS INTEGER)

CONST FALSO = 0
CONST CIERTO = NOT FALSO

DIM X AS INTEGER
DIM Y AS INTEGER
DIM Termina AS INTEGER

Termina = FALSO

SCREEN 0
LOCATE , , 0

PonLongLin 640

LlenaPantalla

DO
    SELECT CASE INKEY$
        CASE CHR$(0) + "H"      'Subir
            Y = (Y + 1) MOD (25 * 16 + 1)
            ScrollTxt X, Y
        CASE CHR$(0) + "P"      'Bajar
            Y = (25 * 16) - ((25 * 16 + 1 - Y) MOD (25 * 16 + 1))
            ScrollTxt X, Y
        CASE CHR$(0) + "M"      'Derecha
            X = (X + 1) MOD (80 * 9 + 1)
            ScrollTxt X, Y
        CASE CHR$(0) + "K"      'Izquierda
            X = (80 * 9) - ((80 * 9 + 1 - X) MOD (80 * 9 + 1))
            ScrollTxt X, Y
        CASE CHR$(27)
            Termina = CIERTO
        CASE ELSE
    END SELECT
LOOP UNTIL Termina

ModoTxt

SUB EspNoReen
    DO: LOOP WHILE (INP(&H3DA) AND &H8)
END SUB

SUB EspReen
    DO: LOOP UNTIL (INP(&H3DA) AND &H8)
END SUB

SUB LlenaPantalla
    DIM n AS INTEGER

    DEF SEG = &HB800
    FOR n = 0 TO 160 * 50
        IF n MOD 10 THEN
            POKE 2 * n, ASC("-")
        ELSE
            POKE 2 * n, ((n MOD 160) \ 10) MOD 10 + ASC("0")
        END IF
        IF (n MOD 160) = 0 THEN
            POKE 2 * n, (n \ 160) MOD 10 + ASC("0")
        END IF
    NEXT n
    DEF SEG
END SUB

SUB PanH (n AS INTEGER)
    OUT &H3C0, (&H13 OR &H20)
    OUT &H3C0, (n OR &H20)
END SUB

SUB PanV (n AS INTEGER)
    OUT &H3D4, 8
    OUT &H3D5, n
END SUB

SUB ScrollTxtx (X%, Y%)
    DIM n AS INTEGER

    n = (Y% \ 16) * 160 + (X% \ 9)

    EspNoReen
    OUT &H3D4, &HC
    OUT &H3D5, n \ 256
    OUT &H3D4, &HD
    OUT &H3D5, n MOD 256
    EspNoReen
    PanV (Y% MOD 16)
    PanH ((X% - 1) MOD 9)
END SUB

