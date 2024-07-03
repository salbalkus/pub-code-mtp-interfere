script_checksum(script) = crc32(Base.replace(read(scriptsdir("dgp", "$(script)"), String), "\n" => "", "\r" => "", "   " => "", " " => ""))

function cluster_graph(n, k)
    n_clusters = n ÷ k
    block = ones(k, k)
    block[diagind(block)] .= 0
    block = sparse(block)
    return(Graph(LinearAlgebra.blockdiag((block for i in 1:n_clusters)...)))
end