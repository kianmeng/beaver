defmodule Beaver.MLIR.Type do
  alias Beaver.MLIR
  alias Beaver.MLIR.CAPI

  def get(string, opts \\ [])

  def get(string, opts) when is_binary(string) do
    ctx = MLIR.Managed.Context.from_opts(opts)
    CAPI.mlirTypeParseGet(ctx, MLIR.StringRef.create(string))
  end

  def equal?(a, b) do
    CAPI.mlirTypeEqual(a, b) |> Exotic.Value.extract()
  end

  def function(inputs, results, opts \\ []) do
    num_inputs = length(inputs)
    num_results = length(results)
    inputs = inputs |> Exotic.Value.Array.get() |> Exotic.Value.get_ptr()
    results = results |> Exotic.Value.Array.get() |> Exotic.Value.get_ptr()
    function(num_inputs, inputs, num_results, results, opts)
  end

  def ranked_tensor(
        shape,
        %MLIR.CAPI.MlirType{} = element_type,
        encoding \\ Exotic.Value.Ptr.null()
      )
      when is_list(shape) do
    rank = length(shape)

    shape = shape |> Exotic.Value.Array.from_list({:i, 64}) |> Exotic.Value.get_ptr()

    ranked_tensor(rank, shape, element_type, encoding)
  end

  def memref(
        shape,
        %MLIR.CAPI.MlirType{} = element_type,
        opts \\ [layout: Exotic.Value.Ptr.null(), memory_space: Exotic.Value.Ptr.null()]
      )
      when is_list(shape) do
    rank = length(shape)

    shape = shape |> Exotic.Value.Array.from_list({:i, 64}) |> Exotic.Value.get_ptr()

    [layout: layout, memory_space: memory_space] =
      for k <- [:layout, :memory_space] do
        {k, Keyword.get(opts, k, Exotic.Value.Ptr.null())}
      end

    CAPI.mlirMemRefTypeGet(element_type, rank, shape, layout, memory_space)
  end

  def vector(shape, element_type) when is_list(shape) do
    rank = length(shape)
    shape = shape |> Exotic.Value.Array.from_list({:i, 64}) |> Exotic.Value.get_ptr()
    vector(rank, shape, element_type)
  end

  def tuple(elements) when is_list(elements) do
    num_elements = length(elements)
    elements = elements |> Exotic.Value.Array.from_list() |> Exotic.Value.get_ptr()
    tuple(num_elements, elements, [])
  end

  def tuple(elements, opts) when is_list(elements) do
    num_elements = length(elements)
    elements = elements |> Exotic.Value.Array.from_list() |> Exotic.Value.get_ptr()
    tuple(num_elements, elements, opts)
  end

  for {:function_signature,
       [
         f = %Exotic.CodeGen.Function{
           name: name,
           args: args,
           ret: {:type_def, Beaver.MLIR.CAPI.MlirType}
         }
       ]} <-
        MLIR.CAPI.__info__(:attributes) do
    name_str = Atom.to_string(name)
    is_type_get = name_str |> String.ends_with?("TypeGet")

    if is_type_get do
      "mlir" <> generated_func_name = name_str
      generated_func_name = generated_func_name |> String.slice(0..-8) |> Macro.underscore()
      generated_func_name = generated_func_name |> String.to_atom()

      @doc """
      generated from
      ```
      #{inspect(f, pretty: true)}
      ```
      """
      case args do
        [{_ctx, {:type_def, Beaver.MLIR.CAPI.MlirContext}} | rest_args] ->
          args =
            for {arg_name, _} <- rest_args do
              arg_name = arg_name |> Atom.to_string() |> Macro.underscore() |> String.to_atom()
              {arg_name, [], nil}
            end

          def unquote(generated_func_name)(unquote_splicing(args), opts \\ []) do
            ctx = MLIR.Managed.Context.from_opts(opts)
            apply(Beaver.MLIR.CAPI, unquote(name), [ctx, unquote_splicing(args)])
          end

        args ->
          args =
            for {arg_name, _} <- args do
              arg_name = arg_name |> Atom.to_string() |> Macro.underscore() |> String.to_atom()
              {arg_name, [], nil}
            end

          def unquote(generated_func_name)(unquote_splicing(args)) do
            apply(Beaver.MLIR.CAPI, unquote(name), [unquote_splicing(args)])
          end
      end
    end
  end

  def f(bitwidth, opts \\ []) when is_integer(bitwidth) do
    apply(__MODULE__, String.to_atom("f#{bitwidth}"), [opts])
  end

  defdelegate i(bitwidth, opts \\ []), to: __MODULE__, as: :integer

  for bitwidth <- [1, 8, 16, 32, 64, 128] do
    i_name = "i#{bitwidth}" |> String.to_atom()

    def unquote(i_name)() do
      apply(__MODULE__, :i, [unquote(bitwidth)])
    end
  end

  def to_string(type) do
    MLIR.StringRef.to_string(type, CAPI, :mlirTypePrint)
  end
end