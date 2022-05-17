# Hangman - Inicio

## Acerca del juego

De acuerdo a Wikipedia, tenemos que el juego del _ahorcado_ o _colgado_ es:

> un juego de adivinanzas de lápiz y papel para dos o más jugadores. Un jugador piensa en una palabra, frase u oración y el otro trata de adivinarla según lo que sugiere por letras o dentro de un cierto número de oportunidades.

Nuestro objetivo es implementar dicho juego haciendo uso de Elixir.

## El inicio

Siempre que querramos encapsular lógica en Elixir, debemos crear modulos, los cuales en esencia son una colección de funciones, tanto públicas como privadas. Podemos definir un nuevo modulo con `defmodule` y las funciones públicas con `def`, para definir funciones privadas usamos `defp`.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_"}
  end
end
```

Una vez definido nuestro módulo y función inicial, vamos a ejecutarlo.

```elixir
Hangman.start_game()
```

Vemos que retornamos el estado del juego contenido en un mapa, el cual usaremos para mantener nuestras funciones puras. Si bien no tiene mucho sentido hacerle saber al cliente el estado del juego, vamos a hacerlo así por ahora, más adelante esperemos ocultar dicho estado.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    state = %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_"}
    {mask_word(state), state}
  end

  ## Helpers
  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end
end
```

```elixir
{word, state} = Hangman.start_game()
```

Nota que la salida muestra ahora la palabra enmascarada tal como pide el juego, no te preocupes por el estado como mencionamos previamente.
Definamos ahora una función que facilite al usuario ingresar una letra para tratar de adivinar la palabra.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    state = %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_"}
    {mask_word(state), state}
  end

  @doc """
  Lets the user to take a guess
  """
  def take_a_guess(letter, state) do
    state = guess(letter, state)
    {mask_word(state), state}
  end

  ## Helpers
  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end

  defp guess(letter, state) do
    %{word: word, matches: matches, misses: misses, limit: limit} = state

    if String.contains?(word, letter) do
      %{state | matches: [letter | matches]}
    else
      %{state | misses: [letter | misses], limit: limit - 1}
    end
  end
end
```

```elixir
{word, state} = Hangman.start_game()
{word, state} = Hangman.take_a_guess("h", state)
```

En este punto puedes notar que el estado parece correcto, pero estamos obteniendo una excepción `FunctionClauseError` para nuestra función privada `mask_word/1`. Resulta que nuestra función privada solo es capaz de enmascarar palabras cuando no hay ningún acierto, vamos a actualizarla para manejar este nuevo escenario.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    state = %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_"}
    {mask_word(state), state}
  end

  @doc """
  Lets the user to take a guess
  """
  def take_a_guess(letter, state) do
    state = guess(letter, state)
    {mask_word(state), state}
  end

  ## Helpers
  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end

  defp mask_word(%{matches: matches, mask: mask, word: word}) do
    matches = Enum.join(matches)
    String.replace(word, ~r/[^#{matches}]/, mask)
  end

  defp guess(letter, state) do
    %{word: word, matches: matches, misses: misses, limit: limit} = state

    if String.contains?(word, letter) do
      %{state | matches: [letter | matches]}
    else
      %{state | misses: [letter | misses], limit: limit - 1}
    end
  end
end
```

```elixir
{word, state} = Hangman.start_game()
{word, state} = Hangman.take_a_guess("a", state)
```

```elixir
{word, state} = Hangman.take_a_guess("h", state) |> tap(fn {word, _} -> IO.inspect(word) end)
{word, state} = Hangman.take_a_guess("n", state) |> tap(fn {word, _} -> IO.inspect(word) end)
{word, state} = Hangman.take_a_guess("m", state) |> tap(fn {word, _} -> IO.inspect(word) end)
{word, state} = Hangman.take_a_guess("g", state)
```

Ok, parece que funciona, ahora, ¿qué pasa si el usuario alcanza el límite de cinco intentos?

```elixir
{word, state} = Hangman.start_game()

Enum.reduce(["z", "q", "r", "i", "w", "p"], state, fn letter, state ->
  {word, state} = Hangman.take_a_guess(letter, state)
  IO.inspect(word)
  state
end)
```

Algo no está bien, manejemos esta situación.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    state = %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_"}
    {mask_word(state), state}
  end

  @doc """
  Lets the user to take a guess
  """
  def take_a_guess(letter, %{limit: limit} = state) when limit > 0 do
    letter
    |> String.downcase()
    |> guess(state)
    |> format_response()
  end

  def take_a_guess(_letter, state), do: format_response(state)

  ## Helpers
  defp format_response(%{limit: limit} = state) when limit > 0 do
    {mask_word(state), state}
  end

  defp format_response(%{word: word} = state) do
    {"Game Over, word was: #{word}", state}
  end

  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end

  defp mask_word(%{matches: matches, mask: mask, word: word}) do
    matches = Enum.join(matches)
    String.replace(word, ~r/[^#{matches}]/, mask)
  end

  defp guess(letter, state) do
    %{word: word, matches: matches, misses: misses, limit: limit} = state

    if String.contains?(word, letter) do
      %{state | matches: [letter | matches]}
    else
      %{state | misses: [letter | misses], limit: limit - 1}
    end
  end
end
```

```elixir
{word, state} = Hangman.start_game()

Enum.reduce(["z", "q", "r", "i", "w", "p"], state, fn letter, state ->
  {word, state} = Hangman.take_a_guess(letter, state)
  IO.inspect(word)
  state
end)
```

Una vez llegamos al limite de intentos permitidos, le decimos al usuario que ha perdido. Solo nos falta decirle cuando ha ganado, ¿verdad?

Introduzcamos una nueva clave o _key_ en nuestro mapa para indicar si el usuario ha completado la palabra.

## Finalizando nuestro juego inicial

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  @doc """
  Starts the game
  """
  def start_game do
    state = %{word: "hangman", misses: [], matches: [], limit: 5, mask: "_", completed?: false}
    {mask_word(state), state}
  end

  @doc """
  Lets the user to take a guess
  """
  def take_a_guess(letter, %{limit: limit, completed?: false} = state) when limit > 0 do
    letter
    |> String.downcase()
    |> guess(state)
    |> format_response()
  end

  def take_a_guess(_letter, state), do: format_response(state)

  ## Helpers
  defp format_response(%{limit: limit, completed?: false} = state) when limit > 0 do
    {mask_word(state), state}
  end

  defp format_response(%{limit: limit, word: word} = state) when limit > 0 do
    {"You won, word was: #{word}", state}
  end

  defp format_response(%{word: word} = state) do
    {"Game Over, word was: #{word}", state}
  end

  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end

  defp mask_word(%{matches: matches, mask: mask, word: word}) do
    matches = Enum.join(matches)
    String.replace(word, ~r/[^#{matches}]/, mask)
  end

  defp guess(letter, state) do
    %{word: word, matches: matches, misses: misses, limit: limit} = state

    if String.contains?(word, letter) do
      matches = [letter | matches]
      completed? = word |> String.codepoints() |> Enum.all?(&(&1 in matches))
      %{state | matches: matches, completed?: completed?}
    else
      %{state | misses: [letter | misses], limit: limit - 1}
    end
  end
end
```

```elixir
{word, state} = Hangman.start_game()

Enum.reduce(["h", "a", "n", "g", "m"], state, fn letter, state ->
  {word, state} = Hangman.take_a_guess(letter, state)
  IO.inspect(word)
  state
end)
```

```elixir
{word, state} = Hangman.start_game()
```

```elixir
{word, state} = Hangman.take_a_guess("h", state)
```

```elixir
{word, state} = Hangman.take_a_guess("a", state)
```

```elixir
{word, state} = Hangman.take_a_guess("n", state)
```

```elixir
{word, state} = Hangman.take_a_guess("g", state)
```

```elixir
{word, state} = Hangman.take_a_guess("m", state)
```

Si bien parece que nos estamos acercando a una implementación sólida del juego, nota que estamos mezclando varias responsabilidades en un solo módulo.

### Retos

* ¿Puedes separar el módulo `Hangman`?
* ¿Cómo lo harías?, ¿existe algún patron que nos ayude a tomar nuestra decisión?
* ¿Cuáles son las distintas reponsibilidades que notas?
* Crees que al separar el módulo original en múltiples piezas, ¿el resultado final sea más fácil de leer y mantener?
* Nuestra función `mask_word/1` hace uso de `String.replace` y expresiones regulares. Crea una versión alternativa evitando hacer eso, puedes crear funciones privadas que te ayuden a resolver el problema, ¿tal vez una función recursiva pueda ayudarnos?
