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

	res = @addto D begin
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

	res = @addto PD begin
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

end # module