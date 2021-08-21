# AddToField.jl

Julia macros to easily construct named tuples and set properties of mutable structures. AddToField.jl exports three macros, `@addnt`, for constructing `NamedTuple`s, `@adddict`, for creating `Dict`s with `Symbol`s as keys, and `@addto!` for modifiying existing data structures. Github repo [here](https://github.com/pdeffebach/AddToField.jl).

To create `NamedTuples`, use `@addnt`:

```julia
julia> using AddToField;

julia> @addnt begin 
           @add a = 1
           @add b = a + 2
       end
(a = 1, b = 3)

julia> @addnt begin 
           @add "Variable a" a = 1
           @add b = a + 2
       end
(Variable a = 1, b = 3)
```

To create `Dict`s, use `@adddict`:

```julia
julia> using AddToField;

julia> @adddict begin 
           @add a = 1
           @add b = a + 2
       end
Dict{Symbol, Int64} with 2 entries:
  :a => 1
  :b => 3

julia> @adddict begin 
           @add "Variable a" a = 1
           @add b = a + 2
       end
Dict{Symbol, Int64} with 2 entries:
  Symbol("Variable a") => 1
  :b                   => 3
```

To modify existing structures, use `@addto!`

```julia
julia> D = Dict();

julia> @addto! D begin 
           @add a = 1
           @add b = a + 2
           @add "Variable c" c = b + 3
       end
Dict{Any,Any} with 3 entries:
  :a                   => 1
  :b                   => 3
  Symbol("Variable c") => 6
```


AddToField makes working with [DataFrames](https://github.com/JuliaData/DataFrames.jl)
easier. First, makes the creation of publication-quality tables easier. 

```julia
using DataFrames, PrettyTables, Chain
julia> df = DataFrame(
           group = repeat(1:2, 50),
           income_reported = rand(100),
           income_imputed = rand(100));

julia> @chain df begin 
           groupby(:group)
           combine(_; keepkeys = false) do d
               @addnt begin 
                   @add "Group" first(d.group)
                   @add "Mean reported income" m_reported = mean(d.income_reported)
                   @add "Mean imputed income" m_imputed = mean(d.income_imputed)
                   @add "Difference" m_reported - m_imputed
               end
           end
           pretty_table(;nosubheader = true)
       end
┌───────┬──────────────────────┬─────────────────────┬────────────┐
│ Group │ Mean reported income │ Mean imputed income │ Difference │
├───────┼──────────────────────┼─────────────────────┼────────────┤
│     1 │             0.523069 │             0.53696 │ -0.0138915 │
│     2 │             0.473178 │             0.41845 │  0.0547277 │
└───────┴──────────────────────┴─────────────────────┴────────────┘
```

It also makes constructing data frames easier


```julia
julia> using DataFrames

julia> @addto! DataFrame() begin
           x = ["a", "b", "c"]
           @add x = x .* "_x"
           @add x_y = x .* "_y"
       end
3×2 DataFrame
 Row │ x       x_y    
     │ String  String 
─────┼────────────────
   1 │ a_x     a_x_y
   2 │ b_x     b_x_y
   3 │ c_x     c_x_y

```

!!! note
    You cannot use `@add` in new scopes created with
    `body`. The following will fail

    ```julia
    @addnt begin
      let
          a = 1
          @add a
      end
    end
    ```

    This is because `@addnt`, `@adddict`, and `@addto!` create anonymous variables,
    then constructs and modifies objects at the end of the block.
    The same applies for `for` loops and `function`s  inside the `@addnt`, `@adddict`, and 
    `@addto!` blocks. In theory, `@addto!` should not have this limitation. 
    However I implementing this feature in `@addnt` is more complicated, 
    and at the moment maintaining simple feature parity is important. 