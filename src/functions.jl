using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
include("types.jl")

function frame(lab::Maze, scale, renderer)
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
    SDL_RenderClear(renderer)
    SDL_SetRenderDrawColor(renderer, 241, 242, 246, 255)
    points = []
    for node in lab.nodes
        cell_min = ((node.position[1])*scale, (node.position[2])*scale) 
        cell_max = ((node.position[1])*scale + scale, (node.position[2])*scale + scale)
        if !node.connections[1]
            SDL_RenderDrawLine(renderer, cell_min[1], cell_min[2], cell_min[1], cell_max[2])
        end
        if !node.connections[2]
            SDL_RenderDrawLine(renderer, cell_min[1], cell_min[2], cell_max[1], cell_min[2])
        end
        if !node.connections[3]
            SDL_RenderDrawLine(renderer, cell_max[1], cell_min[2], cell_max[1], cell_max[2])
        end
        if !node.connections[4]
            SDL_RenderDrawLine(renderer, cell_min[1], cell_max[2], cell_max[1], cell_max[2])
        end
    end
    for tPoint in points
        SDL_RenderDrawLine(renderer, tPoint[1][1], tPoint[1][2], tPoint[2][1], tPoint[2][2])
    end
    if !isnothing(lab.curr_node)
        SDL_SetRenderDrawColor(renderer,  94, 40, 37, 255)
        curr = Ref(SDL_Rect(lab.curr_node.position[1]*scale+2, lab.curr_node.position[2]*scale+2, scale-4, scale-4))
        SDL_RenderFillRect(renderer, curr)
    end
end
function pathFrame(lab::Maze, scale, renderer, short=false)

    if !isnothing(lab.curr_node)

        curr_y = lab.curr_node.position[1]*scale+2
        curr_x = lab.curr_node.position[2]*scale+2
        h = scale -3
        w = scale -3

        if lab.curr_node.connections[1]
            curr_y -= 2
            h += 2
        end
        if lab.curr_node.connections[2]
            curr_x -=2
            w += 2
        end
        if lab.curr_node.connections[3]
            h += 2
        end
        if lab.curr_node.connections[4]
            w += 2
        end

        if short
            SDL_SetRenderDrawColor(renderer, 37, 94, 40, 255)
        else
            SDL_SetRenderDrawColor(renderer, 94, 40, 37, 255)
        end
        curr = Ref(SDL_Rect(curr_y, curr_x, h, w))
        SDL_RenderFillRect(renderer, curr)
    end
end

function visualize(lab::Maze, scale::Int=20)
    
    @assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"
    win = SDL_CreateWindow("Maze", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, (size(lab.nodes, 1)+2)*scale, (size(lab.nodes, 2)+2)*scale, SDL_WINDOW_SHOWN)
    SDL_SetWindowResizable(win, SDL_TRUE)
    renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

    try
        close = false
        while !close
            event_ref = Ref{SDL_Event}()
            frame(lab, scale, renderer)

            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
                evt_ty = evt.type
                if evt_ty == SDL_QUIT
                    close = true
                    break
                end
            end
            
            SDL_RenderPresent(renderer)
        end
    finally
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(win)
        SDL_Quit()
    end
end
function animateMaze(height::Int, width::Int, scale::Int=20, speed::Int=1)
    created = false
    @assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"
    win = SDL_CreateWindow("Maze", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, (height+2)*scale, (width+2)*scale, SDL_WINDOW_SHOWN)
    SDL_SetWindowResizable(win, SDL_TRUE)
    renderer = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

    try
        close = false
        while !close
            event_ref = Ref{SDL_Event}()
            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
                evt_ty = evt.type
                if evt_ty == SDL_QUIT
                    close = true
                    break
                end
            end
            if !created
                @assert height >= 1 && width >= 1 "Invalid dimensions"

                NORTH = 1
                WEST = 2
                SOUTH = 3
                EAST = 4

                lab = Maze(height, width)

                stack = []

                push!(stack, rand(lab.nodes))

                # while there are encountered unvisited nodes
                while !isempty(stack)
                    
                    # if lab.curr_node is nothing, get the latest node from the stack
                    if isnothing(lab.curr_node)
                        lab.curr_node = pop!(stack)
                        lab.curr_node.visited = true
                    end
                    frame(lab, scale, renderer)
                    SDL_RenderPresent(renderer)
                    SDL_Delay(floor(Int, 50/speed))
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
                
                frame(lab, scale, renderer)
                SDL_RenderPresent(renderer)
                SDL_Delay(floor(Int, 250/speed))

                lab.curr_node = lab.nodes[goal_y, goal_x]
                n = neighbors(lab.curr_node)
                edges = findall(isnothing, n)
                lab.curr_node.connections[rand(edges)] = true

                frame(lab, scale, renderer)
                SDL_RenderPresent(renderer)
                SDL_Delay(floor(Int, 250/speed))

                lab.start = (start_y, start_x)
                lab.goal = (goal_y, goal_x)

                lab.path, lab.short_path = solve(lab)

                lab.curr_node = nothing
                frame(lab, scale, renderer)
                SDL_RenderPresent(renderer)
                for node in lab.path
                    lab.curr_node = node
                    pathFrame(lab, scale, renderer)
                    SDL_RenderPresent(renderer)
                    SDL_Delay(floor(Int, 50/speed))
                end
                for node in lab.short_path
                    lab.curr_node = node
                    pathFrame(lab, scale, renderer, true)
                    SDL_RenderPresent(renderer)
                    SDL_Delay(floor(Int, 50/speed))
                end

                created = true
            end
            SDL_RenderPresent(renderer)
        end
    finally
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(win)
        SDL_Quit()
    end
end

function solve(maze::Maze)
    NORTH = 1
    WEST = 2
    SOUTH = 3
    EAST = 4
    diffs = [(-1, 0), (0, -1), (1, 0), (0, 1)]
    #get the start and end position
    start = maze.start
    goal = maze.goal
    

    if !isnothing(start)&&!isnothing(goal)

        startNode = maze.nodes[start[1], start[2]]
        goalNode = maze.nodes[goal[1],goal[2]]

        height = size(maze.nodes, 1)
        width = size(maze.nodes, 2)

        #get the first direction
        #if coming southwards, point must be (1, ...)
        if start[1] == 1 && startNode.connections[1]
            direction = SOUTH
        #if coming northwards, point must be (height, ...)
        elseif start[1] == height && startNode.connections[3]
            direction = NORTH
        #if coming eastwards, point must be (..., 1)
        elseif start[2] == 1 && startNode.connections[2]
            direction = EAST
        #if coming westwards, point must be (..., width)
        elseif start[2] == width && startNode.connections[4]
            direction = WEST
        end

        #initialize the path
        solution = [startNode]

        #initialize the shortes path
        short_sol = Vector{Node}()
        #initialize the circles (unnecessary passed nodes)
        circle = Vector{Node}()
        #we need a set to save passed nodes
        path_set = Set{Node}()

        curr_node = startNode


        while curr_node != goalNode
            #to find out, where the right side is
            right = mod(direction + 2, 4)+1

            #to find out, where the left side is
            left = mod(direction, 4) + 1
            #opposite side, in order we have to go back
            opp = mod(direction + 1, 4) + 1

            #if there is no wall to the right
            if curr_node.connections[right]
                #get the next node's position
                i, j = curr_node.position[1], curr_node.position[2]
                next_i, next_j = diffs[right]

                #add the next node to the path
                push!(solution, maze.nodes[i+next_i, j+next_j])
                #change the direction
                #since we turned to the right
                direction = right

            #if we cannot turn right, we try to go forward
            elseif curr_node.connections[direction]
                i, j = curr_node.position[1], curr_node.position[2]
                next_i, next_j = diffs[direction]

                push!(solution, maze.nodes[i+next_i, j+next_j])

            #if we cannot go forward, we try to go to the left
            elseif curr_node.connections[left]
                i, j = curr_node.position[1], curr_node.position[2]
                next_i, next_j = diffs[left]

                push!(solution, maze.nodes[i+next_i, j+next_j])
                direction = left
            #if nothign worked so far, we have to get back
            else 
                direction = opp
            end

            #check, if there is a circle
            if curr_node in path_set
                #find the revisited node
                for i in 1:length(short_sol)
                    if short_sol[i] == curr_node
                        k = i
                        #add the new circle to circles
                        #delete the circe form the shortes path
                        while length(short_sol) > k
                            push!(circle, pop!(short_sol))
                        end 
                        #since the revisited node is still part of the path
                        #it doesn't belong to the circle vector
                        pop!(short_sol)
                        break
                    end 
                end 
            end
            #update the shorter path, save the (updated) direction
            push!(short_sol, curr_node)
            #add the node to the set of visited nodes
            push!(path_set, curr_node)
            
            #update current node
            curr_node = solution[end]

        end 
        

        #get the last direction
        #if going southwards, point must be (height, ...)
        if start[1] == height && startNode.connections[3]
            direction = SOUTH
        #if going northwards, point must be (1, ...)
        elseif start[1] == 1 && startNode.connections[1]
            direction = NORTH
        #if going eastwards, point must be (..., width)
        elseif start[2] == width && startNode.connections[4]
            direction = EAST
        #if going westwards, point must be (..., 1)
        elseif start[2] == 1 && startNode.connections[2]
            direction = WEST
        end

        #add the end node to the path
        push!(short_sol, goalNode)
        return (solution, short_sol)

    end
        
    #if the maze is empty, there is no path
    return nothing
end