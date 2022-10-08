defmodule Beaver.DSL.Pattern do
  alias Beaver.MLIR
  import MLIR.Sigils
  import Beaver
  require Beaver.MLIR
  require Beaver.MLIR.CAPI

  defmodule Env do
    defstruct ctx: nil, block: nil
  end

  @doc """
  generate PDL ops for types and attributes
  """
  def gen_pdl(%Env{} = env, %MLIR.CAPI.MlirType{} = type) do
    mlir block: env.block, ctx: env.ctx do
      Beaver.MLIR.Dialect.PDL.type(constantType: type) >>> ~t{!pdl.type}
    end
  end

  def gen_pdl(%Env{} = env, f) when is_function(f, 1) do
    Quark.Compose.compose(
      &gen_pdl(env, &1),
      f
    )
  end

  def gen_pdl(%Env{} = env, %Beaver.MLIR.CAPI.MlirAttribute{} = attribute) do
    mlir block: env.block, ctx: env.ctx do
      Beaver.MLIR.Dialect.PDL.attribute(value: attribute) >>>
        ~t{!pdl.attribute}
    end
  end

  def gen_pdl(_env, %MLIR.Value{} = value) do
    value
  end

  @doc """
  The difference between a pdl.operation creation in a match body and a rewrite body:
  - in a match body, pdl.attribute/pdl.operand/pdl.result will be generated for unbound variables
  - in a rewrite body, all variables are considered bound before creation pdl ops
  """
  def create_operation(
        op_name,
        %Beaver.DSL.Op.Prototype{operands: operands, attributes: attributes, results: results},
        {%Env{} = env, attribute_names}
      )
      when is_list(attribute_names) do
    mlir block: env.block, ctx: env.ctx do
      results = results |> Enum.map(&gen_pdl(env, &1))
      attributes = attributes |> Enum.map(&gen_pdl(env, &1))

      Beaver.MLIR.Dialect.PDL.operation(
        operands ++
          attributes ++
          results ++
          [
            opName: Beaver.MLIR.Attribute.string(op_name),
            attributeValueNames: Beaver.MLIR.Attribute.array(attribute_names),
            operand_segment_sizes:
              Beaver.MLIR.ODS.operand_segment_sizes([
                length(operands),
                length(attributes),
                length(results)
              ])
          ]
      ) >>> ~t{!pdl.operation}
    end
  end

  def gen_attribute_names(attributes_keys) do
    for key <- attributes_keys do
      key
      |> Atom.to_string()
      |> Beaver.MLIR.Attribute.string()
    end
  end

  def gen_prototype_args(kind, map_args) do
    args = map_args |> Keyword.get(kind, [])

    case args do
      # a variable, do nothing
      {_name, _line, nil} ->
        args

      {:bound, var} ->
        var

      args when is_list(args) ->
        case kind do
          # Transform unbound variables of operands/results. If is bound, it means it is another operation's result (get bound in a previous expression)
          kind when kind in [:operands, :results] ->
            Enum.map(args, fn
              {:bound, bound} -> bound
              other -> other
            end)

          # extract unbound variables from attributes keyword
          :attributes ->
            Enum.map(args, fn
              {_k, {:bound, bound}} -> bound
              {_k, other} -> other
            end)
        end

      _ ->
        raise "Must pass a list or a variable to operands/attributes/results, got: \n" <>
                Macro.to_string(args)
    end
  end

  @doc """
  generate arguments for prototype dispatch
  """
  def gen_prototype_args(map_args) do
    map_args
    |> Keyword.put(:operands, gen_prototype_args(:operands, map_args))
    |> Keyword.put(:attributes, gen_prototype_args(:attributes, map_args))
    |> Keyword.put(:results, gen_prototype_args(:results, map_args))
  end

  defp create_op_in_match(
         struct_name,
         map_args
       ) do
    operands = map_args |> Keyword.get(:operands, [])
    results = map_args |> Keyword.get(:results, [])
    attributes = map_args |> Keyword.get(:attributes, [])

    map_args = map_args |> gen_prototype_args

    # generate bounds between operand variables and pdl.operand
    operands =
      for operand <- operands do
        case operand do
          {:bound, _bound} ->
            quote do
              []
            end

          _ ->
            quote do
              unquote(operand) = Beaver.MLIR.Dialect.PDL.operand() >>> ~t{!pdl.value}
            end
        end
      end

    # generate bounds between attribute variables and pdl.attribute
    attributes_match =
      if Keyword.keyword?(attributes) do
        for {_name, attribute} <- attributes do
          case attribute do
            {:bound, bound} ->
              quote do
                unquote(bound) = Beaver.DSL.Pattern.gen_pdl(env, unquote(bound))
              end

            _ ->
              quote do
                unquote(attribute) = Beaver.MLIR.Dialect.PDL.attribute() >>> ~t{!pdl.attribute}
              end
          end
        end
      else
        []
      end

    attributes_keys = Keyword.keys(attributes)

    # generate bounds between result variables and pdl.type
    results_match =
      if is_list(results) do
        for result <- results do
          case result do
            {:bound, bound} ->
              quote do
                Beaver.DSL.Pattern.gen_pdl(env, unquote(bound))
              end

            _ ->
              quote do
                unquote(result) = Beaver.MLIR.Dialect.PDL.type() >>> ~t{!pdl.type}
              end
          end
        end
      else
        []
      end

    # generate bounds between result variables and pdl.value produced by pdl.result
    # preceding expression should use pin operator (^var) to access these version of binding otherwise it will get bound to a pdl.value produced by pdl.operand
    # must use a list of unbound variables to do the match
    results_rebind =
      if is_list(results) do
        for {result, i} <- Enum.with_index(results) do
          case result do
            {:bound, _bound} ->
              []

            _ ->
              quote do
                unquote(result) =
                  Beaver.MLIR.Dialect.PDL.result(
                    beaver_gen_root,
                    index: Beaver.MLIR.Attribute.integer(Beaver.MLIR.Type.i32(), unquote(i))
                  ) >>> ~t{!pdl.value}
              end
          end
        end
      else
        []
      end

    # injecting all variables and dispatch the op creation
    ast =
      quote do
        env = %Env{ctx: MLIR.__CONTEXT__(), block: MLIR.__BLOCK__()}
        unquote_splicing(operands)
        unquote_splicing(attributes_match)
        unquote_splicing(results_match)

        attribute_names = Beaver.DSL.Pattern.gen_attribute_names(unquote(attributes_keys))

        beaver_gen_root =
          Beaver.DSL.Op.Prototype.dispatch(
            unquote(struct_name),
            unquote(map_args),
            {env, attribute_names},
            &Beaver.DSL.Pattern.create_operation/3
          )

        unquote_splicing(results_rebind)
        beaver_gen_root
      end

    ast
  end

  defp create_op_in_rewrite(
         struct_name,
         map_args
       ) do
    attributes = map_args |> Keyword.get(:attributes, [])

    filtered_attributes =
      Enum.map(attributes, fn
        {_k, other} -> other
      end)

    map_args = Keyword.put(map_args, :attributes, filtered_attributes)
    attributes_keys = Keyword.keys(attributes)

    ast =
      quote do
        env = %Env{ctx: MLIR.__CONTEXT__(), block: MLIR.__BLOCK__()}
        attribute_names = Beaver.DSL.Pattern.gen_attribute_names(unquote(attributes_keys))

        Beaver.DSL.Op.Prototype.dispatch(
          unquote(struct_name),
          unquote(map_args),
          {env, attribute_names},
          &Beaver.DSL.Pattern.create_operation/3
        )
      end

    ast
  end

  defp transform_struct_to_op_creation(
         caller,
         {:%, _,
          [
            struct_name,
            {:%{}, _, map_args}
          ]} = ast,
         cb
       )
       when is_function(cb, 2) do
    case struct_name do
      # TODO: this is a hack, need to find a better way to get the module name
      {:__aliases__, _line, [dialect | tail] = op_name} when is_list(op_name) ->
        module =
          with {:ok, mod} <- Macro.Env.fetch_alias(caller, dialect) do
            Module.concat([mod | tail])
          else
            _ -> Module.concat(op_name)
          end

        if Beaver.DSL.Op.Prototype.is_compliant(module) do
          apply(cb, [struct_name, map_args])
        else
          ast
        end

      _ ->
        ast
    end
  end

  defp transform_struct_to_op_creation(_caller, ast, _cb), do: ast

  defp do_transform_match(_caller, {:^, _, [var]}) do
    {:bound, var}
  end

  defp do_transform_match(caller, ast),
    do: transform_struct_to_op_creation(caller, ast, &create_op_in_match/2)

  defp do_transform_rewrite(caller, ast),
    do: transform_struct_to_op_creation(caller, ast, &create_op_in_rewrite/2)

  @doc """
  transform a macro's call to PDL operations to match operands, attributes, results.
  Every Prototype form within the block should be transformed to create a PDL operation.
  """

  def transform_match(caller, ast) do
    Macro.postwalk(ast, &do_transform_match(caller, &1))
  end

  @doc """
  transform a do block to PDL rewrite operation.
  Every Prototype form within the block should be transformed to create a PDL operation.
  The last expression will be replaced by the root op in the match by default.
  TODO: wrap this function with a macro rewrite/1, so that it could be use in a independent function
  """
  def transform_rewrite(caller, ast) do
    rewrite_block_ast = Macro.postwalk(ast, &do_transform_rewrite(caller, &1))

    quote do
      Beaver.MLIR.Dialect.PDL.rewrite [
        beaver_gen_root,
        operand_segment_sizes: Beaver.MLIR.ODS.operand_segment_sizes([1, 0])
      ] do
        region do
          block some() do
            repl = unquote(rewrite_block_ast)

            Beaver.MLIR.Dialect.PDL.replace([
              beaver_gen_root,
              repl,
              operand_segment_sizes: Beaver.MLIR.ODS.operand_segment_sizes([1, 1, 0])
            ]) >>> []
          end
        end
      end >>> []
    end
  end

  # TODO: accepting block here is ugly, change it to %Beaver.Env{block: block}
  def result(%Env{} = env, %Beaver.MLIR.Value{} = v, i) when is_integer(i) do
    alias Beaver.MLIR.Dialect.PDL

    mlir block: env.block, ctx: env.ctx do
      v = %{v | safe_to_print: false}

      PDL.result(v, index: Beaver.MLIR.Attribute.integer(Beaver.MLIR.Type.i32(), i)) >>>
        ~t{!pdl.value}
    end
  end
end