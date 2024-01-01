
run:
	julia --project -e 'include("test/main.jl");'

runyams:
	julia --project -e 'include("test/main_yams.jl");'

yams: runyams

install:
	julia --project -e 'import Pkg; Pkg.instantiate()'

init:
	julia --project -e 'include("test/solver.jl");'

inityams:
	julia --project -e 'include("test/solver_yams.jl");'
