defmodule Beaver.MLIR.StringRef do
  alias Beaver.MLIR.CAPI

  @moduledoc """
  StringRef is very commom in LLVM projects. It is a wrapper of a C string. This function will create a Elixir owned C string from a Elixir bitstring and create a StringRef from it. StringRef will keep a reference to the C string to prevent it from being garbage collected by BEAM.
  """
  def create(value) when is_binary(value) do
    Exotic.Value.String.get(value)
    |> Exotic.Value.get_ptr()
    |> CAPI.mlirStringRefCreateFromCString()
  end

  def extract(string_ref) do
    data = Exotic.Value.fetch(string_ref, CAPI.MlirStringRef, :data)
    length = Exotic.Value.fetch(string_ref, CAPI.MlirStringRef, :length)
    Exotic.Value.String.extract(data, length)
  end

  defmodule Callback do
    alias Beaver.MLIR

    def create() do
      Exotic.Closure.create(
        MLIR.CAPI.MlirStringCallback.native_type(),
        __MODULE__,
        :string_ref_callback
      )
    end

    def handle_invoke(:string_ref_callback, [string_ref, _user_data_opaque_ptr], nil) do
      {:pass, MLIR.StringRef.extract(string_ref)}
    end

    def handle_invoke(:string_ref_callback, [string_ref, _user_data_opaque_ptr], state) do
      {:pass, state <> MLIR.StringRef.extract(string_ref)}
    end

    def collect_and_destroy(closure) do
      collected = closure |> Exotic.Closure.state()
      closure |> Exotic.Closure.destroy()
      collected
    end
  end

  def to_string(object, module, function) do
    string_ref_callback_closure = Callback.create()

    apply(module, function, [
      object,
      Exotic.Value.as_ptr(string_ref_callback_closure),
      Exotic.Value.Ptr.null()
    ])

    string_ref_callback_closure
    |> Callback.collect_and_destroy()
  end
end