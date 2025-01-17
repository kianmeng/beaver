defmodule RegionTest do
  use Beaver.Case
  use Beaver
  alias Beaver.MLIR
  alias Beaver.MLIR.{Attribute, Type}
  alias Beaver.MLIR.Dialect.{Func, Arith, CF}
  require Func
  @moduletag :pdl

  test "multiple regions", test_context do
    op =
      mlir ctx: test_context[:ctx] do
        module do
          Func.func some_func(function_type: Type.function([], [Type.i(32)])) do
            region do
              block bb_entry() do
                v0 = Arith.constant(value: Attribute.integer(Type.i(32), 0)) >>> Type.i(32)
                cond0 = Arith.constant(true) >>> Type.i(1)
                CF.cond_br(cond0, Beaver.Env.block(bb1), {Beaver.Env.block(bb2), [v0]}) >>> []
              end

              block bb1() do
                v1 = Arith.constant(value: Attribute.integer(Type.i(32), 0)) >>> Type.i(32)
                _add = Arith.addi(v0, v0) >>> Type.i(32)
                CF.br({Beaver.Env.block(bb2), [v1]}) >>> []
              end

              block bb2(arg >>> Type.i(32)) do
                v2 = Arith.constant(value: Attribute.integer(Type.i(32), 0)) >>> Type.i(32)
                add = Arith.addi(arg, v2) >>> Type.i(32)
                Func.return(add) >>> []
              end
            end

            region do
              block bb1() do
                v0 = Arith.constant(value: Attribute.integer(Type.i(32), 0)) >>> Type.i(32)
                _v1 = Arith.constant(value: Attribute.integer(Type.i(32), 0)) >>> Type.i(32)
                _add = Arith.addi(v0, v0) >>> Type.i(32)
              end
            end
          end
        end
      end

    {_, [region_num]} =
      op
      |> Beaver.Walker.prewalk([], fn
        ir, acc ->
          with op = %Beaver.MLIR.Operation{} <- ir,
               "func.func" <- MLIR.Operation.name(op),
               region_num <- Beaver.Walker.regions(op) |> Enum.count() do
            {ir, [region_num | acc]}
          else
            _ -> {ir, acc}
          end
      end)

    assert region_num == 2
  end
end
