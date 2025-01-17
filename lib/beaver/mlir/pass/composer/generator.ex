defmodule Beaver.MLIR.Pass.Composer.Generator do
  @moduledoc false
  alias Beaver.MLIR
  alias Beaver.MLIR.CAPI

  def normalized_name(original) do
    original
    |> String.replace("-", "_")
    |> Macro.underscore()
    |> String.to_atom()
  end

  defmacro __using__(prefix: prefix) do
    quote bind_quoted: [prefix: prefix] do
      require Beaver.MLIR.CAPI
      alias Beaver.MLIR
      alias Beaver.MLIR.CAPI
      alias Beaver.MLIR.Pass.Composer

      # We are calling C functions dynamically at compile time, so we need to make sure managed libraries get loaded.

      for fa <- CAPI.__info__(:functions) do
        with {name, 0} <- fa do
          is_transform = name |> Atom.to_string() |> String.starts_with?(prefix)

          if is_transform do
            pass = apply(CAPI, name, [])

            arg_name =
              pass
              |> CAPI.beaverPassGetArgument()
              |> MLIR.StringRef.to_string()

            pass_name =
              pass
              |> CAPI.beaverPassGetName()
              |> MLIR.StringRef.to_string()

            normalized_name = MLIR.Pass.Composer.Generator.normalized_name(arg_name)

            doc = pass |> CAPI.beaverPassGetDescription() |> MLIR.StringRef.to_string()

            @doc """
            #{doc}
            ### Argument name in MLIR CLI
            `#{arg_name}`
            ### Pass name in TableGen
            `#{pass_name}`
            """
            def unquote(normalized_name)() do
              CAPI.unquote(name)()
            end

            def unquote(normalized_name)(composer_or_op) do
              pass = CAPI.unquote(name)()
              Composer.append(composer_or_op, pass)
            end
          end
        end
      end
    end
  end
end
