    TYPE RGB
        R AS INTEGER
        G AS INTEGER
        B AS INTEGER
    END TYPE

    DECLARE SUB ModoX ()
    DECLARE SUB ModoTxt ()
    DECLARE SUB PonLongLin (LongLin%)
    DECLARE FUNCTION LeeLongLin% ()
    DECLARE SUB PonPixel (X%, Y%, Col%)
    DECLARE FUNCTION LeePixel% (X%, Y%)
    DECLARE SUB ClsX ()
    DECLARE SUB Modo200Lin ()
    DECLARE SUB Modo400Lin ()
    DECLARE SUB LeeColor (n%, Col AS RGB)
    DECLARE SUB PonColor (n%, Col AS RGB)
    DECLARE SUB LeePaleta (Pal() AS RGB)
    DECLARE SUB PonPaleta (Pal() AS RGB)
    DECLARE SUB ScrollGrf (X%, Y%)
    DECLARE SUB ScrollTxt (X%, Y%)
    DECLARE SUB Linea (X1%, Y1%, X2%, Y2%, Col%)

