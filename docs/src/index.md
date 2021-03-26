# AddToField.jl

Julia macros to usingasily construct named tuples and set properties of mutable structures. AddToField.jl exports two macros, `@addnt`, for constructing `NamedTuple`s and `@addto!` for modifiying existing data structures. 

AddToField was originally written to make working with DataFrames easier, in 
particular the creation of publication-quality tables. Consider the following 

```
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

# Provided macros

```@docs
@addnt
```

```@docs
@addto!
```