
struct SMCAlgorithm{RT} <: AbstractPFAlgorithm where RT<:AbstractFloat
    resampler             ::  Function
    resampler_threshold   ::  RT

end

function SMCAlgorithm()
    SMCAlgorithm(resample_systematic, 0.5)
end

struct PGAlgorithm{RT} <:AbstractPGAlgorithm where RT<:AbstractFloat
    resampler             ::  Function
    resampler_threshold   ::  RT
    n                     ::  Int64

end

function PGAlgorithm(n::Int64)
    PGAlgorithm(resample_systematic, 0.5, n)
end


struct PGASAlgorithm{RT} <:AbstractPGAlgorithm where RT<:AbstractFloat
    resampler             ::  Function
    resampler_threshold   ::  RT
    n                     ::  Int64
    proposal_a_w          ::  Bool
end

function PGASAlgorithm(n::Int64)
    PGASAlgorithm(resample_systematic, 0.5, n, false)
end
