"""
    observe(dist::Distribution, x)

Observe sample `x` from distribution `dist` and yield its log-likelihood value.
"""
function observe(dist::Distributions.Distribution, x)
    return Libtask.produce(Distributions.loglikelihood(dist, x))
end

function (instr::Libtask.Instruction{typeof(observe)})()
    dist = Libtask.val(instr.input[1])
    x = Libtask.val(instr.input[2])
    result = Distributions.loglikelihood(dist, x)
    return Libtask.internal_produce(instr, result)
end
