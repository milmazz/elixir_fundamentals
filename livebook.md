# LiveBook

En la clase pasada vimos como instalar Erlang y Elixir localmente. En esta
ocasión hablaremos e instalaremos [LiveBook](https://livebook.dev). Pero, ¿Qué es LiveBook?

LiveBook es una herramienta reciente en el ecosistema de Elixir y nos ofrece
una alternativa bien interesante, en ella podrás crear cuadernos o _notebooks_
con código Elixir. Es bastante útil para diseño rápido de prototipos, puedes
pensarlo como una mezcla de IEx o la consola interactiva de Elixir combinada
con tu editor. También puedes usar LiveBook para crear artículos que puedes
compartir fácilmente, las personas que lean tus artículos, pueden ejecutar tu
código, visualizarlo y en definitiva jugar con el, lo cual hace LiveBook
atractiva para aprender nuevos conceptos. 

Otro caso de uso para LiveBook, es cuando los autores de librerías deciden crear
cuadernos con tutoriales interactivos que pueden incluir en sus repositorios,
de modo que los usuarios puedan descargarlos y seguir dichos tutoriales paso a
paso.

En nuestras clases estaremos usando LiveBook, por lo que vamos a proceder a
instalarlo.

Para instalar LiveBook, tenemos varias alternativas. Por ejemplo, si no
quisieras instalarlo localmente, podrías usar el servicio de fly.io.

Nosotros lo vamos a instalar localmente, podemos hacerlo vía Docker, o dado que
ya hemos instalado Elixir, podríamos hacerlo a través de `mix`, el cual es una
herramienta para el manejo de proyectos en Elixir, siguiendo estos pasos.

```console
mix local.rebar --force && mix local.hex --force
mix escript.install hex livebook
fish_add_path ~/.mix/escripts/
livebook server --home ~/elixir_fundamentals
```

Llegados a este punto, vayamos al terminal y ejecutemos estos comandos.

```console
mix local.rebar --force && mix local.hex --force
```

Lo primero que hacemos es instalar `rebar` localmente, el cual es una
herramienta de construcción que facilita compilar y probar aplicaciones
Erlang. Al mismo tiempo instalamos localmente `hex`, el cual es un manejador de
paquetes para el ecosistema de Erlang.

Luego procedemos a instalar el escript de LiveBook disponible en Hex con el comando:

```console
mix escript.install hex livebook
```

Seguramente te estés preguntando que es un escript. Un escript en el ecosistema
de Erlang representa un ejecutable que puede ser invocado desde la linea de
comandos. Es importante resaltar que un escript puede correr en cualquier
maquina que tenga Erlang/OTP instalado y por omisión no requiere que Elixir
este instalado, porque Elixir es embebido como parte del escript.

Por conveniencia, se nos recomienda agregar `~/.mix/escripts` al PATH de nuestro
sistema, esto va a ser bien particular dependiendo de tu ambiente, pero en mi
caso que uso fish como shell, puedo usar el siguiente comando:

```console
fish_add_path ~/.mix/escripts/
```

Si no deseas agregar la ruta anterior a tu variable de entorno PATH, tendrás
que usar la ruta absoluta.

Ahora si, vamos a ejecutar el servidor local de LiveBook:

```console
livebook server --home ~/elixir_fundamentals
```

El comando previo nos indica que LiveBook ya se encuentra corriendo, vamos al
navegador para ver el resultado.

LiveBook por omisión incluye algunos cuadernos que te servirán como
introducción. Veamos rápidamente el cuaderno "Welcome to LiveBook", el concepto
principal acá es que cada cuadernos consiste en una serie de celdas, las cuales
funcionan como bloques de construcción.

Existen celdas Markdown que sirven para describir tu trabajo, así como también
hay celdas de código, las cuales ejecutan código Elixir.

Te dejo como reto que revises

Llegados acá, hagamos un repaso de lo aprendido en esta clase.

* Vimos LiveBook es una excelente alternativa en Elixir para diseñar prototipos rápidos
* Luego procedimos a instalarlo localmente
* Y finalmente comenzamos a explorar los cuadernos que vienen pre-instalados con LiveBook

Como reto te dejo instalar LiveBook, ejecutarlo localmente y finaliza la
exploración del cuaderno "Welcome to LiveBook", luego si gustas revisa el
cuaderno "Elixir and LiveBook" y comenta como te fue con tu exploración inicial
en nuestro sistema de comentarios.

Nos vemos en la próxima clase.
