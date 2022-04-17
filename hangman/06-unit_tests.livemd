# Hangman - Unit Tests

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

## Unit Tests

Seguramente te has venido preguntando, ¿pero no debimos haber implementado las pruebas unitarias primero?, tienes razón, debimos haberlo hecho así, pero la idea por ahora era dar entender algunos conceptos de Elixir primero. Sin embargo, en esta sección vamos a corregir ese error, pasemos ahora a crear algunas pruebas unitarias.

```elixir
ExUnit.start(autorun: false)

defmodule HangmanTest do
  use ExUnit.Case, async: true

  describe "take_a_guess/2" do
    setup do
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
