defmodule Beaver.MLIR.CAPI do
  require Logger

  mem_ref_descriptor_kinds =
    for rank <- [
          DescriptorUnranked,
          Descriptor1D,
          Descriptor2D,
          Descriptor3D,
          Descriptor4D,
          Descriptor5D,
          Descriptor6D,
          Descriptor7D,
          Descriptor8D,
          Descriptor9D
        ],
        t <- [Complex.F32, U8, U16, U32, I8, I16, I32, I64, F32, F64] do
      %Kinda.CodeGen.Type{
        module_name: Module.concat([Beaver.Native, t, MemRef, rank]),
        kind_functions: Beaver.MLIR.CAPI.CodeGen.memref_kind_functions()
      }
    end

  kinds =
    [
      %Kinda.CodeGen.Type{
        module_name: Beaver.Native.PtrOwner
      },
      %Kinda.CodeGen.Type{
        module_name: Beaver.Native.Complex.F32,
        kind_functions: Beaver.MLIR.CAPI.CodeGen.memref_kind_functions()
      }
    ] ++ mem_ref_descriptor_kinds

  dest_dir = Path.join([Mix.Project.build_path(), "native-install"])

  llvm_constants =
    with {:ok, include_dir} <- Beaver.LLVM.Config.include_dir() do
      %{
        llvm_include: include_dir
      }
    else
      _ ->
        %{}
    end

  use Kinda.Prebuilt,
    otp_app: :beaver,
    lib_name: "beaver",
    base_url:
      Application.compile_env(
        :beaver,
        :prebuilt_base_url,
        "https://github.com/beaver-project/beaver-prebuilt/releases/download/2022-10-06-1051"
      ),
    version: "0.2.10",
    wrapper: Path.join(File.cwd!(), "native/wrapper.h"),
    zig_src: "native/mlir-zig",
    include_paths:
      %{
        beaver_include: Path.join(File.cwd!(), "native/mlir-c/include")
      }
      |> Map.merge(llvm_constants),
    constants: %{
      beaver_libdir: Path.join(dest_dir, "lib")
    },
    dest_dir: dest_dir,
    type_gen: &__MODULE__.CodeGen.type_gen/2,
    nif_gen: &__MODULE__.CodeGen.nif_gen/1,
    kinds: kinds,
    forward_module: Beaver.Native,
    func_filter: fn fns ->
      fns
      |> Enum.filter(fn x -> String.contains?(x, "mlir") || String.contains?(x, "beaver") end)
      |> Enum.filter(fn x -> String.contains?(x, "pub extern fn") end)
    end

  @moduledoc """

  This module calls C API of MLIR. These FFIs are generated from headers in LLVM repo and this repo's headers providing supplemental functions.
  """

  llvm_headers =
    with {:ok, include_dir} <- Beaver.LLVM.Config.include_dir() do
      include_dir
      |> Path.join("*.h")
      |> Path.wildcard()
    else
      _ ->
        []
    end

  # setting up elixir re-compilation triggered by changes in external files
  for path <-
        llvm_headers ++
          Path.wildcard("native/mlir-c/**/*.h") ++
          Path.wildcard("native/mlir-c/**/*.cpp") ++
          Path.wildcard("native/mlir-zig/src/**") ++
          ["native/mlir-zig/#{Mix.env()}/build.zig"],
      not String.contains?(path, "kinda.gen.zig") do
    @external_resource path
  end

  # stubs for hand-written NIFs
  def beaver_raw_get_context_load_all_dialects(), do: raise("NIF not loaded")

  def beaver_raw_create_mlir_pass(
        _name,
        _argument,
        _description,
        _op_name,
        _handler
      ),
      do: raise("NIF not loaded")

  def beaver_raw_pass_token_signal(_), do: raise("NIF not loaded")
  def beaver_raw_registered_ops(), do: raise("NIF not loaded")
  def beaver_raw_registered_ops_of_dialect(_), do: raise("NIF not loaded")
  def beaver_raw_registered_dialects(), do: raise("NIF not loaded")
  def beaver_raw_resource_c_string_to_term_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_attribute_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_type_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_operation_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_value_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_affine_map_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_beaver_location_to_charlist(_), do: raise("NIF not loaded")
  def beaver_raw_mlir_named_attribute_get(_, _), do: raise("NIF not loaded")
  def beaver_raw_get_resource_c_string(_), do: raise("NIF not loaded")
  def beaver_raw_read_opaque_ptr(_, _), do: raise("NIF not loaded")
  def beaver_raw_own_opaque_ptr(_), do: raise("NIF not loaded")
  def beaver_raw_context_attach_diagnostic_handler(_), do: raise("NIF not loaded")
end