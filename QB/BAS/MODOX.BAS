'$INCLUDE: 'modox.bi'

DECLARE SUB LineaX (x1%, y1%, x2%, y2%, c%)

CONST rad = 3.171592 / 180

	DIM x AS INTEGER, y AS INTEGER, a AS SINGLE

	ModoX
	PonLongLin 640

	FOR x = 0 TO 256
		PonPixel x, 0, x
		PonPixel x, 1, x
	NEXT x

	FOR a = 0 TO 179 STEP 2
		x = 72 * COS(a * rad)
		y = 60 * SIN(a * rad)
		Linea x + 160, 100 - y, 160 - x, y + 100, a / 5 + 32
	NEXT a
   
	DO: LOOP UNTIL INKEY$ <> ""
   
	FOR x = 0 TO 200
		ScrollGrf x, x
	NEXT

	ModoTxt

