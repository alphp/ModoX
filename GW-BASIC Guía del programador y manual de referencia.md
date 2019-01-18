# Microsoft GW-BASIC: Guía del programador y manual de referencia

Título de la obra original:  
[*Microsoft GW-BASIC User's Guide and Reference*](https://hwiegman.home.xs4all.nl/gw-man/index.html)

## Apéndice D: Subrutinas en lenguaje ensamblador

Este apéndice está escrito principalmente para usuarios experimentados en programación en lenguaje ensamblador (lenguaje máquina).

El GW-BASIC le permite conectar con subrutinas en lenguaje ensamblador utilizando la función USR y la instrucción CALL.

La función USR permite que se llame a las subrutinas en lenguaje ensamblador de la misma forma que se llama a las funciones en el GW-BASIC intrínsecas. Sin embargo, se recomienda la instrucción CALL para conectar programas en lenguaje máquina con el GW-BASIC. La instrucción CALL es compatible con más lenguajes que la llamada a la función USR, produce un código fuente más legible y puede pasar múltiples argumentos.

### D.1 Localización de memoria

El espacio de memoria tiene que inicializarse para una subrutina en lenguaje ensamblador antes de que pueda cargarse. Hay tres métodos recomendados para inicializar espacio para las rutinas en lenguaje ensamblador:

- Especificar una matriz y usar VARPTR para localizar el comienzo de la matriz antes de cualquier acceso.
- Utilizar el parámetro /m en la línea de comandos. Obtener el segmento de datos (DS) del GW-BASIC y sumar el tamaño del DS para referenciar el espacio reservado por encima del segmento de datos.
- Ejecutar un fichero .COM que permanezca residente y almacenarle un puntero en un vector de interrupción libre.

Hay tres métodos recomendados para cargar rutinas en lenguaje ensamblador:

- Utilizar BLOAD para cargar el fichero. Usar DEBUG para cargar un fichero .EXE en alta memoria, ejecutar el GW-BASIC y grabar con BSAVE el fichero .EXE
- Ejecutar un fichero .COM que contiene las rutinas. Salvar el puntero a esas rutinas en posiciones de vectores de interrupciones libres, para que su aplicación en el GW-BASIC pueda obtener el puntero y utilizar la rutina(s).
- Situar las rutinas en el área especificada.

Si se necesita más espacio de pila cuando se llama a una subrutina en lenguaje ensamblador, se puede almacenar el espacio de pila del GW-BASIC y definir uno nuevo para la subrutina en lenguaje ensamblador. Sin embargo, el espacio de pila del GW-BASIC tiene que restaurarse antes de volver de la subrutina.

### D.2 Instrucción CALL

**CALL** *nombre de variable*[(argumentos)]

*nombre de variable* contiene el desplazamento en el segmento actual de la subrutina que se está llamando.

*argumentos* son las variables o constantes, separadas por comas, que se pasan a la rutina.

Para cada parámetro en *argumentos*, el desplazamiento de dos bytes de la posición de los parámetros dentro de un segmento de datos (DS) se pone en la pila.

Una llamada lejana a la dirección de segmento de la última instrucción DEF SEG y el desplazamiento *nombre de variable* transfieren el control a la rutina del usuario.

El segmento de pila (SS), segmento de datos (DS), segmento extra (ES) y el puntero a pila (SP) tienen que reservarse.

En la figura D.1 aparece el estado de la pila en el momento de la instrucción CALL:

	       Direcciones altas
	
	 │                            │
	 ├────────────────────────────┤
	 |        Parámetro 0         |     Cada parámetro es un puntero
	 |        Parámetro 1         |     de dos bytes en memoria
	 │             ·              │
	 │             ·              │
	 │             ·              │
	 |        Parámetro n         |
	 ├────────────────────────────┤
	 |       Dirección del        |
	 |    segmento de retorno     |
	 ├────────────────────────────┤
	 │ Desplazamiento del retorno │ <== Puntero de la pila (SP)
	 ├────────────────────────────┤
	 
	       Direcciones bajas
> **Figura D.1 Estructura de la pila al activar la instrucción CALL**

La rutina del usuario tiene ahora el control. Los parámetros se pueden referenciar moviendo el puntero de pila (SP) al puntero base (BP) y sumándole un desplazamiento positivo.

Hasta la entrada, los registros de segmento DS, ES y SS apuntan a la dirección del segmento que contiene el código intérprete del GW-BASIC. El registro de segmento de código CS contiene el último valor proporcionado por DEF SEG. Si no se ha especificado DEF SEG, apunta entonces a la misma dirección que DS, ES y SS (el DEF SEG por defecto).

En la figura D.2 puede verse la condición de la pila durante la ejecución de la subrutina llamada:

	       Direcciones altas
	
	 │                            │
	 ├────────────────────────────┤
	 |        Parámetro 0         | <== Ausente si se referencia
	 |        Parámetro 1         |     cualquier parámetro dentro
	 │             ·              │     de un procedimiento anidado.
	 │             ·              │
	 │             ·              │
	 |        Parámetro n         |
	 ├────────────────────────────┤
	 |       Dirección del        | <== Ausencia en procedimiento local
	 |    segmento de retorno     |
	 ├────────────────────────────┤
	 │ Desplazamiento del retorno │ <== Puntero de la pila (SP)
	 ├────────────────────────────┤
	 │  Antigua marca de la pila  │ <== Nueva marca de la pila
	 ├────────────────────────────┤
	 |      Variables locales     | <== Sólo en procedimientos
	 │              ·             │     re-entrantes
	 │              ·             │
	 │              ·             │
	 ├────────────────────────────┤
	 |     Este espacio puede     | <== El puntero de la pila (SP)
	 |    utilizarse durante la   |     puede cambiar durante la
	 |        ejecución del       |     ejecución del procedimiento
	 |        procedimiento       |
	 │              ·             │
	 │              ·             │
	 │              ·             │
	 ├────────────────────────────┤
	 
	       Direcciones bajas
> **Figura D.2 Estructura de la pila durante la ejecución de la instrucción CALL**

Las siete reglas siguientes tienen que seguirse cuando se codifica una subrutina:

1. La rutina llamada puede destruir los contenidos de los registros AX, BX, CX, DX, SI, DI y BP. No requieren restauración hasta volver al GW-BASIC. Sin embargo, tiene que restaurarse todos los registros de segmento y el puntero de pila. La buena práctica de programación dicta que las interrupciones activadas o desactivadas se restauren al estado mantenido hasta la entrada.
2. El programa de llamada tiene que conocer el número y la longitud de los parámetros pasados. Las referencias a parámetros son desplazamientos positivos sumados a BP, asumiendo que la rutina de llamada movió el puntero de pila actual en BP, esto es, `MOV BP, SP`. Cuando se pasan tres parámetros, la posición de P0 es BP + 10, P1 es BP + 8 y P2 es BP + 6.
3. La rutina llamada tiene que hacer un RETURN *n* (*n* es dos veces el número de parámetros de la lista de argumentos) para ajustar la pila al comienzo de la secuencia de llamada. Los programas también tienen que estar definidos con una instrucción `PROC FAR`.
4. Los valores se devuelven al GW-BASIC incluyendo en la lista de argumentos el nombre de la variable que recibe el resultado.
5. Si el argumento es una cadena, el desplazamiento del parámetro apunta a tres bytes llamados *descriptor de cadena*. El byte 0 del descriptor de cadena contiene la longitud de la cadena (0 a 255). Los bytes 1 y 2, respectivamente, son los ocho bits más bajos y más altos de la dirección de comienzo de la cadena en el espacio de cadenas.
    > ***Nota:***  
    La rutina llamada no tiene que cambiar los contenidos de cualquiera de los tres bytes del descriptor de cadena.
6. Las cadenas pueden alterarse por rutinas del usuario, pero su logitud no tiene que cambiarse. El GW-BASIC no puede manipular correctamente cadenas si sus longitudes se modifican con rutinas externas.
7. Si el argumento es un literal de cadena en el programa, el descriptor de cadena apunta al texto del programa. Hay que tener cuidado de no alterar o destruir el programa de esta forma. Para evitar resultados impredecibles, sumar + "" a la cadena literal del programa. Por ejemplo, la línea siguiente fuerza al literal de cadena a copiarse en el espacio de cadenas localizado fuera del espacio de memoria del programa:
    ```vbnet
    20 A$="BASIC"+""
    ```
    La cadena puede entoces ser modificada sin afectar al programa.

#### Ejemplos:

```vbnet
100 DEF SEG=&H2000
110 ACC=&H7FA
120 CALL ACC(A, B$, C)
·
·
·
```

La siguiente secuencia, en lueguaje ensamblador, demuestra el acceso a los parámetros pasados y almacena un resultado de retorno en la variable C.

> ***Nota:***  
    El programa de llamada tiene que conocer el tipo de la variable en los parámetros numéricos pasados. En estos ejemplos, la instrucción siguiente copia sólo dos bytes:  
    `MOVSW`  
    Esto es adeucado si las variables A y C son enteros. Sería necesario copiar cuatro bytes si fueran de simple precisión, o copiar ocho bytes si fueran de doble precisión.

```
MOV BP, SP     ;Obtiene la posición actual de la pila en BP.
MOV BX, 8[BP]  ;Obtiene la dirección del descriptor B$.
MOV CL, [BP]   ;Obtiene la longitud de B$ en CL.
MOV DX, 1[BX]  ;Obtiene la dirección del texto en B$ en DX.
MOV SI, 10[BP] ;Obtiene la dirección de A en SI.
MOV DI, 6[BP]  ;Obtiene un puntero a C en DI
MOVSW          ;Almacena la variable A en 'C'.
RET 6          ;Restaura la pila y vuelve
```

### D.3 Llamadas a fnciónes USR

Aunque la instrucción CALL sea el método recomendado para llamar a subrutinas en lenguaje ensamblador, todavía están disponibles las llamadas a la función USR para compatibilidad con programas anteriores.

#### Sintaxis:

**USR**\[*n*\](*argumento*)

*n* es un número de 0 a 9 que especifica la rutina USR a la que se está llamando (véase la instrucción DEF USR). Si se omite *n*, se asume USR0.

*argumento* es cualquier expresión numérica o de cadena.

En el GW-BASIC, una instrucción DEF SEG debe ejecutarse antes de una llamada a la función USR, para asegurar que el segmento de código apunte a la subrutina a la que se va a llamar. La dirección de segmento de la instrucción DEF SEG determina la dirección de comienzo de la subrutina.

Para cada llamada a la función USR, tiene que haberse ejecutado la correspondiente instrucción DEF USR para definir el desplazamiento de llamada a la función USR. Este desplazamiento y la dirección activa DEF SEG determinan la dirección de comienzo de la subrutina.

Cuando se ha realizado una llamada a la función USR, el registro AL contiene el *indicador del tipo de número* (NTF: *Numbet Type Flag*), que especifica el tipo de argumento dado. El valor NTF puede ser:

|Valor NTF|Especifica                                             |
|:-------:|-------------------------------------------------------|
|    2    | un entero de dos bytes (en formato complemento a dos) |
|    3    | una cadena                                            |
|    4    | un número en punto flotante de simple precisión       |
|    8    | un número en punto flotante de doble precisión        |

Si el argumento de una llamada a la función USR es un número (AL <> 73), el valor del argumento se sitúa en el *acumulador de punto flotante* (FAC: *floating-point accumulator*). El FAC es de una longitud de ocho bytes y está en el segmento de datos del GW-BASIC. El registro BX apunta al quinto byte del FAC. La figura D.3 muestra la representación de todos los tipos numéricos del GW-BASIC en el FAC:

| BX - 4 | BX - 3 | BX - 2 | BX - 1 |  BX  | BX + 1 | BX + 2 | BX + 3 | BX + 4 |     |
|:------:|:------:|:------:|:------:|:----:|:------:|:------:|:------:|:------:|:---:|
||||| byte menos significativo | byte más significativo |||| Entero |
||||| byte menos significativo ||| byte más significativo | exponente menos 128 | Simple precisión |
| byte menos significativo ||||||| byte más significativo | exponente menos 128 | Doble precisión |
|||||||| byte de signo |||

> **Figura D.3 Tipos numéricos en el acumulador en punto flotante**

Si el argumento es un entero:

- BX + 1 contiene los ocho bits más altos del argumento.
- BX + 0 contiene los ocho bits más bajos del argumento.

Si el argumento es un número en punto flotante de precisión simple:

- BX + 3 es el exponente, menos 128. El punto binario está a la izquierda del bit más significativo de la mantisa.
- BX + 2 contiene los siete bits más altos de la mantisa con el primer 1 implícito. El bit 7 es el signo del número (0 = positivo, 1 = negativo).
- BX + 1 contiene los ocho bits medios de la mantisa.
- BX + 0 contiene los ocho bits más bajos de la mantisa.

Si el argumento es un número en punto flotante de doble precisión:

- BX + 0 a BX + 3 son iguales que en punto flotante de simple precisión.
- BX - 1 a BX - 4 contienen cuatro bytes más de la mantisa. BX - 4 contiene los ocho bits más bajos de la mantisa.

Si el argumento es una cadena (indicado por el valor 3 almacenado en el registro Al) el par de registro (DX) apunta a tres bytes llamados el descriptor de cadena. El byte 0 del descriptor de cadena contiene la longitud de la cadena (0 a 255). Los bytes 1 y 2, respectivamente, son los ocho bits inferiores y superiores de la dirección de comienzo de la cadena en el segmento de datos del GW-BASIC.

Si el argumento es un literal de cadena del programa, el descriptor de cadena apunta al texto del programa. Téngase cuidado de no alterar o destruir programas de esta forma (véase la instrucción CALL precedente).

Normalmente, el valor devuelto por una llamada a función USR es del mismo tipo (entero, cadena, simple precisión, doble precisión) que el argumento que se pasa. Los registros que tienen que conservarse son los mismos que en la instrucción CALL.

Si se necesita un `FAR RETURN` para salir de la subrutina USR, el valor devuelto tiene que almacenarse en la FAC.

### D.4 Programas que llaman a otros en lenguaje ensamblador

Esta sección contiene dos ejemplos de programas en el GW-BASIC que:

- Cargan una rutina en lenguaje ensamblador para sumar dos números
- Devuelven la suma en memoria
- Permanecen residentes en memoria

El segmento de código y el desplazamiento a la primera rutina se almacenan en el vector de interrupción en 0:100H.

El ejemplo 1 llama a una subrutina en lenguaje ensamblador:

#### Ejemplo 1

```vbnet
010 DEF SEG=0
100 CS=PEEK(&H102)+PEEK(&H103)*256
200 OFFSET=PEEK(&H100)+PEEK(&H101)*256
250 DEF SEG
300 C1%=2:C2%=3:C3%=0
400 SUMARDOS=OFFSET
500 DEF SEG=CS
600 CALL SUMARDOS(C1%,C2%,C3%)
700 PRINT C3%
800 END
```

La subrutina en lenguaje ensamblador llamada en el programa anterior tiene que ser ensamblada, enlazada y convertida en un fichero .COM. El programa, cuando se ejecuta antes del programa en el GW-BASIC, permanecerá residente en memoria hasta que se desactive la alimentación del sistema o se reinicialice el sistema.

```
0100            org 100H
0100            double segment
                assume cs:double
0100 EB 17 90   start: jmp start1
0103            usrprg proc far
0103 55         push bp
0104 8B EC      mov bp,sp
0106 8B 76 08   mov si,[bp]+8        ;obtener dirección del parámetro b
0109 8B 04      mov ax,[si]          ;obtener valor de b
010B 8B 76 0A   mov si,[bp]+10       ;obtener dirección del parámetro a
010E 03 04      add ax,[si]          ;sumar valor de a al valor de b
0110 8B 7E 06   mov di,[bp]+6        ;obtener dirección del parámetro c
0113 89 05      mov di,ax            ;almacenar suma en parámetro c
0115 5D         pop bp
0116 ca 00 06   ret 6
0119            usrprg endp
                                     ;Programa para poner el
                                     ;procedimiento en memoria
                                     ;y convertirlo en residente.
                                     ;El desplazamiento y el segmento se
                                     ;almacenan en la posición 100-103H.
0119            start1:
0119 B8 00 00   mov ax,0
011C 8E D8      mov ds,ax            ;segmento de datos a 0000H
011E BB 01 00   mov bx,0100H         ;puntero al vector de int. 100H
0121 83 7F 02 0 cmp word ptr [bx],0
0125 75 16      jne quit             ;programa ya ejecutado, salir
0127 83 3F 00   cmp word ptr2 [bx],0
012A 75 11      jne quit             ;programa ya ejecutado, salir
012C B8 01 03 R mov ax,offset usrprg
012F 89 07      mov [bx],ax          ;desplazamiento del programa
0131 8C c8      mov ax,cs
0133 89 47 02   mov [bx+2],ax        ;segmento de datos
0136 0E         push cs
0137 1F         pop ds
0138 BA 0141 R  mov dx,offset veryend
013B CD 27      int 27h
013D            quit:
013D CD 20      int 20h
013F            veryend:
013F            double ends
                end start
```

El ejemplo 2 sitúa la subrutina en lenguaje ensamblador en el área especificada:

#### Ejemplo 2

```vbnet
10 I=0:JC=0
100 DIM A%(23)
150 MEM%=VARPTR(A%(1))
200 FOR I=1 TO 23
300 READ JC
400 POKE MEM%,JC
450 MEM%=MEM%+1
500 NEXT
600 C1%=2:C2%=3:C3%=0
700 SUMARDOS=VARPTR(A%(1))
800 CALL SUMARDOS(C1%,C2%,C3%)
900 PRINT C3%
950 END
1000 DATA &H55,&H8b,&Hec &H8b,&H76,&H08,&H8b,&H04,&H8b,&H76
1100 DATA &H0a,&H03,&H04,&H8b,&H7e,&H06,&H89,&H05,&H5d
1200 DATA &Hca,&H06,&H00
```
