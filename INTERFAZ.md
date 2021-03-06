## Interfaz con intérprete de BASIC

La comunicación entre el intérprete de BASIC y un módulo ensamblador se realiza vía sentencia CALL del BASIC:

```VB
CALL nombre_subrutina(argumento1, argumento2, ...)
```

Las características de esta comunicación son:

- Los parámetros son opcionales. Si existen, se deben de corresponder en número y tipo con los del ensamblador.
- El control se transfiere a la dirección:
	- Segmento: el último especificado en DEF SEG
	- Desplazamiento: el especificado en CALL
- La llamada es de tipo FAR, es decir, se guada sobre la pila la dirección completa de retorno (seg. y despl.). El procedimiento principal de la subrutina ensamblador debe ser también FAR.
- El paso de argumentos en la llamada es mediante los desplazamientos (offsets) de cada variable.
- Para las variables tipo cadena de caracteres, el desplazamiento corresponde al descriptor de la cadena.
	Este descriptor tiene la estructura siguiente:
	- Byte 1: longitud de la cadena (0 a 255).
	- Bytes 2 y 3: desplazamiento (offset) de la cadena.
	> En el compilador BASIC, la longitud de la cadena es de 2 bytes. Cuando se recoge un parámetro de este tipo dentro de la subrutina ensamblador, es conveniente prepararla para que se pueda utilizar en ambos entornos de programación.
- En el módulo ensamblador la instrucción de retorno debe ser RET n, siendo n = 2 * número de parámetros.
- Los registros ES, CS y DS apuntan inicialmente al comienzo del segmento del BASIC. El registro CS se actualiza cada vez que se ejecuta una sentencia DEF SEG del BASIC.
- Los datos dentro del segmento del BASIC están direccionados mediante el registro de segmento DS.

## Interfaz con BASIC compilado

La comunicación entre un módulo BASCOM (IBM PC Basic Compiler) y un módulo ensamblador se realiza, como en el caso del intérprete de BASIC, mediante la sentencia:

```VB
CALL nombre_subrutina(argumento1, argumento2, ...)
```

Pero hay diferencias respecto al modo intérprete:

- El objeto del módulo ensamblador se incluye en la fase de montaje (LINK) del programa. Es decir, teóricamente ya no es necesario cargar el código objeto mediante POKE o BLOAD. Realmente se hace el uso normal de la capacidad del montador de crear un módulo ejecutable a partir de varios módulos objetos.
- El nombre de la subrutina debe declararse PUBLIC. Por su lado, la sentencia CALL genera un EXTRN idéntica a la que se usa en ensamblador.
- La manera en que se transmiten los argumentos es la misma que en modo intérprete, con la única diferencia de que el descriptor de la cadena tiene un campo de longitud de 2 bytes.
	Descriptor de cadena:
	- Bytes 1 y 2: longitud de la cadena (0 a 32767).
	- Bytes 3 y 4: desplazamiento (offset) de la cadena.
- Se puede también cargar un objeto ensamblador mediante BLOAD o POKE, pero no se puede utilizar esta forma de la sentencia CALL.
- Cuando el compilador BASIC inicializa las variables, pone a cero todos los segmentos que no tienen como nombre de clase "CODE". Con este nombre de clase nos aseguramos de que el módulo objeto del ensamblador se agrupará junto con el módulo objeto del BASIC compilado.