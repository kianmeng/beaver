defmodule Beaver.MLIR.Dialect.CF do
  alias Beaver.MLIR
  require Beaver.MLIR.CAPI
  alias Beaver.MLIR.Dialect

  use Beaver.MLIR.Dialect,
    dialect: "cf",
    ops: Dialect.Registry.ops("cf") |> Enum.reject(fn x -> x in ~w{cond_br} end)

  defp sizes_of_block_args(arguments) do
    Enum.reduce(arguments, [], fn x, sizes ->
      case x do
        {%MLIR.CAPI.MlirBlock{}, block_args} when is_list(block_args) ->
          sizes ++ [length(block_args)]

        %MLIR.CAPI.MlirBlock{} ->
          sizes ++ [0]

        _ ->
          sizes
      end
    end)
  end

  @doc """
  Create cf.cond_br op. Passing atom will lead to defer the creation of this terminator.
  """
  def cond_br(%Beaver.DSL.SSA{arguments: arguments, block: block, ctx: ctx}) do
    sizes = sizes_of_block_args(arguments)

    if length(sizes) not in [1, 2] do
      raise "cond_br requires 1 or 2 successors, instead got: #{length(sizes)}"
    end

    # always prepend 1 for the condition operand
    operand_segment_sizes = [1 | sizes] |> MLIR.ODS.operand_segment_sizes()

    MLIR.Operation.create_and_append(
      ctx,
      "cf.cond_br",
      arguments ++ [operand_segment_sizes: operand_segment_sizes],
      block
    )
  end
end

require Beaver.MLIR.Dialect

Beaver.MLIR.Dialect.define_op_modules(
  Beaver.MLIR.Dialect.CF,
  "cf",
  Beaver.MLIR.Dialect.Registry.ops("cf")
)