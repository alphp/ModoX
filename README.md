[![](https://img.shields.io/github/license/alphp/ModoX.svg)](https://github.com/alphp/ModoX/blob/master/LICENSE)

# ModoX
Librería gráfica escrita en ensamblador para QB (QuickBasic, QBasic).

Para la documentación utilizaré C a modo de pseudocódigo.

Abril 1996

### Constantes utilizadas en las funciones
```C
#define VGA     0xA000	// VGA, Segmento de la memoria de video
#define ATC     0x3C0	// ATC, Registro índice/escritura
#define ATC1    0x3C1	// ATC, Registro de lectura
#define TSInd   0x3C4	// TS, Registro índice
#define TSDat   0x3C5	// TS, Registro de datos
#define DLP     0x3C7	// DAC, Dirección de lectura del pixel
#define DEP     0x3C8	// DAC, Dirección de escritura del pixel
#define VCP     0x3C9	// DAC, Valor del color del pixel
#define GDCInd  0x3CE	// GDC, Registro índice
#define GDCDat  0x3CF	// GDC, Registro de datos
#define CRTCInd 0x3D4	// CRTC, Registro índice
#define CRTCDat 0x3D5	// CRTC, Registro de datos
```

### Estructura de un Color RGB
```C
struct RGB
{
	unsigned char R, G, B;
};
```

### Estructura de un registro word con acceso directo al byte alto y bajo
```C
struct BReg
{
	unsigned char l, h;
};

union Reg
{
	unsigned int w;
	struct BReg b;
};
```

### Prototipos de las funciones
```C
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
```

## Establecer el Modo X

El Modo X no es más que un modo de trabajo no estándar de la VGA basado en el modo estándar 13h. Asi pues, para establecer el Modo X hay que llevar a cabo una serie de procesos que van modificando el modo de trabajo de la VGA hasta conseguir que esta trabaje con unas características tan peculiares que se han dado en llamar Modo X.
1. **Activar Modo 13h**: Activamos el Modo 13h de vídeo mediante la BIOS.
2. **Desactivar Modo Chain 4 y Modo Par/Impar**: El Modo Chain 4 utiliza los bits 0 y 1 de las direcciones para la selección del plano, tanto para escritura como para lectura. El Modo Par/Impar es similar al Modo Chain 4, aqui se utiliza el bit 0 de las direcciones para la selección de planos pares o impares.
3. **Desactivar Modo DoubleWord**: El Modo DoubleWord rota la dirección dos bits a la izquierda antes de enviarla a la memoria de vídeo para un acceso de lectura.
4. **Activar Modo Byte**: El Modo Byte permite el direccionamiento directo e individual de cada byte de la memoria de vídeo.

Ya solo queda borrar la pantalla (posiblemente llena de morralla) y empezar a disfrutar de nuestro recién establecido Modo X.
```C
// Activar Modo X
void ModoX (void)
{
	// Activar Modo 13h
	union REGS Registros;
	Registros.x.ax = 0x0013;
	int86 (0x10, &Registros, &Registros);

	// Desactivar Modo Chain 4 y Modo Par/Imar
	outportb (TSInd, 0x04);
	outportb (TSDat, (inportb (TSDat) & 0xF7) | 0x14);

	// Desactivar Modo DoubleWord
	outportb (CRTCInd, 0x14);
	outportb (CRTCDat, inportb (CRTCDat) & 0xBF);

	// Activar Modo Byte
	outportb (CRTCInd, 0x17);
	outportb (CRTCDat, inportb (CRTCDat) | 0x40);
};
```
## Establecer el Modo Texto

Para establecer el Modo Texto basta con llamar a la interrupción 10h, función 00h. Si piensas que para qué hace falta establecer el Modo Texto la respuesta es muy sencilla: después de jugar con el Modo X (que dicho sea de paso no es un modo estándar con lo que ello conlleva) habremos de volver al monótono Modo Texto para que las cosas vayan como deben.
```C
// Activar Modo Texto
void ModoTxt (void)
{
	// Activar Modo Texto
	union REGS Registros;
	Registros.x.ax = 0x0003;
	int86 (0x10, &Registros, &Registros);
};
```
## Establecer la Longitud de Línea

Es posible definir una longitud de línea distinta de la definida por el Modo 13h. Este modo define una longitud de línea de 320 bytes, la misma longitud de línea visible. Teóricamente podemos definir cualquier longitud de línea entre 0 y 2040 bytes, en la practica se establece un mínimo de 320 bytes y un máximo recomendado de unos 1300 bytes. Si definimos una línea mayor de 320 bytes el TRC no la visualizara entera, sino sólo 320 bytes, pero tendremos la posibilidad de realizar un Scroll visualizando la imagen como por una ventana deslizable. Si la longitud de la línea es menor de 320 bytes tendremos zonas de la pantalla que se “repiten”, lógicamente esto produce una “distorsión” que, en principio, no resulta interesante.

No tiene demasiada importancia cuando se define la línea, pero ha de ser obligatoriamente después de definir el Modo X y antes de “dibujar” el primer punto.

Para definir la longitud de la línea basta escribir el valor deseado en el registro CRTC 13h, teniendo en cuenta que se deberá especificar la longitud en Double Words, esto es, para una línea de 640 bytes tendremos 640 / 8 = 80 Double Words.
```C
// Definir longitud de línea
void PonLongLin (unsigned int Long)
{
	outportb (CRTCInd, 0x13);
	outportb (CRTCDat, Long / 8)
};

// Leer longitud de línea
unsigned int LeeLongLin (void)
{
	outportb (CRTCInd, 0x13);
	return (inportb (CRTCDat) * 8);
};
```
## Escribir un Pixel en Modo X
Escribir (“dibujar”) un pixel en el Modo X es un poco (¿sólo un poco?) más complicado que hacerlo en el Modo 13h. En el Modo 13h los pixels se representan por un byte, lo mismo que en el Modo X, pero se alinean de forma lineal puesto que se direccionan los cuatro planos de forma automática, resultando como contrapartida de la simplicidad el que una sóla página ocupa ya la practica totalidad de la memoria de video direccionable. En el Modo X el direccionamiento de los planos es manual, lo que implica el tener que seleccionar el plano al que pertenece el pixel antes de escribirlo, esta “contrariedad” nos da la ventaja de poseer cuatro páginas en la misma memoria de video direccionable que en el Modo 13h.

¿Cómo es esto?, bastante sencillo... cuando se llega a comprender. Partamos de la base, de lo que disponemos: tenemos cuatro planos independientes con 64Kb de memoria de video direccionable cada uno, esto da 256Kb de memoria de video o 4 páginas del conocido Modo 13h. Los pixels ya no se estructuran de forma alineada en memoria, pero para simplificar la explicación supongamos que los direccionamos del mismo modo que en el Modo 13h, esto nos da direcciones de 18 bits donde los dos bits inferiores nos indican el plano al que pertenece el pixel, y los dieciséis restantes nos indican el offset en la memoria de video (segmento de la memoria de video: A000h).
```C
// Escribir un Pixel en Modo X
void PonPixel (unsigned int x, unsigned int y, unsigned char Color)
{
	unsigned int Despl;
	unsigned char Plano;

	Plano = 1 << (x % 4);      // Los bits 1-0 indican el plano
	Despl = 160 * y + (x / 4); // Los bits 17-2 indican el offset

	outportb (TSInd, 0x02);    // El Registro TS 2 indica el Plano
	outportb (TSDat, Plano);   // de escritura con los bits 3-0
	pokeb (VGA, Despl, Color); // Escribimos en memoria el Pixel
};
```

## Leer un Pixel en Modo X
Leer un pixel en el ModoX es tan fácil (o complicado) como escribirlo, pero existen algunas diferencias. Las diferencias radican en el direccionamiento de los planos. Existen dos registros que direccionan los planos, el TS 2 y el GDC 4. El TS 2 direcciona los planos para la escritura, utiliza para ello los cuatro bits de menor peso representando cada uno de ellos la habilitación para la escritura de cada plano, así es posible escribir en varios planos al mismo tiempo. El GDC 4 direcciona los planos para la lectura, utiliza para ello los dos bits de menor peso representando como Integer de 2 bits el plano que se leerá, queda claro que no se pueden leer varios planos al mismo tiempo.
```C
// Leer un Pixel en Modo X
unsigned char LeePixel (unsigned int x, unsigned int y)
{
	unsigned int Despl;
	unsigned char Plano;

	Plano = x % 4;               // Los bits 1-0 indican el plano
	Despl = 160 * y + (x / 4);   // Los bits 17-2 indican el offset

	outportb (GDCInd, 0x04);     // El Registro GDC 4 indica el Plano
	outportb (GDCDat, Plano);    // de lectura con los bits 1-0
	return (peekb (VGA, Despl)); // Leemos en memoria el Pixel
};
```

## Borrar la pantalla en Modo X
Borrar la pantalla consiste simplemente en llenar la memoria de video con un mismo valor que normalmente corresponde al negro. Si pensamos que tenemos 256K pixels, hacer el borrado mediante la escritura de pixels (mediante la función PonPixel por ejemplo) se haría tan eterno que es una solución que ni se nos tiene que ocurrir.

Recordando como se escribe un pixel vemos que antes de direccionarlo hay que seleccionar el plano, pues bien, aquí es donde esta el truco del almendruco. El Registro TS 2 indica los planos de escritura mediante los bits 3-0, así si el bit 0 esta activo, se escribirá en el plano 0; si el bit 1 esta activo, se escribirá en el plano 1; y así con el bit y el plano 2 y 3. Si activamos al mismo tiempo dos o más bits/planos tendremos que escribiremos en dos o más planos al mismo tiempo. Activando los cuatro planos al mismo tiempo tendremos que borrar sólo 64K pixels, es decir la cuarta parte que antes.

Y puesto que no nos importa que coordenadas representa cada dirección podemos simplificar al máximo la escritura de cada pixel puesto que no tenemos que calcular el desplazamiento, basta con indicarlo directamente.
```C
// Borrar la pantalla en Modo X
void ClsX (void)
{
	unsigned int n;

	// Activamos los cuatro planos para la escritura
	outportb (TSInd, 0x02);
	outportb (TSDat, 0x0F);

	// Borramos la memoria de video (Color 0)
	for(n = 0; n < 0xFFFF; n++)
	{
		pokeb(VGA, n, 0);
	}
};
```

## Establecer 200 ó 400 líneas
La VGA estándar sólo puede representar resoluciones de 350, 400 ó 480 líneas, así que para representar resoluciones de 200 líneas lo que hace es duplicar cada línea con lo que obtiene 400 / 2 = 200 líneas visualizadas. El registro CRTC 9 indica en su bit de más peso si se han de duplicar o no las líneas, y en los cinco bits de menor peso el número de copias extra de cada línea. Para pasar al modo de 400 líneas habrá que borrar los bits 7 y 4-0 del registro CRTC 9, mientras que para volver al modo de 200 líneas podemos activar unicamente el bit 7 o bien activar sólo el bit 0.
```C
// Establecer 400 líneas
void Modo400Lin (void)
{
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) & 0x70)
};

// Establecer 200 líneas
void Modo200Lin (void)
{
	outportb (CRTCInd, 0x09);
	outportb (CRTCDat, inportb (CRTCDat) | 0x80)
};
```

## Los Colores
Tanto la teoría como la practica de los colores son idénticas para el Modo X y el Modo 13h. Lo fundamental de este tema no es sino la teoría tricromática, que dice algo así como que todos los colores se pueden obtener a partir de mezclas de tres únicos colores base. Esto que parece muy simple no lo es tanto. Primero habrá que saber que tipo de mezcla vamos a realizar: aditiva (suma de intensidades luminosas) o sustractiva (resta de intensidades luminosas). Dependiendo del tipo de mezcla, los colores base serán unos u otros.

|Mezcla      |Colores base                   |
|------------|-------------------------------|
|Aditiva     | RGB (Rojo, Verde, Azul)       |
|Sustractiva | CMY (Cian, Magenta, Amarillo) |

Pensando un poco nos damos cuenta que un monitor emite luz, y por tanto la mezcla que produce es aditiva, así que los colores base que utilizaremos serán el Rojo (R), el Verde (G) y el Azul (B). Representando cada una de las componentes del color por un byte obtenemos 256 combinaciones de cada componente, que combinadas entre si nos dan un total de 16M colores. Pero para nuestra desgracia de los ocho bits que componen un byte sólo se utilizan los seis de menor peso, con lo que obtenemos 64 combinaciones por componente y 256K colores. Y aquí no se acaban los males, para representar 256K colores hace falta un registro de 18 bits, lo cual no es posible, por lo que se representa cada color por un byte, lo que da como resultado el que sólo se pueden visualizar simultáneamente 256 colores de los 256K posibles.

Todo esto queda materializado en una paleta de 256 registros triples, algo así como un array de 256 registros de 18 bits cada uno. De esta forma se pueden representar 256 colores de las 256K tonalidades posibles con 18 bits (tres registros de 6 bits).

Y la cosa funciona más o menos asi: el DAC (Convertidor Digital/Analógico) lee de la memoria el número de color a representar, obtiene de la paleta las componentes RGB y forma la señal de color que el TRC (Tubo de Rayos Catódicos) se encarga de visualizar.

Es posible leer y escribir la paleta de la VGA, para ello contamos con tres registros: dos índices y uno de datos. Los registros índice nos permiten indicar al DAC el color que queremos leer (DLP) o escribir (DEP). El registro de datos (VCP) nos permite leer o escribir el valor de las tres componentes del color. Dada la disposición de la paleta en memoria, se han de leer o escribir las componentes en el orden Rojo, Verde y Azul, siendo la siguiente lectura o escritura la de la componente Roja del siguiente color.

Para leer o escribir toda la paleta basta con repetir las operaciones de lectura/escritura para los 256 colores. Como en el caso del ClsX hay una vía fácil y lenta, y otra rápida y más sencilla si cabe.

La primera opción seria utilizar una de las dos funciones anteriores (la que corresponda) dentro de un bucle, mientras que la segunda es comenzar la operación en el color cero y leer 256 veces seguidas las tres componentes, sabiendo que cada trió corresponde a un color. La velocidad es tal que ni siquiera se aprecia parpadeo alguno al realizar la escritura de toda la paleta.

```C
// Leer un color
void LeeColor (unsigned char n, struct RGB *Color)
{
	outportb (DLP, n);        // Leemos el color número n
	Color->R = inportb (VCP); // Primero el Rojo (R)
	Color->G = inportb (VCP); // Segundo el Verde (G)
	Color->B = inportb (VCP); // Tercero el Azul (B)
};

// Escribir un color
void PonColor (unsigned char n, struct RGB Color)
{
	outportb (DEP, n);       // Escribimos el color número n
	outportb (VCP, Color.R); // Primero el Rojo (R)
	outportb (VCP, Color.G); // Segundo el Verde (G)
	outportb (VCP, Color.B); // Tercero el Azul (B)
};

// Leer la paleta
void LeePaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DLP, 0);              // Comenzamos por el color 0
	for (n = 0; n < 256; n++)
	{
		Pal[n].R = inportb (VCP); // Primero el Rojo (R)
		Pal[n].G = inportb (VCP); // Segundo el Verde (G)
		Pal[n].B = inportb (VCP); // Tercero el Azul (B)
	}
};

// Escribir la paleta
void PonPaleta (struct RGB Pal[])
{
	unsigned int n;

	outportb (DEP, 0);              // Comenzamos por el color 0
	for (n = 0; n < 256; n++)
	{
		outportb (VCP, Pal[n].R); // Primero el Rojo (R)
		outportb (VCP, Pal[n].G); // Segundo el Verde (G)
		outportb (VCP, Pal[n].B); // Tercero el Azul (B)
	}
};
```

## Scroll Gráfico en Modo X:

Al disponer de 256Kb de memoria de video es teóricamente posible cargar una imagen de 640x409 puntos, para lo cual bastara con definir la longitud de la línea en 640 puntos. Tendremos que imaginarnos, en este caso, que tenemos ante nosotros una ventana que nos permite ver sólo una parte del paisage. El efecto denominado Scroll consiste en desplazar esa ventana para poder visualizar otras partes de la memoria, como si pudieramos desplazar la ventana de nuestra imaginaria habitación para poder ver otra parte del horizonte.

Para poder desplazar nuestra ventana, disponemos de dos registros:
- Dirección de inicio de línea (CRTC 0Ch:CRTC 0Dh)
- Panning de Píxeles Horizontal (ATC 13h)

La dirección de inicio de línea índica el desplazamiento dentro de la memoria de video en la cual el CRTC comienza la lectura de los datos. El registro CRTC 0Ch es el byte alto y el registro CRTC 0Dh es el byte bajo del desplazamiento. Si la dirección de inicio de línea es cero, tendremos que la esquina superior izquierda de la pantalla representa las coordenadas 0,0 del dibujo en memoria. Si incrementamos este valor en una longitud de línea, es decir en 640 / 4 = 160 bytes, la esquina superior izquierda representara las coordenadas 0,1.

Existe un probrema, el scroll vertical se puede realizar línea a línea, pero resulta imposible realizar un scroll horizontal pixel a pixel mediante este metodo. Esto es debido a que sólo controlamos el desplazamiento, me explico: el CRTC mira la dirección de inicio de línea para averiguar en que posición debe comenzar la lectura de los pixels a representar, asi, si lee un desplazamiento igual a 1, leera el byte 1 del plano 0 y lo representa, luego el byte 1 del plano 1, y asi con el resto de los planos. Si el desplazamiento es igual a 2, el CRTC comenzara la representación de los pixels a partir del byte 2 del plano 0, es decir, cuatro pixels horizontales más a la derecha.

Para solventar este inconveniente la VGA posee un registro denominado panning de pixels horizontal (ATC 13h). Este registro, para el modo X y cómo simplificación, indica el plano por el cual se va a iniciar la representación de los pixels. De esta forma, con un desplazamiento igual a 0 y con un panning igual a 1, el CRTC comenzara la representación a partir del byte 0 del plano 1, consiguiendo de esta forma un scroll horizontal de un pixel.

El cálculo de la dirección de inicio es el siguiente: Dir.Ini. = (LongLin / 4) * y + (x / 4).

El cálculo del panning horizontal es el siguiente: Panning = x MOD 4

```C
// Scroll Gráfico en Modo X:
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
```

## Scrooll en Modo Texto:

La idea de poder desplazar el texto de la misma forma que los gráficos es genial. Gracias a la posibilidad de poder definir los bytes que contiene una línea, podemos tener pantallas de texto virtuales de 160x102 caracteres. Como ocurria en el Modo X, la pantalla actua como una ventana de 80x25 caracteres que sera desplazada por la memoria para visualizar las diferentes partes del texto.

En este caso el scroll que se consigue mediante la dirección de inicio de línea es de caracteres, es decir, el minimo desplazamiento omnidireccional es de un caracter. Esto es asi por la distribución del modo de texto. En el modo texto cada byte representa un caracter, un conjunto de pixels (9x16 pixels en el Modo 03h).

Para realizar un scroll más fino, de pixels, es necesario recurrir como en el caso anterior al panning horizontal (ATC 13h) y ademas al panning vertical (CRTC 08h). En este caso, estos registros indican cuantos pixels ha de desplazarse la visualización hacia la izquierda y hacia arriba.

El cálculo de los valores es como sigue:
- Dir.Ini. = (LongLin / 4) * (y / 16) + (x / 9)
- Pan.Hor. = (x MOD 9) - 1
- Pan.Ver. = (y MOD 16)

```C
// Scrooll en Modo Texto:
void ScrollTxt (unsigned int x, unsigned int y)
{
	union Reg n;

	// Calculamos el desplazamiento en bytes
	n.w = (LeeLongLin () / 4) * (y / 16) + (x / 9);

	do {} while (inportb(ISR1) & 0x08);

	// Realizamos el Scroll en bytes
	outportb (CRTCInd, 0x0C);    // Dir. de inicio de línea (parte alta)
	outportb (CRTCDat, n.b.h);
	outportb (CRTCInd, 0x0D);    // Dir. de inicio de línea (parte baja)
	outportb (CRTCDat, n.b.l);

	do {} while (~inportb(ISR1) & 0x08);

	// Realizamos el Scroll en pixels
	outportb (CRTCInd, 0x08);    // Panning Vertical
	outportb (CRTCDat, y % 16);

	outportb (ATC, 0x13 | 0x20); // Panning Horizontal
	outportb (ATC, ((x % 9) -1) | 0x20);
};
```

## El Modo 13h
Vamos a conocer la estructura del Modo 13h ya que ofrece unas posibilidades excelentes para gráficos en color y por que en el se basa el Modo X.

El Modo 13h ofrece una resolución de 320x200 con 256 colores, asi pues cada pixel está representado por un byte. Los pixels en la pantalla se estructuran en 200 lineas de 320 pixels cada una. En memoria la pantalla (los pixels) se “dibuja” en el segmento A000h, esto es asi por que una página (una pantalla) de 320x200 pixels nos da un total de 64000 pixels (bytes) y un segmento tiene un tamaño de 64Kb, así que disponemos de 1.5Kb extras para almacenar sprites (trozos de imagen). La estructura de los pixels en memoria es muy simple, estos están alineados en la memoria a partir de la dirección A0000h (segmento A000h, desplazamiento u offset 0000h), asi la primera línea ocupara las posiciones de memoria A0000h-A013Fh, la siguiente esta en A0140h-A027Fh y asi hasta la última línea. Pensando un poco puede llegarse a la siguiente expresión para calcular el desplazamiento de un pixel dadas sus coordenadas: Despl = 320 * y + x.

Para acceder al Modo 13h y aprovecharse de sus posibilidades no hay otro medio que utilizar la interrupción 10h, función 00h, de la ROM BIOS.
```C
// Activar Modo 13h
void Modo13h (void)
{
	// Activar Modo 13h
	union REGS Registros;
	Registros.x.ax = 0x0013;
	int86 (0x10, &Registros, &Registros);
};
```
