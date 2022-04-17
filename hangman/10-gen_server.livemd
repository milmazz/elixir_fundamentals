# Hangman - GenServer

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

```elixir
defmodule Hangman.Goal.DummyGenerator do
  @behaviour Hangman.Goal.Api

  @impl true
  def generate do
    Enum.random(["hangman", "letterbox", "wheel of fortune"])
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
  @spec format_response(State.t()) :: String.t()
  def format_response(%State{limit: limit, completed?: false} = state) when limit > 0 do
    mask_word(state)
  end

  def format_response(%State{limit: limit, word: word}) when limit > 0 do
    "You won, word was: #{word}"
  end

  def format_response(%State{word: word}) do
    "Game Over, word was: #{word}"
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

## GenServer

### Introducción a `GenServer`

TODO

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """
  use GenServer

  alias Hangman.GameLogic
  alias Hangman.Goal
  alias Hangman.State
  alias Hangman.View

  ## Client
  @doc """
  Starts the game
  """
  @spec start_link(atom()) :: GenServer.on_start()
  def start_link(player) when is_atom(player) do
    GenServer.start_link(__MODULE__, player, name: player)
  end

  @doc """
  Returns the masked word
  """
  @spec get(atom() | pid()) :: String.t()
  def get(player) do
    player
    |> GenServer.call(:get)
    |> View.format_response()
  end

  @doc """
  Lets the user to take a guess
  """
  @spec take_a_guess(atom() | pid(), String.t()) :: String.t()
  def take_a_guess(player, letter) do
    player
    |> GenServer.call({:guess, letter})
    |> View.format_response()
  end

  @doc """
  Stops the game for the given player
  """
  def stop(player), do: GenServer.stop(player)

  ## Callbacks
  @impl GenServer
  def init(_player) do
    {:ok, State.new(Goal.generate())}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:guess, letter}, _from, state) do
    new_state =
      letter
      |> String.downcase()
      |> GameLogic.guess(state)

    {:reply, new_state, new_state}
  end
end
```

```elixir
player = :milton
{:ok, pid} = Hangman.start_link(player)
```

```elixir
Hangman.get(player)
```

```elixir
for letter <- ["h", "a", "n", "g", "m"] do
  Hangman.take_a_guess(player, letter)
end
```

```elixir
if Process.alive?(pid), do: Hangman.stop(player)
Hangman.start_link(player)

for letter <- ["z", "q", "p", "r", "y"] do
  Hangman.take_a_guess(player, letter)
end
```

```elixir
Hangman.stop(player)
```

Hasta ahora solo hemos demostrado que `Agent` es una abstracción construida encima de `GenServer`, pero no hemos aplicado los cambios sugeridos en el reto anterior, veamos si ahora podemos añadir soporte para expirar un sesión de juego.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """
  use GenServer

  alias Hangman.GameLogic
  alias Hangman.Goal
  alias Hangman.State
  alias Hangman.View

  require Logger

  @idle_timeout :timer.seconds(15)

  ## Client
  @doc """
  Starts the game
  """
  @spec start_link(atom()) :: GenServer.on_start()
  def start_link(player) when is_atom(player) do
    GenServer.start_link(__MODULE__, player, name: player)
  end

  @doc """
  Returns the masked word
  """
  @spec get(atom() | pid()) :: String.t()
  def get(player) do
    player
    |> GenServer.call(:get)
    |> View.format_response()
  end

  @doc """
  Lets the user to take a guess
  """
  @spec take_a_guess(atom() | pid(), String.t()) :: String.t()
  def take_a_guess(player, letter) do
    player
    |> GenServer.call({:guess, letter})
    |> View.format_response()
  end

  @doc """
  Stops the game for the given player
  """
  def stop(player), do: GenServer.stop(player)

  ## Callbacks
  @impl GenServer
  def init(player) do
    game_state = State.new(Goal.generate())
    {:ok, %{name: player, game_state: game_state}, @idle_timeout}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, Map.get(state, :game_state), state, @idle_timeout}
  end

  def handle_call({:guess, letter}, _from, %{game_state: game_state} = state) do
    new_game_state =
      letter
      |> String.downcase()
      |> GameLogic.guess(game_state)

    {:reply, new_game_state, %{state | game_state: new_game_state}, @idle_timeout}
  end

  @impl GenServer
  def handle_info(:timeout, %{name: player} = state) do
    Logger.info("Stopping game session for #{player}")
    {:stop, :normal, state}
  end
end
```

Ahora comencemos un nuevo juego y esperemos unos 15 segundos sin pasar ningún mensaje al proceso.

```elixir
Hangman.start_link(player)
```

Si después de recibir el mensaje _Stopping game session for..._ decidimos intentar jugando vamos a recibir un error porque el proceso ya no se encuentra activo.

```elixir
Hangman.get(player)
```

### Retos

Con los cambios previos demostramos que podemos expirar sesiones de juego. Sin embargo, podríamos mejorar la experiencia de usuario si guardamos el estado del juego en un medio persistente, de modo que si el jugador decide interactuar de nuevo con el servidor, el modulo `Hangman` verifica primero si tiene una sesión previa sin terminar, de existir dicha sesión, podríamos preguntarle al jugador si desea continuarla o si desea iniciar un nuevo juego. Si por el contrario, dicha sesión no existe, procedemos de inmediato a crear un nuevo juego.

Si quisieras evitarte tener que preguntarle al jugador si desea continuar o no con la sesión previa sin terminar, podrías cambiar el argumento esperado por `Hangman.start_link/1`. En vez de aceptar un átomo como argumento, podrías espera un _keyword list_ de la siguiente manera:

<!-- livebook:{"force_markdown":true} -->

```elixir
Hangman.start_link(player: :my_name, recover_session: true)
```

Si el jugador no indica el valor para `recover_session`, su valor por omisión será `false`. Recuerda que independientemente de la decisión del jugador, de existir, debes eliminar la sesión no concluida del medio persistente. Solo puede haber una sesión no concluida por jugador en el medio persistente, y debe ser la más reciente.
