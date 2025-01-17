defmodule Beaver.Env do
  @moduledoc """
  This module defines macros to getting MLIR context, region, block within the do block of mlir/1. It works like __MODULE__/0, __CALLER__/0 of Elixir special forms.
  """

  @doc """
  Return context in the DSL environment
  """
  defmacro context() do
    if Macro.Env.has_var?(__CALLER__, {:beaver_internal_env_ctx, nil}) do
      quote do
        Kernel.var!(beaver_internal_env_ctx)
      end
    else
      raise "no MLIR context in environment, maybe you forgot to put the ssa form inside the 'mlir ctx: ctx, do: ....' ?"
    end
  end

  @doc """
  Return region in the DSL environment
  """
  defmacro region() do
    if Macro.Env.has_var?(__CALLER__, {:beaver_env_region, nil}) do
      quote do
        Kernel.var!(beaver_env_region)
      end
    else
      quote do
        nil
      end
    end
  end

  @doc """
  Return block in the DSL environment
  """
  defmacro block() do
    if Macro.Env.has_var?(__CALLER__, {:beaver_internal_env_block, nil}) do
      quote do
        Kernel.var!(beaver_internal_env_block)
      end
    else
      raise "no block in environment, maybe you forgot to put the ssa form inside the Beaver.mlir/2 macro or a block/1 macro?"
    end
  end

  @doc """
  Return block with a given name in the DSL environment
  """
  defmacro block({var_name, _line, nil} = block_var) do
    if Macro.Env.has_var?(__CALLER__, {var_name, nil}) do
      quote do
        %Beaver.MLIR.Block{} = unquote(block_var)
      end
    else
      quote do
        Kernel.var!(unquote(block_var)) = Beaver.MLIR.Block.create([])
        %Beaver.MLIR.Block{} = Kernel.var!(unquote(block_var))
      end
    end
  end

  @doc """
  Create location from caller in the Elixir source
  """
  defmacro location() do
    file = __CALLER__.file
    line = __CALLER__.line

    quote do
      Beaver.MLIR.Location.file(
        name: unquote(file),
        line: unquote(line),
        ctx: Beaver.Env.context()
      )
    end
  end
end
