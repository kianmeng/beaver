defmodule Beaver.MLIR.Context do
  alias Beaver.MLIR

  @doc """
  create a MLIR context and register all dialects
  """
  def create(allow_unregistered: allow_unregistered) do
    ctx = MLIR.CAPI.mlirContextCreate()
    MLIR.CAPI.mlirRegisterAllDialects(ctx)
    MLIR.CAPI.mlirContextSetAllowUnregisteredDialects(ctx, allow_unregistered)
    ctx |> Exotic.Value.transmit()
  end

  def create() do
    create(allow_unregistered: false)
  end
end