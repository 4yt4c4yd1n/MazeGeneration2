mutable struct Node
    position::Tuple{Int, Int}
    connections::Vector{Bool}
    visited::Bool
    neighbors::Vector{Union{Node, Nothing}}
    Node(position::Tuple{Int,Int}) = new(position, Vector{Bool}([false, false, false, false]), false, Vector{Union{Node, Nothing}}([nothing, nothing, nothing, nothing]))
end
neighbors(n::Node) = n.neighbors

function neighbors(node::Node, nodes::Matrix{Node})
    hood = []
    height, width = size(nodes, 1), size(nodes, 2)
    y, x = node.position[1], node.position[2]

    if y-1 >= 1
        push!(hood, nodes[y-1, x])
    else
        push!(hood, nothing)
    end
    if x-1 >= 1
        push!(hood, nodes[y, x-1])
    else
        push!(hood, nothing)
    end
    if y+1 <= height
        push!(hood, nodes[y+1, x])
    else
        push!(hood, nothing)
    end
    if x+1 <= width
        push!(hood, nodes[y, x+1])
    else
        push!(hood, nothing)
    end

    return hood
end

struct MazeViz
    walls::Vector{String}
end
mutable struct Maze

    path::Union{Vector{Node}, Nothing}
    short_path::Union{Vector{Node}, Nothing}
    visual::Union{MazeViz, Nothing}
    nodes::Matrix{Node}
    start::Union{Tuple{Int, Int}, Nothing}
    goal::Union{Tuple{Int, Int}, Nothing}
    curr_node::Union{Node, Nothing}

    function Maze(height::Int, width::Int)
        Lab = Matrix{Node}(undef, height, width)
        for j in 1: height
            for i in 1:width
                
                Lab[j, i] = Node((j, i))

            end
        end
        for j in 1: height
            for i in 1:width
                
                Lab[j, i].neighbors = neighbors(Lab[j, i], Lab)

            end
        end
        return new(nothing, nothing, nothing, Lab, nothing, nothing, nothing)
    end
end