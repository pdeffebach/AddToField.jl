module TestAddToField

using Test, AddToField

import Base: setproperty!

function addone(x)
	x[] += 1
	return x[]
end

struct PropertyDict
	D::Dict{Symbol, Int}
end

setproperty!(PD::PropertyDict, name::Symbol, value) = setindex!(PD.D, value, name)

@testset "one arg" begin
	s = "e1"

	r = Ref(1)

	res = @addnt begin
		a = 1
		@add a
		@add b = 2
		@add :c1 c = 3
		@add "d1" d = 4
		@add "$s" e = 5
		f, g, h = 6, 7, 8

		@add f, g, h

		@add i = addone(r)
		@add "j" addone(r)
	end

	correct= (
		a = 1,
		b = 2,
		c1 = 3,
		d1 = 4,
		e1 = 5,
		f = 6,
		g = 7,
		h = 8,
		i = 2,
		j = 3
	)

	@test res == correct
end

@testset "two args" begin
	D = Dict{Symbol, Int}()

	s = "e1"

	r = Ref(1)

	res = @addto! D begin
		a = 1
		@add a
		@add b = 2
		@add :c1 c = 3
		@add "d1" d = 4
		@add "$s" e = 5
		f, g, h = 6, 7, 8

		@add f, g, h

		@add i = addone(r)
		@add "j" addone(r)
	end

	correct = Dict(
		:a => 1,
		:b => 2,
		:c1 => 3,
		:d1 => 4,
		:e1 => 5,
		:f => 6,
		:g => 7,
		:h => 8,
		:i => 2,
		:j => 3
	)

	@test res == correct

	PD = PropertyDict(Dict{Symbol, Int}())

	r = Ref(1)

	res = @addto! PD begin
		a = 1
		@add a
		@add b = 2
		@add :c1 c = 3
		@add "d1" d = 4
		@add "$s" e = 5
		f, g, h = 6, 7, 8

		@add f, g, h

		@add i = addone(r)
		@add "j" addone(r)
	end

	@test res.D == correct
end

@testset "let" begin
	x = 1

	@test x == 1
	res = @addnt let
		local x = 2
		@add y = 5
	end

	@test res == (; y = 5)
	@test x == 1

	res = Dict{Symbol, Int}()

	@addto! res let
		local x = 2
		@add y = 5
	end

	@test res == Dict([:y => 5])
	@test x == 1
end

@testset "new dict" begin
	d = @addto! Dict() begin
		x = 1
		@add y = 2
	end

	@test d == Dict{Any, Any}(:y => 2)

	d = @addto! Dict() let
		x = 10
		@add y = 20
	end

	@test d == Dict{Any, Any}(:y => 20)


	d = @addto! Dict() let z = 50
		x = 100
		@add y = 200
	end

	@test d == Dict{Any, Any}(:y => 200)

	d = @addto! Dict() let z = 50, zz = 51
		x = 100
		@add y = 200
	end

	@test d == Dict{Any, Any}(:y => 200)
end

end # module