# Hangman - Doctests

## Modulos requeridos

```elixir
defmodule Hangman.State do
  @moduledoc """
  The Hangman game state
  """

  @enforce_keys [:word, :goal]
  defstruct [
    :word,
    :goal,
    misses: MapSet.new(),
    matches: MapSet.new(),
    limit: 5,
    mask: "_",
    completed?: false
  ]

  @type t :: %__MODULE__{
          word: String.t(),
          goal: MapSet.t(),
          misses: MapSet.t(),
          matches: MapSet.t(),
          limit: pos_integer(),
          mask: String.t(),
          completed?: boolean()
        }

  @doc """
  Creates the initial game state
  """
  @spec new(String.t()) :: t()
  def new(word) when is_binary(word) do
    word = String.downcase(word)
    goal = word |> String.codepoints() |> MapSet.new()
    struct!(__MODULE__, word: word, goal: goal)
  end
end
```

## Doctests

Seguramente vienes notando que para documentar módulos usamos `@moduledoc` y para documentar funciones usamos `@doc`, la documentación dentro de dichos bloques debe seguir la sintaxis Markdown, una manera de asegurarnos que la documentación está actualizando es proveyendo _doctests_, como beneficio extra proveemos documentación con ejemplos de código correcto.

Los _doctests_ están especificados por una indentación de cuatro espacios seguidos de `iex>` prompt dentro de nuestra cadena de documentación. Si un comando se extiende más de una línea podemos usar `...>`, tal como lo hace `IEx`. El resultado esperado debe comenzar en la siguiente línea después de `iex>` o `...>` y termina tanto por un salto de línea o un nuevo prefijo `iex>`.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  alias Hangman.GameLogic
  alias Hangman.State
  alias Hangman.View

  @doc """
  Starts the game
  """
  def start_game do
    word = "hangman"

    word
    |> State.new()
    |> View.format_response()
  end

  @doc """
  Lets the user to take a guess

  ## Examples

      iex> {_word, state} = Hangman.start_game()
      iex> Hangman.take_a_guess("a", state) |> elem(0)
      "_a___a_"

  """
  def take_a_guess(letter, %State{limit: limit, completed?: false} = state) when limit > 0 do
    letter
    |> String.downcase()
    |> GameLogic.guess(state)
    |> View.format_response()
  end

  def take_a_guess(_, state), do: View.format_response(state)
end
```

Luego, dentro de nuestras pruebas unitarias podemos invocar el macro `doctest(module, opts)`, dicho macro generará casos de pruebas para nuestros doctests. Por ejemplo, en nuestro caso particular sería `doctest(Hangman)`. Para más información acerca de este macro puedes revisar su documentación [acá](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html#doctest/2).

El objetivo de los _doctests_ no es reemplazar las pruebas unitarias, si no más bien asegurarse que nuestra documentación está actualizada. Puedes leer más acerca de _doctests_ in la documentación ofrecida para [ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html).

### Retos

* Hasta ahora hemos creado pruebas unitarias para `Hangman`, ¿puedes crear pruebas unitarias para el resto de los módulos (e.g. `Hangman.GameLogic`, `Hangman.View`)?
* ¿Puedes añadir más _doctests_ donde lo creas conveniente?
