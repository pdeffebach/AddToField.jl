module AddToField

using MacroTools

export @addnt, @addto!

is_add(x::Expr) = x.head == :macrocall && x.args[1] == Symbol("@add")
is_add(x) = false

is_interp_string(x) = false
is_interp_string(x::String) = true
is_interp_string(x::Expr) = x.head == :string
is_interp_string(x::QuoteNode) = true

function add_property_or_index!(d::AbstractDict, name, value)
	setindex!(d, value, Symbol(name))
end

function add_property_or_index!(d::AbstractDict{<:AbstractString}, name, value)
	setindex!(d, value, string(name))
end

function add_property_or_index!(d, name, value)
	setproperty!(d, Symbol(name), value)
end

function add_to_props_vec!(props_vec, arg)
	if arg.args[3] isa Symbol
		v = gensym()
		n = QuoteNode(arg.args[3])
		push!(props_vec, :($n => $v))
		Expr(:block, Expr(:(=), v, arg.args[3]))
	elseif is_interp_string(arg.args[3])
		v = gensym()
		v_n = gensym()
		n = arg.args[3]
		push!(props_vec, :(Symbol($n) => $v))
		Expr(:block, Expr(:(=), v, arg.args[4]))
	elseif arg.args[3].head == :(=)
		v = gensym()
		n = QuoteNode(arg.args[3].args[1])
		push!(props_vec, :($n => $v))
		Expr(:block, Expr(:(=), v, arg.args[3]))
	elseif arg.args[3].head === :tuple
		equals_vec = []
		for s in arg.args[3].args
			v = gensym()
			@assert s isa Symbol "Ony Symbols allowed in tuples with @add"
			n = QuoteNode(s)
			push!(equals_vec, Expr(:block, Expr(:(=), v, s)))
			push!(props_vec, :($n => $v))
		end
		Expr(:block, equals_vec...)
	else
		throw(ArgumentError("Malformed @add expression"))
	end
end

function addto_one_arg_helper(body)
	body = MacroTools.unblock(body)

	props_vec = Expr[]

	newbody = MacroTools.postwalk(body) do x
		if is_add(x)
			add_to_props_vec!(props_vec, x)
		else
			x
		end
	end

	nt_expr = Expr(:tuple, Expr(:parameters, props_vec...))

	if body isa Expr && body.head == :let
		newbody.args[2] = Expr(:block, newbody.args[2], nt_expr)
		return newbody
	else
   	return Expr(:block, newbody, nt_expr)
   end
end

"""
	@addnt(body)

Create a named tuple using `@add` statments inside `body`.

### Usage

Within `body`, you can create a namedtuple with the following
syntaxes.

- `@add x`: The named tuple will contain the field `:x` with the value of `x`.
- `@add x, y, z`: The named tuple will contain the fields `x`, `y`, and `z` with
   their corresponding values.
- `@add x = expr`: The named tuple will contain the field `:x` with the value of
   `expr`. The variable `x` will still be created.
- `@add "My value" x`: The named tuple will contain the field `Symbol("My value)`
   with the value of `x`. You can also interpolate values inside the `String`
   name.
- `@add "My value" x = expr`: The named tuple will contain the field
   `Symbol("My value")` with the value of `expr`. The variable `x` will still be created.

`@addnt begin ... end` does not create a new scope, meaning changes
all variable assignments in the inside the expression modify the
existing scope. To create a new scope, use `@addnt let ... end`.

### Example:

```jldoctest
julia> s = "My long name";

julia> res = @addnt begin
		a = 1
		@add a

		f, g, h = 6, 7, 8
		@add f, g, h

		@add b = 2
		@add :c1 c = 3
		@add "d1" d = 4
		@add "My long name" e = 5
	end
end
(a = 1, f = 6, g = 7, h = 8, b = 2, c1 = 3, d1 = 4, My long name = 5)

julia> @addnt let
           @add local_var = 500
       end
(local_var = 500,)

julia> isdefined(Main, :local_var)
false
```

!!! note
    `You` cannot use `@add` in new scopes created with
    `body`. The following will fail

    ```julia
    @addnt begin
    	let
    	    a = 1
    	    @add a
    	end
    end
    ```

    This is because `@addnt` creates anonymous variables,
    then constructs the named tuple at the end of the
    expression. The same applies for `for` loops and `function`s
    inside the `@addnt` and `@addto!` blocks.
"""
macro addnt(body)
	esc(addto_one_arg_helper(body))
end

function addto_two_arg_helper(x, body)
	body = MacroTools.unblock(body)

	props_vec = []

	newbody = MacroTools.postwalk(body) do x
		if is_add(x)
			add_to_props_vec!(props_vec, x)
		else
			x
		end
	end

	anon = gensym()
	assign_to_anon = :($anon = $x)

	addproperties = map(props_vec) do p
		name = p.args[2]
		value = p.args[3]
		:(AddToField.add_property_or_index!($anon, $name, $value))
	end
	push!(addproperties, quote $anon end)

	if body isa Expr && body.head == :let
		# The first argument of a let block is a block of
		# assignments for the variable captures if
		# there are multiple captures. But if there
		# is only one, it is not, so we put it in
		# a block.
		initial_let_assignments = MacroTools.block(newbody.args[1])
		push!(initial_let_assignments.args, assign_to_anon)
		newbody.args[1] = initial_let_assignments
		newbody.args[2] = Expr(:block, newbody.args[2], addproperties...)
		return newbody
	else
   	return Expr(:block, assign_to_anon, newbody, addproperties...)
   end
end

"""
	@addto!(x, body)

Set properties or indices of `x` using `@add` statments inside `body`.

### Usage

Within `body`, you can add properies or indices of `x` with the following.

- `@add x`: The named tuple will contain the field `:x` with the value of `x`.
- `@add x, y, z`: The named tuple will contain the fields `x`, `y`, and `z`
   with their corresponding values.
- `@add x = expr`: The named tuple will contain the field `:x` with the value of
   `expr`. The variable `x` will still be created.
- `@add "My value" x`: The named tuple will contain the field `Symbol("My value)`
   with the value of `x`. You can also interpolate values inside the `String`
   name.
- `@add "My value" x = expr`: The named tuple will contain the field
   `Symbol("My value")` with the value of `expr`. The variable `x` will still be created.

`@addto!` defaults to calling `setproperty!` on `x`. However
with `AbstractDict`, it calls `setindex!` with `Symbol`s.
Wieh `AbstractDict{<:AbstractString}` is calls `setindex!` with `String`s.

`@addto! d begin ... end` does not create a new scope, meaning changes
all variable assignments in the inside the expression modify the
existing scope. To create a new scope, use `@addto! d let ... end`.

### Example:

```jldoctest
julia> D = Dict();

julia> s = "My long name";

julia> res = @addto! D begin
		a = 1
		@add a

		f, g, h = 6, 7, 8
		@add f, g, h

		@add b = 2
		@add :c1 c = 3
		@add "d1" d = 4
		@add "My long name" e = 5
	end
end
Dict{Any,Any} with 8 entries:
  :a                     => 1
  :f                     => 6
  :b                     => 2
  :h                     => 8
  :g                     => 7
  :d1                    => 4
  :c1                    => 3
  Symbol("My long name") => 5

julia> @addto! d let
           @add local_var = 500
       end;

julia> isdefined(Main, :local_var)
false
```

!!! note
    `You` cannot use `@addto!` in new scopes created with
    `body`. The following will fail

    ```julia
    @addto! D begin
    	let
    	    a = 1
    	    @add a
    	end
    end
    ```

    This is because `@addto!` creates anonymous variables,
    then constructs the `setproperty!` or `setindex!` calls
    at the end of the expression.
"""
macro addto!(x, body)
	esc(addto_two_arg_helper(x, body))
end


end # module
