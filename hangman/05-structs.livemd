# Hangman - Structs

## Structs

Hasta ahora hemos manejado un mapa como contenedor de nuestro estado, veamos el concepto de `struct` en Elixir.

Los _structs_ definen una estructura de datos con llaves o _keys_ predefinidas. Dichas llaves son verificadas en tiempo de compilación, esto quiere decir que si cometes un error al escribir el nombre de la llave (a.k.a _typo_), obtendrás un error por parte del compilador y podrás arreglarlo inmediatamente. Los _structs_ son definidos dentro de módulos, haciendo uso de la palabra reservada `defstruct` con una lista de átomos. Definamos la estructura `User` con campos `:name` y `:age`:

```elixir
defmodule User do
  defstruct [:name, :age]
end
```

Ahora, podemos crear estructuras usando la notación `%User{...}`

```elixir
user = %User{name: "John Connor", age: 37}
```

Podemos acceder a los campos de la estructura usando la sintaxis `struct.field`:

```elixir
user.name
```

También podemos aplicar _pattern matching_ sobre estructuras:

```elixir
%User{age: age} = user
age
```

Finalmente, veamos que pasa si cometemos un error al escribir un campo de una estructura:

```elixir
%User{agge: age} = user
```

Con toda esta introducción, ahora estamos listos para definir la estructura `Hangman.State`, la cual contendrá el estado de nuestro juego.

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
  @spec start_game() :: {String.t(), State.t()}
  def start_game do
    word = "hangman"

    word
    |> State.new()
    |> View.format_response()
  end

  @doc """
  Lets the user to take a guess
  """
  @spec take_a_guess(String.t(), State.t()) :: {String.t(), State.t()}
  def take_a_guess(letter, %State{limit: limit, completed?: false} = state) when limit > 0 do
    letter
    |> String.downcase()
    |> GameLogic.guess(state)
    |> View.format_response()
  end

  def take_a_guess(_letter, %State{} = state), do: View.format_response(state)
end
```

Con esto, ahora obtenemos varias garantías en tiempo de compilación, por ejemplo:

```elixir
%Hangman.State{}
```

Nota que además podemos inyectar valores por omisión.

```elixir
%Hangman.State{word: "word", goal: MapSet.new()}
```

Pasemos a actualizar nuestra vista y lógica del juego para manejar nuestra `struct`

```elixir
defmodule Hangman.GameLogic do
  @moduledoc """
  Main logic for the game
  """

  alias Hangman.State

  @doc """
  Returns the game state after the user takes a guess
  """
  @spec guess(String.t(), State.t()) :: State.t()
  def guess(letter, %State{} = state) do
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

```elixir
defmodule Hangman.View do
  @moduledoc """
  Presentation layer for the Hangman game
  """

  alias Hangman.State

  @doc """
  Returns a human-friendly response
  """
  @spec format_response(State.t()) :: {String.t(), State.t()}
  def format_response(%State{limit: limit, completed?: false} = state) when limit > 0 do
    {mask_word(state), state}
  end

  def format_response(%State{limit: limit, word: word} = state) when limit > 0 do
    {"You won, word was: #{word}", state}
  end

  def format_response(%State{word: word} = state) do
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

### Retos

* Hasta ahora todas nuestras pruebas que hemos hecho han sido manuales. Elixir incluye un _framework_ para desarrollo de pruebas unitarias llamado [`ExUnit`](https://hexdocs.pm/ex_unit/ExUnit.html). ¿Puedes generar algunas pruebas unitarias para nuestro proyecto?
* Si estás siguiendo este tutorial en Livebook y ya lo tienes instalado, revisa la sección _Explore_ y lee el cuaderno _Elixir and Livebook_, en dicho documento encontrarás una sección sobre como ejecutar pruebas unitarias en Livebook.
