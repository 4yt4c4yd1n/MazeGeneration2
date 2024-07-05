module MazeGeneration2
include("functions.jl")
export maze, animateMaze, visualize
function randUnvisitedDirection(nodes::Vector)
    # get a list of unvisited nodes
    unvisited = filter(x->!isnothing(x)&&!x.visited,nodes)

    # if no unvisited neighbors exist, return nothing
    if isempty(unvisited)
        return nothing
    end

    # pick a random next neighbor
    next = rand(unvisited)

    # get the index(direction) for the neighbor
    index = findfirst(==(next), nodes)


    # return the direction of the next node
    return index
end


function maze(height::Int, width::Int)

    @assert height >= 1 && width >= 1 "Invalid dimensions"

    NORTH = 1
    WEST = 2
    SOUTH = 3
    EAST = 4

    lab = Maze(height, width)

    stack = []

    push!(stack, rand(lab.nodes))
    lab.curr_node = nothing

    # while there are encountered unvisited nodes
    while !isempty(stack)

        # if lab.curr_node is nothing, get the latest node from the stack
        if isnothing(lab.curr_node)
            lab.curr_node = pop!(stack)
            lab.curr_node.visited = true
        end

        _neighbors = neighbors(lab.curr_node)

        next = randUnvisitedDirection(_neighbors)

        # if no neighbor is possible to visit
        if isnothing(next)
            # we are done with lab.curr_node then
            # set lab.curr_node to nothing, go to the beginning of the loop
            # and get a node from the stack
            lab.curr_node = nothing
            continue
        end
        
        # add the current node to the stack in case we need to backtrack
        push!(stack, lab.curr_node)

        # remove the wall between the current node and the next
        lab.curr_node.connections[next] = true
        curr_pos = lab.curr_node.position

        # get the object of the next node depending on the next direction
        if  next == NORTH
            lab.curr_node = lab.nodes[curr_pos[1] - 1, curr_pos[2]]
            # 2 nodes that share the same wall have the record of the wall. 
            # Remove the wall from the neighbor(now lab.curr_node) too
            lab.curr_node.connections[3] = true
            # mark it as visited
            lab.curr_node.visited = true
        elseif  next == WEST
            lab.curr_node = lab.nodes[curr_pos[1], curr_pos[2] - 1]
            lab.curr_node.connections[4] = true
            lab.curr_node.visited = true
        elseif  next == SOUTH
            lab.curr_node = lab.nodes[curr_pos[1] + 1, curr_pos[2]]
            lab.curr_node.connections[1] = true
            lab.curr_node.visited = true
        elseif  next == EAST
            lab.curr_node = lab.nodes[curr_pos[1], curr_pos[2] + 1]
            lab.curr_node.connections[2] = true
            lab.curr_node.visited = true
        end

        #loop
    end

    # y and x are random but they cannot be completely random.
    # They must be at edges. Therefore we restrict one of them to 2 options
    if rand(1:2) == 1
        ys = collect(1:height)
        xs = [1, width]
    else
        ys = [1, height]
        xs = collect(1:width)
    end

    start_y = rand(ys)
    start_x = rand(xs)

    if rand(1:2) == 1 && length(xs) > 1
        deleteat!(xs, findfirst(x->x==start_x, xs))
    elseif length(ys) > 1
        deleteat!(ys, findfirst(x->x==start_y, ys))
    end

    goal_y = rand(ys)
    goal_x = rand(xs)

    lab.curr_node = lab.nodes[start_y, start_x]
    n = neighbors(lab.curr_node)
    # get all the indexes of edges(where the neighbor is marked as nothing)
    edges = findall(isnothing, n)
    # select a random edge wall and remove it
    lab.curr_node.connections[rand(edges)] = true

    lab.curr_node = lab.nodes[goal_y, goal_x]
    n = neighbors(lab.curr_node)
    edges = findall(isnothing, n)
    lab.curr_node.connections[rand(edges)] = true

    lab.start = (start_y, start_x)
    lab.goal = (goal_y, goal_x)

    lab.path, lab.short_path = solve(lab)
    return lab
end
end # module MazeGeneration2