defmodule Concat do
  def join(a, b) do
    IO.puts("first join")
    a <> b
  end

  def join(a, b, sep \\ " ") do
    IO.puts("second join")
    a <> sep <> b
  end
end
