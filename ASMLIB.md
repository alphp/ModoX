## GENERAL

Los entornos de programación que admiten librerias, tales como QuickBASIC y Turbo C, permiten la creación de estas en lenguaje ensamblador a trabes de su código objeto.

La estructura de un procedimiento en ensamblador es la siguiente:

```Assembly
codigo  segment
		assume  cs:codigo
		public  _Proc

_Proc   proc    far
		push    bp
		mov     bp,sp
		push    si      ;Solo si se utiliza en el procedimiento
		push    di      ;Solo si se utiliza en el procedimiento

		;Cuerpo del procedimiento

		pop     di      ;Solo si se utiliza en el procedimiento
		pop     si      ;Solo si se utiliza en el procedimiento
		pop     bp
		ret
_Proc   endp

codigo  ends
		end
```

Los parametros se pasan al procedimiento en la pila, asi hay que recordar que en BASIC los parametros se pasan por defecto por referencia, mientras que en C se pasan por valor. Otra diferencia es el orden en el que son empilados los parametros, asi en BASIC se empila de izquierda a derecha y en C justo al contrario. Esto es, dada la llamada FUNC(A, B, C), BASIC empilara primero la DIRECCION de A seguida de la de B y después la de C, mientras que C empilara primero el VALOR de C seguido el de B y despueés el de C. El número de bytes ocupado en la pila por cada tipo se muestra en la siguiente tabla (BASIC pasa las direcciones como punteros del tipo *near*):

|Tipo                  |Número de Bytes              |
|----------------------|-----------------------------|
|Entero                |2                            |
|Entero largo          |4                            |
|Simple precisión      |4                            |
|Puntero (*near*)      |2 (sólo desplazamiento)      |
|Puntero (*far*)       |4 (segmento y desplazamiento)|

Antes de entrar en un procedimiento en código ensamblador, el contenido del registro BP debe salvarse en la pila y el valor actual del puntero de la pila (SP) debe colocarse en BP. Los únicos registros que se deben preservar son SI y DI si los usa la rutina.

Si la función en lenguaje ensamblador devuelve un valor, éste se coloca en el registro AX si es un valor de 8 ó 16 bits. En cualquier otro caso se devuelve de acuerdo con la siguiente tabla:

|Tipo            |Registro(s) y significado                          |
|----------------|---------------------------------------------------|
|entero          |AX                                                 |
|entero largo    |DX:AX (Palabra de orden alto:Palabra de orden bajo)|
|simple precisión|DX:AX (Palabra de orden alto:Palabra de orden bajo)|

## QuickBASIC

Para hacer bien las librerias en ensamblador para QB (QuickBASIC) es necesario cumplir con las especificaciones del interprete (librerias QLB) y con las del lenguaje compilado (librerias LIB).

Puesto que hay detalles que cambian segun se ejecute el programa en modo interprete o compilado, es necesario ajustarse a unos convenios que, aunque innecesarios para uno de los modos, son necesarios para el otro. Esto tiene la ventaja de tener únicamente un módulo fuente para ambas librerias (QLB y LIB), aunque presenta la desventaja de realizar operaciones que quizas para una de las librerias fueran innecesarias.

Nos referiremos con el termino QB tanto al programa interpretado como al compilado.

## ESTADO DE LA PILA

Cuando se produce la llamada al procedimiento, QB empila los desplazamientos de los parametros (de izquierda a derecha), despues empila el segmento de código y el puntero de instrucción.

La pila quedara entonces como sigue:

	│             │ Direcciones Bajas
	├─────────────┤
	│      IP     │ <-- SP      | El puntero de Pila apunta al
	│      CS     │ <-- SP + 2  | desplazamiento de retorno. Dos bytes
	├─────────────┤             | por debajo se encuentra el segmento de
	│ Parámetro n │ <-- SP + 4  | retorno. Y dos bytes más abajo empieza
	│      ·      │             | la lista de parámetros.
	│      ·      │
	│      ·      │
	│ Parámetro 1 │ <-- SP + 2·(n + 1)
	├─────────────┤
	│             │ Direcciones Altas

## ACCESO A LOS PARAMETROS

Puesto que QB empila los desplazamientos de los parametros, tendremos que servirnos de un puntero para acceder a estos de la siguiente manera:

1. Empilamos BP
2. Copiamos el valor de SP en BP
3. Copiamos el desplazamiento del parámetro requerido en un registro índice.
4. Accedemos al parámetro mediante el registro índice.

Si el parámetro requerido es una cadena, QB nos da el desplazamiento del descriptor de la cadena, y no de la cadena en si. El descriptor de la cadena tiene una longitud de cuatro bytes, los dos primeros indican la longitud de la cadena, y los dos segundos bytes componen el desplazamiento de la cadena respecto de segmento de datos (DS) cargado por QB con el valor apropiado.

## RETORNO DE VALORES (FUNCIONES)

El retorno de valores en las funciones de QB se realiza mediante el registro AX o DX:AX según la siguiente tabla:

|Tipo            |Registro(s) y significado                          |
|----------------|---------------------------------------------------|
|Entero          |AX                                                 |
|Entero largo    |DX:AX (Palabra de orden alto:Palabra de orden bajo)|
|Simple precisión|DX:AX (Palabra de orden alto:Palabra de orden bajo)|

## REGLAS A SEGUIR

Los procedimientos deveran estar definidos como FAR (lejanos) y cumplir las siguientes reglas:

1. El contenido de los registros AX, BX, CX, DX, SI y DI pueden ser destruidos y no necesitan ser restaurados para volver a QB.
2. Los registros BP, CS, DS, ES y SS tendran que ser restarurados antes de retornar a QB en caso de ser modificados.
3. El retorno a QB se realizara con RET n, siendo n = 2 * Nº Parámetros.

## EJEMPLO

A continuación se detalla el listado de una libreria en ensamblador con dos procedimientos (Suma y Escribe), se han indicado a modo de comentarios las declaraciones de los procedimientos a incluir en QB:

```Assembly
codigo  segment
		assume cs:codigo
		public Suma
		public Escribe

;DECLARE FUNCTION Suma% (A%, B%)
Suma    proc    far
		push    bp          ;Se guarda el contenido de BP
		mov     bp,sp       ;Se copia en BP el contenido de SP

		mov     si,[bp+8]   ;Copiamos el desplazamiento de A en SI
		mov     ax,[si]     ;Copiamos A en AX
		mov     si,[bp+6]   ;Copiamos el desplazamiento de B en SI
		add     ax,[si]     ;Sumamos B a AX (A), y como el resultado queda
							;en AX, sera retornado a QB.
		pop     bp          ;Restablecemos BP
		ret     4           ;Retornamos a QB (4 = 2 * 2 Parámetros)
Suma    endp

;DECLARE SUB Escribe (Cad$)
Escribe proc    far
		push    bp          ;Se guarda el contenido de BP
		mov     bp,sp       ;Se copia en BP el contenido de SP
		push    es          ;Se guarda el contenido de ES

		mov     ax,ds       ;Copiamos DS en AX
		mov     es,ax       ;Copiamos AX en ES (ES <-- DS)
		mov     ax,1301h
		mov     bx,0007h
		mov     si,[bp+6]   ;Cojemos el despl. del descriptor de la cadena
		mov     cx,[si]     ;Cojemos la longitud de la cadena
		mov     dx,1010h
		mov     bp,[si+2]   ;Cojemos el despl. de la cadena dentro de DS
		int     10h

		pop     es          ;Restablecemos ES
		pop     bp          ;Restablecemos BP
		ret     2           ;Retornamos a QB (2 = 2 * 1 Parámetro)
Escribe endp

codigo  ends
		end
```
