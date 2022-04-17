# Hangman - Responsabilidades

## Implementación previa

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

## Asignando responsabilidades

En la sección anterior, mencionamos que el módulo `Hangman`, tal como está, mezcla algunas responsabilidades. Por ejemplo, algunas funciones privadas solo se ocupan de la presentación de los datos, otras funciones privadas se ocupan de la lógica del juego en sí, vamos a separar dichas responsabilidades antes de continuar.

En principio definamos lo que de ahora en adelante vamos a llamar capa de presentación, también conocida como vista en algunos entornos.

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
  defp mask_word(%{matches: [], mask: mask, word: word} = _state) do
    String.replace(word, ~r/./, mask)
  end

  defp mask_word(%{matches: matches, mask: mask, word: word}) do
    matches = Enum.join(matches)
    String.replace(word, ~r/[^#{matches}]/, mask)
  end
end
```

Definamos la lógica principal del juego:

```elixir
defmodule Hangman.GameLogic do
  @moduledoc """
  Main logic for the game
  """

  @doc """
  Creates the initial game state
  """
  def init(word) do
    %{word: word, misses: [], matches: [], limit: 5, mask: "_", completed?: false}
  end

  @doc """
  Returns the game state after the user takes a guess
  """
  def guess(letter, state) do
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

Modifiquemos el módulo principal que tiene la función de director de orquesta

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

Nuestra implementación del juego ha sido organizado de la siguiente manera:

```mermaid
graph TD;
Hangman-->Hangman.View
Hangman-->Hangman.GameLogic
```

<!-- livebook:{"break_markdown":true} -->

Probemos que hemos mantenido la funcionalidad previa después de aplicar la separación de responsabilidades.

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

Después que hemos separado nuestra implementación, podemos introducir algunas pequeñas mejoras.

### Retos

* Si bien nuestro objetivo en este punto **no** es obtener el mayor rendimiento, ¿qué pequeño cambio podrías introducir para mejorar la lógica del juego?
* En la capa de presentación, en los pasos intermedios, parece que falta indicarle al jugador cuantos intentos le quedan disponibles, ¿puedes actualizar la salida que se le presenta al usuario?
