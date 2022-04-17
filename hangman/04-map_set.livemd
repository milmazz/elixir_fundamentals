# Hangman - MapSet

## Implementación previa

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  alias Hangman.GameLogic
  alias Hangman.View

  @doc """
  Starts the game
  """
  def start_game do
    word = "hangman"

    word
    |> GameLogic.init()
    |> View.format_response()
  end

  @doc """
  Lets the user to take a guess
  """
  def take_a_guess(letter, %{limit: limit, completed?: false} = state) when limit > 0 do
    letter
    |> String.downcase()
    |> GameLogic.guess(state)
    |> View.format_response()
  end

  def take_a_guess(_letter, state), do: View.format_response(state)
end
```

## MapSet

Si bien la lógica del juego, parece estar bien, aprovechemos este espacio para hacer unas pequeñas mejoras e introducir un nuevo concepto: `MapSet`.

Nota que anteriormente cuando determinamos `completed?`, estabamos separando la palabra en una lista de caracteres que luego usamos para verificar que cada letra se encuentraba en nuestra lista de `matches`. Pero una palabra puede tener la misma letra varias veces, entonces tiene sentido guardar valores únicos de dichas letras.

```elixir
defmodule Hangman.GameLogic do
  @moduledoc """
  Main logic for the game
  """

  @doc """
  Creates the initial game state
  """
  def init(word) do
    goal = word |> String.codepoints() |> MapSet.new()

    %{
      word: word,
      goal: goal,
      misses: MapSet.new(),
      matches: MapSet.new(),
      limit: 5,
      mask: "_",
      completed?: false
    }
  end

  @doc """
  Returns the game state after the user takes a guess
  """
  def guess(letter, state) do
    %{goal: goal, matches: matches, misses: misses, limit: limit} = state

    if MapSet.member?(goal, letter) do
      matches = MapSet.put(matches, letter)
      completed? = MapSet.equal?(matches, goal)
      %{state | matches: matches, completed?: completed?}
    else
      %{state | misses: MapSet.put(misses, letter), limit: limit - 1}
    end
  end
end
```

Pero antes de probar todo, debemos actualizar la capa de presentación para soportar la nueva estructura de datos.

```elixir
defmodule Hangman.View do
  @moduledoc """
  Presentation layer for the Hangman game
  """

  @doc """
  Returns a human-friendly response
  """
  def format_response(%{limit: limit, completed?: false} = state) when limit > 0 do
    {mask_word(state), state}
  end

  def format_response(%{limit: limit, word: word} = state) when limit > 0 do
    {"You won, word was: #{word}", state}
  end

  def format_response(%{word: word} = state) do
    {"Game Over, word was: #{word}", state}
  end

  ## Helpers
  defp mask_word(%{matches: matches, mask: mask, word: word} = _state) do
    if MapSet.size(matches) > 0 do
      matches = Enum.join(matches)
      String.replace(word, ~r/[^#{matches}]/, mask)
    else
      String.replace(word, ~r/./, mask)
    end
  end
end
```

Sin necesidad de cambiar nuestro punto de entrada o módulo principal, podemos hacer lo siguiente:

```elixir
{word, state} = Hangman.start_game()

Enum.reduce(["h", "a", "n", "g", "m"], state, fn letter, state ->
  {word, state} = Hangman.take_a_guess(letter, state)
  IO.inspect(word)
  state
end)

IO.puts("\nLets start a new game...\n")

{word, state} = Hangman.start_game()

Enum.reduce(["z", "q", "r", "i", "w", "p"], state, fn letter, state ->
  {word, state} = Hangman.take_a_guess(letter, state)
  IO.inspect(word)
  state
end)
```

### Retos

* Hasta este punto hemos venido manejando el estado como un mapa o diccionario. ¿Qué estructura de datos basada en mapas podríamos utilizar para obtener garantías en tiempo de compilación y la posibilidad de inyectar valores por omisión? Implementa los cambios necesarios para soportar la nueva estructura de datos.
* Nuestra lógica del juego tiene al menos un problema. Resulta que el nombre del argumento `letter` en nuestra función `Hangman.GameLogic.guess/2` es engañoso porque en realidad el jugador puede introducir cadenas de caracteres y no estamos generando un error en dicho caso. Pero dado que las reglas del juego permiten al jugador intentar adivinar la palabra u oración en cualquier momento, aprovechemos esta regla para mejorar nuestra lógica. De modo que al final debemos hacer _pattern matching_:

```
usuario suministra una letra -> seguimos usando `MapSet.member?(goal, letter)`
usuario suministra una palabra u oración -> hacemos otro tipo de comparación
```
