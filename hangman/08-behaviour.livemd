# Hangman - Behaviour

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

```elixir
defmodule Hangman.GameLogic do
  @moduledoc """
  Main logic for the game
  """

  alias Hangman.State

  @doc """
  Returns the game state after the user takes a guess

  ## Examples

      iex> state = Hangman.State.new("hangman")
      iex> guess("a", state)
      %Hangman.State{matches: MapSet.new(["a"]), word: "hangman", goal: MapSet.new(["a", "g", "h", "m", "n"])}

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

## Behaviour

Cuando dividimos la implementación del juego en diferentes módulos, cada uno con una responsabilidad, dejamos la "selección" de la palabra dentro de `Hangman.start_game/1`. Sin embargo, podríamos asumir que pueden haber diferentes maneras de proveer dicha palabra. Por ejemplo, la palabra puede provenir de un fichero, podríamos hacer una solicitud HTTP a otro servidor. Pareciese una buena oportunidad para definir el contrato que deben cumplir los adaptadores que intentan integrarse con nuestro juego. Otra ventaja de este cambio es que "empujamos" el _efecto secundario_ a un borde de nuestra aplicación. Veamos.

```elixir
defmodule Hangman.Goal.Api do
  @moduledoc """
  Word generator API
  """

  @doc """
  Generates a word, phrase, or sentence.
  """
  @callback generate() :: String.t()
end
```

Nuestro contrato define un único _callback_ por ahora, dicho _callback_ no recibe ningún argumento, pero debe retornar una cadena de caracteres. Que puede ser una palabra, frase o sentencia.

Vamos a implementar un módulo que safisface nuestro contrato.

```elixir
defmodule Hangman.Goal do
  @behaviour Hangman.Goal.Api
end
```

Como puedes notar nuestro módulo inicial no implementa de manera correcta el contrato, esto demuestra que existen validaciones en tiempo de compilación para ver si nuestros adaptadores implementan todas las funciones requeridas por el contrato. Vamos a resolver este error:

```elixir
defmodule Hangman.Goal do
  @moduledoc """
  Goal (word, phrase, sentence) generator entry point
  """
  @behaviour Hangman.Goal.Api

  @impl true
  def generate do
    client = Application.get_env(:hangman, :goal_generator, Hangman.Goal.DummyGenerator)
    client.generate()
  end
end
```

Nota que este implementación es solo una fachada que nos permitirá cambiar el generador de palabras, frases o sentencias en tiempo de ejecución o por ambiente, esto nos sera útil para cambiar la implementación cuando estemos ejecutando pruebas unitarias por ejemplo.

```elixir
defmodule Hangman.Goal.DummyGenerator do
  @behaviour Hangman.Goal.Api

  @impl true
  def generate do
    Enum.random(["hangman", "letterbox", "wheel of fortune"])
  end
end
```

Ahora tenemos un adaptador que hace cierto "trabajo" para conseguir la palabra que nuestro jugador tendrá que adivinar, veremos a continuación como hacer uso de estos adaptadores.

Actualicemos nuestro módulo de entrada.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """

  alias Hangman.GameLogic
  alias Hangman.Goal
  alias Hangman.State
  alias Hangman.View

  @doc """
  Starts the game
  """
  @spec start_game() :: {String.t(), State.t()}
  def start_game do
    Goal.generate()
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

Si ejecutamos varias veces la siguiente celda podremos observar que la palabra objetivo esta cambiando entre `letterbox`, `hangman`, o `wheel of fortune`.

```elixir
Hangman.start_game()
```

Pero el comportamiento aleatorio que ofrece `Hangman.Goal.DummyGenerator.generator/0` no nos sirve para pruebas unitarias, alli queremos controlar la palabra que generamos. Vamos a ver como podemos cambiar el generador cuando corremos pruebas unitarias.

```elixir
defmodule Hangman.Goal.TestGenerator do
  @behaviour Hangman.Goal.Api

  @impl true
  def generate, do: "hangman"
end

ExUnit.start(autorun: false)

defmodule HangmanTest do
  use ExUnit.Case, async: true

  describe "take_a_guess/2" do
    setup do
      original_generator = Application.get_env(:hangman, :goal_generator)
      Application.put_env(:hangman, :goal_generator, Hangman.Goal.TestGenerator)

      on_exit(fn ->
        if original_generator,
          do: Application.put_env(:hangman, :goal_generator, original_generator)
      end)

      {"_______", state} = Hangman.start_game()
      %{state: state}
    end

    test "announces when the user wins", %{state: state} do
      assert {"___g___", state} = Hangman.take_a_guess("g", state)
      assert {"_a_g_a_", state} = Hangman.take_a_guess("a", state)
      assert {"ha_g_a_", state} = Hangman.take_a_guess("h", state)
      assert {"hang_an", state} = Hangman.take_a_guess("n", state)

      assert {"You won, word was: hangman", %{completed?: true}} =
               Hangman.take_a_guess("m", state)
    end

    test "announces when the user loses", %{state: state} do
      assert {"_______", state} = Hangman.take_a_guess("z", %{state | limit: 2})
      assert {"Game Over, word was: hangman", _state} = Hangman.take_a_guess("q", state)
    end
  end
end

ExUnit.run()
```

En este punto, nuestra implementación está organizada más o menos como sigue:

```mermaid
graph TD;
H[Hangman]-->V[Hangman.View];
H-->L[Hangman.GameLogic];
H-->S[Hangman.State];
B[Hangman.Goal.Api]-->|implements| G;
H-->G[Hangman.Goal];
G-->A{adapter};
A-.->D[Hangman.Goal.DummyGenerator];
A-.->T[Hangman.Goal.TestGenerator];
```

<!-- livebook:{"break_markdown":true} -->

### Retos

* Nuestra implementación por omisión, `Hangman.Goal.DummyGenerator`, es bastante básica. Puedes intentar crear un adaptador alternativo que lea palabras desde un fichero de texto.
* Cambia la definición del contrato para que reemplace `generate/0` por `generate/1`, en donde el nuevo contrato acepte una lista de opciones, que por omisión está vacía, dicha lista de opciones puede ayudarnos a filtrar palabras por categorías o añadir cierto nivel de dificultad.
* Puedes intentar consumir los datos de un API abierto, como [Merriam-Webster Dictionary API](https://dictionaryapi.com), algunas alternativas al juego, ofrecen al definición de la palabra como pista, lo cual suele usarse para facilitar la enseñanza de un lenguaje extranjero.
