using Turing
using BenchmarkTools
n = 3000

y = Vector{Float64}(undef,n-1)
for i =1:n-1
    y[i] = 0
end

@model demo(y) = begin
    x = Vector{Float64}(undef,n)
    x[1] ~ Normal()
    for i = 2:n
        x[i] ~ Normal()
        y[i-1] ~ Normal(x[i],1.0)
    end
end




#@elapsed sample(demo(),PG(10),5)
chn = @btime sample(demo(y), SMC(), 100)
