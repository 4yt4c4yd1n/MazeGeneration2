mutable struct Node
    position::Tuple{Int, Int}
    connections::Vector{Bool}
    visited::Bool
    dir::Union{Int, Nothing}
    neighbors::Vector{Union{Node, Nothing}}
    Node(position::Tuple{Int,Int}) = new(position, Vector{Bool}([false, false, false, false]), false, nothing, Vector{Union{Node, Nothing}}([nothing, nothing, nothing, nothing]))
end
neighbors(n::Node) = n.neighbors

function Base.show(io::IO, n::Node)
    if n.visited
        print(io,  " [n]$(n.position) ")
    else
        print(io,  "  N $(n.position) ")
    end
    if (n.connections[1])
        print(io, "⬆ ")
    else
        print(io, "✖ ")
    end
    if (n.connections[2])
        print(io, "⬅ ")
    else
        print(io, "✖ ")
    end
    if (n.connections[4])
        print(io, "➡ ")
    else
        print(io, "✖ ")
    end
    if (n.connections[3])
        print(io, "⬇")
    else
        print(io, "✖")
    end
end

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
    short_path::Union{Vector{Tuple{Node, Int}}, Nothing}
    visual::Union{MazeViz, Nothing}
    nodes::Matrix{Node}
    start::Union{Tuple{Int, Int}, Nothing}
    goal::Union{Tuple{Int, Int}, Nothing}

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
        return new(nothing, nothing, nothing, Lab)
    end
end


function Base.show(io::IO, lab::Maze)
    viz = lab.visual
    for i in 1:size(viz.walls, 1)
        for n in 1:size(viz.walls, 2)
            print(io, join(viz.walls[i,n]))
        end
        println(io)
    end
    if !isnothing(lab.start) && !isnothing(lab.goal)
        println(io, "Start: ", lab.start, ", Goal: ", lab.goal)
    end
    if !isnothing(lab.path)
        print(io, "Right hand path: ")
        for i in 1:(length(lab.path)-1)
            print(io, lab.path[i].position, " ⇒ ")
        end
        println(io, lab.path[end].position)
    end
    if !isnothing(lab.short_path)
        print(io, "Shortest path: ")
        for i in 1:(length(lab.short_path)-1)
            print(io, lab.short_path[i][1].position, " ⇒ ")
        end
        println(io, lab.short_path[end][1].position)
    end
end