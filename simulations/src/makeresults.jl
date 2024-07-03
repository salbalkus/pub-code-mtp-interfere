

function makeresults(v::Vector, methods = ["or", "ipw", "onestep", "tmle"])
    output = vcat([
        vcat([
            construct_df(v, key, subkey)
            for subkey in keys(v[1][1][key])
        ]...)
        for key in methods
    ]...)
    output[!, :estimate] = String.(output[!, :estimate])
    return output
end


function construct_df(v::Vector, key::String, subkey::Symbol)
    value = [r[key][subkey] for rvec in v for r in rvec]
    return DataFrame(
        value = value,
        estimate = fill(subkey, length(value)),
        method = fill(key, length(value)),
        samples = [r["samples"] for rvec in v for r in rvec],
        i = [r["i"] for rvec in v for r in rvec]
    )
end