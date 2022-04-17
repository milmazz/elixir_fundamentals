# Hangman - Protocols

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

## Protocols

### Introducción

TODO

```elixir
defimpl Inspect, for: Hangman.State do
  def inspect(%Hangman.State{limit: limit, completed?: false} = state, _opts) when limit > 0 do
    "#{mask_word(state)}, remaining attempts: #{limit}"
  end

  def inspect(%Hangman.State{limit: limit, word: word}, _opts) when limit > 0 do
    "You won, word was: #{word}"
  end

  def inspect(%Hangman.State{word: word}, _opts) do
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

Tras implementar el protocolo previo, podemos eliminar el modulo `Hangman.View` y las referencias al mismo.

```elixir
defmodule Hangman do
  @moduledoc """
  The famous Hangman game
  """
  use GenServer

  alias Hangman.GameLogic
  alias Hangman.Goal
  alias Hangman.State

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
    GenServer.call(player, :get)
  end

  @doc """
  Lets the user to take a guess
  """
  @spec take_a_guess(atom() | pid(), String.t()) :: String.t()
  def take_a_guess(player, letter) do
    GenServer.call(player, {:guess, letter})
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

```elixir
player = :milton
{:ok, pid} = Hangman.start_link(player)
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

for letter <- ["q", "w", "e", "r", "t"] do
  Hangman.take_a_guess(player, letter)
end
```
