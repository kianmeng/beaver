require Beaver.MLIR.CAPI
require Beaver.MLIR.Dialect

for d <-
      Beaver.MLIR.Dialect.Registry.dialects()
      |> Enum.reject(fn x -> x in ~w{
        cf arith func builtin tensor
        llvm spirv tosa linalg rocdl shape pdl_interp vector
        } end) do
  Beaver.MLIR.Dialect.define_modules(d)
end
