defmodule Beaver.MLIR.Operation do
  alias Beaver.MLIR
  alias Beaver.MLIR.CAPI
  import Beaver.MLIR.CAPI
  require Logger

  @doc """
  Create a new operation from a operation state
  """
  def create(state) do
    state |> Exotic.Value.get_ptr() |> MLIR.CAPI.mlirOperationCreate()
  end

  @doc """
  Create a new operation from arguments and insert to managed insertion point
  """
  def create(op_name, %Beaver.DSL.SSA{arguments: arguments, results: results, filler: filler})
      when is_function(filler, 0) do
    create(op_name, arguments ++ [result_types: results, regions: filler])
  end

  def create(op_name, %Beaver.DSL.SSA{arguments: arguments, results: results}) do
    create(op_name, arguments ++ [result_types: results])
  end

  def create(op_name, %Beaver.DSL.Op.Prototype{
        operands: operands,
        attributes: attributes,
        results: results
      }) do
    create(op_name, operands ++ attributes ++ [result_types: results])
  end

  def create(op_name, arguments) do
    defer_if_terminator = Keyword.get(arguments, :defer_if_terminator, true)

    if defer_if_terminator and MLIR.Trait.is_terminator?(op_name) do
      if block = MLIR.Managed.Block.get() do
        Beaver.MLIR.Managed.Terminator.defer(fn ->
          op = do_create(op_name, arguments)
          Beaver.MLIR.CAPI.mlirBlockAppendOwnedOperation(block, op)
        end)

        {:deferred, {op_name, arguments}}
      else
        raise "deferred terminator creation requires a block"
      end
    else
      op = do_create(op_name, arguments)

      if block = MLIR.Managed.Block.get() do
        Beaver.MLIR.CAPI.mlirBlockAppendOwnedOperation(block, op)
      end

      op
    end
  end

  def results(%MLIR.CAPI.MlirOperation{} = op) do
    case CAPI.mlirOperationGetNumResults(op) |> Exotic.Value.extract() do
      0 ->
        op

      1 ->
        CAPI.mlirOperationGetResult(op, 0)

      n when n > 1 ->
        for i <- 0..(n - 1)//1 do
          CAPI.mlirOperationGetResult(op, i)
        end
    end
  end

  defp do_create(op_name, arguments) when is_binary(op_name) and is_list(arguments) do
    location = MLIR.Managed.Location.get()

    state = MLIR.Operation.State.get!(op_name, location)

    for argument <- arguments do
      MLIR.Operation.State.add_argument(state, argument)
    end

    state
    |> MLIR.Operation.create()
  end

  @doc """
  Print operation to a Elixir `String`. This function could be very expensive. It is recommended to use it at compile-time or debugging.
  """
  def to_string(operation) do
    string_ref_callback_closure = MLIR.StringRef.Callback.create()

    MLIR.CAPI.mlirOperationPrint(
      operation,
      Exotic.Value.as_ptr(string_ref_callback_closure),
      Exotic.Value.Ptr.null()
    )

    string_ref_callback_closure
    |> MLIR.StringRef.Callback.collect_and_destroy()
  end

  @default_verify_opts [dump: false, dump_if_fail: false]
  def verify!(op, opts \\ @default_verify_opts) do
    with {:ok, op} <-
           verify(op, opts ++ [should_raise: true]) do
      op
    else
      :fail -> raise "MLIR operation verification failed"
    end
  end

  def verify(op, opts \\ @default_verify_opts) do
    dump = opts |> Keyword.get(:dump, false)
    dump_if_fail = opts |> Keyword.get(:dump_if_fail, false)
    is_success = MLIR.CAPI.mlirOperationVerify(op) |> Exotic.Value.extract()

    if dump do
      Logger.warning("Start dumping op not verified. This might crash.")
      dump(op)
    end

    if is_success do
      {:ok, op}
    else
      if dump_if_fail do
        Logger.warning("Start dumping op failed to pass the verification. This might crash.")
        dump(op)
      end

      :fail
    end
  end

  def dump(op) do
    mlirOperationDump(op)
    op
  end

  @doc """
  Verify the op and dump it. It raises if the verification fails.
  """
  def dump!(op) do
    verify!(op)
    mlirOperationDump(op)
    op
  end
end