####
#### Resampling schemes for particle filters
####

# Some references
#  - http://arxiv.org/pdf/1301.4019.pdf
#  - http://people.isy.liu.se/rt/schon/Publications/HolSG2006.pdf
# Code adapted from: http://uk.mathworks.com/matlabcentral/fileexchange/24968-resampling-methods-for-particle-filtering

# More stable, faster version of rand(Categorical)
function randcat(rng::Random.AbstractRNG, p::AbstractVector{<:Real})
    T = eltype(p)
    r = rand(rng, T)
    cp = p[1]
    s = 1
    n = length(p)
    while cp <= r && s < n
        @inbounds cp += p[s += 1]
    end
    return s
end

function resample_multinomial(
    rng::Random.AbstractRNG, w::AbstractVector{<:Real}, num_particles::Integer=length(w)
)
    return rand(rng, Distributions.sampler(Distributions.Categorical(w)), num_particles)
end

function resample_residual(
    rng::Random.AbstractRNG,
    w::AbstractVector{<:Real},
    num_particles::Integer=length(weights),
)
    # Pre-allocate array for resampled particles
    indices = Vector{Int}(undef, num_particles)

    # deterministic assignment
    residuals = similar(w)
    i = 1
    @inbounds for j in 1:length(w)
        x = num_particles * w[j]
        floor_x = floor(Int, x)
        for k in 1:floor_x
            indices[i] = j
            i += 1
        end
        residuals[j] = x - floor_x
    end

    # sampling from residuals
    if i <= num_particles
        residuals ./= sum(residuals)
        rand!(rng, Distributions.Categorical(residuals), view(indices, i:num_particles))
    end

    return indices
end

"""
    resample_stratified(rng, weights, n)

Return a vector of `n` samples `x₁`, ..., `xₙ` from the numbers 1, ..., `length(weights)`,
generated by stratified resampling.

In stratified resampling `n` ordered random numbers `u₁`, ..., `uₙ` are generated, where
``uₖ \\sim U[(k - 1) / n, k / n)``. Based on these numbers the samples `x₁`, ..., `xₙ`
are selected according to the multinomial distribution defined by the normalized `weights`,
i.e., `xᵢ = j` if and only if
``uᵢ \\in [\\sum_{s=1}^{j-1} weights_{s}, \\sum_{s=1}^{j} weights_{s})``.
"""
function resample_stratified(
    rng::Random.AbstractRNG, weights::AbstractVector{<:Real}, n::Integer=length(weights)
)
    # check input
    m = length(weights)
    m > 0 || error("weight vector is empty")

    # pre-calculations
    @inbounds v = n * weights[1]

    # generate all samples
    samples = Array{Int}(undef, n)
    sample = 1
    @inbounds for i in 1:n
        # sample next `u` (scaled by `n`)
        u = oftype(v, i - 1 + rand(rng))

        # as long as we have not found the next sample
        while v < u
            # increase and check the sample
            sample += 1
            sample > m &&
                error("sample could not be selected (are the weights normalized?)")

            # update the cumulative sum of weights (scaled by `n`)
            v += n * weights[sample]
        end

        # save the next sample
        samples[i] = sample
    end

    return samples
end

"""
    resample_systematic(rng, weights, n)

Return a vector of `n` samples `x₁`, ..., `xₙ` from the numbers 1, ..., `length(weights)`,
generated by systematic resampling.

In systematic resampling a random number ``u \\sim U[0, 1)`` is used to generate `n` ordered
numbers `u₁`, ..., `uₙ` where ``uₖ = (u + k − 1) / n``. Based on these numbers the samples
`x₁`, ..., `xₙ` are selected according to the multinomial distribution defined by the
normalized `weights`, i.e., `xᵢ = j` if and only if
``uᵢ \\in [\\sum_{s=1}^{j-1} weights_{s}, \\sum_{s=1}^{j} weights_{s})``.
"""
function resample_systematic(
    rng::Random.AbstractRNG, weights::AbstractVector{<:Real}, n::Integer=length(weights)
)
    # check input
    m = length(weights)
    m > 0 || error("weight vector is empty")

    # pre-calculations
    @inbounds v = n * weights[1]
    u = oftype(v, rand(rng))

    # find all samples
    samples = Array{Int}(undef, n)
    sample = 1
    @inbounds for i in 1:n
        # as long as we have not found the next sample
        while v < u
            # increase and check the sample
            sample += 1
            sample > m &&
                error("sample could not be selected (are the weights normalized?)")

            # update the cumulative sum of weights (scaled by `n`)
            v += n * weights[sample]
        end

        # save the next sample
        samples[i] = sample

        # update `u`
        u += one(u)
    end

    return samples
end

const DEFAULT_RESAMPLER = resample_systematic

struct ResampleWithESSThreshold{R,T<:Real}
    resampler::R
    threshold::T
end

function ResampleWithESSThreshold(resampler=DEFAULT_RESAMPLER)
    return ResampleWithESSThreshold(resampler, 0.5)
end

function ResampleWithESSThreshold(threshold::T) where {T<:Real}
    return ResampleWithESSThreshold(DEFAULT_RESAMPLER, threshold)
end
