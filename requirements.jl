# Install open-source solvers
using Pkg

# from COIN-OR: Computational Infrastructure for Operations Research
#Pkg.add("Clp")
#Pkg.add("Cbc")
#Pkg.add("GLPK")

Pkg.add("Combinatorics")
Pkg.add("LinearAlgebra")
Pkg.add("JuMP")
Pkg.add("Gurobi")