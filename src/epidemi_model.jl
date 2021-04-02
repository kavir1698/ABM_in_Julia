mutable struct Person <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int,Float64}
    route::Vector{Int}
    destination::Tuple{Int,Int,Float64}
    days_infected::Int  # number of days since is infected
    status::Symbol  # :S, :I or :R
    β::Float64  #  transmission probability
    fav_places::Vector{Int}  # a number of places the agent frequently visits
end

function initialise(;
    n_public_places=15,
    map_path = "data/zurich_oerlikon.osm",
    infection_period = 30,
    detection_time = 3,
    reinfection_probability = 0.05,
    isolated = 0.0, # in %
    death_rate = 0.03,
    N = 200,
    initial_infected = 5,
    β = 0.1,
    n_fav_places = 3, # number of frequently visited places per agent
    speed = 20,  # how fast the agents move along their ways
    movement_prob = 0.05  # probability of moving after arriving to a destination
    )
    
    m = OpenStreetMapSpace(map_path)
    model = ABM(Person, m, 
    properties = Dict(
        :public => Vector{Tuple{Int64, Int64, Float64}}(),
        :n_public_places => n_public_places,
        :infection_period => infection_period,
        :detection_time => detection_time,
        :reinfection_probability => reinfection_probability,
        :death_rate => death_rate,
        :speed => speed,
        :movement_prob => movement_prob
        )
    )
    model.public = [osm_random_road_position(model) for i in 1:n_public_places]
    
    for ind in 1:N
        start = osm_random_road_position(model) # At an intersection
        fav_places = rand(1:n_public_places, n_fav_places)
        finish = model.public[fav_places[1]] # Somewhere on a road
        route = osm_plan_route(start, finish, model)
        individual = Person(ind, start, route, finish, 0, :S, β, fav_places)
        add_agent_pos!(individual, model)
    end
    for inf in 1:initial_infected
        model[inf].days_infected = 1
        model[inf].status = :I
    end
    return model
end

function move!(agent, model)   
    if osm_is_stationary(agent) 
        if rand(model.rng) < model.movement_prob
            new_destination = model.public[rand(agent.fav_places)]
            agent.route = osm_plan_route(agent.pos, new_destination, model)
            move_agent!(agent, model, model.speed)
        end
    else
        move_agent!(agent, model, model.speed)
    end
end

function update!(agent)
    if agent.status == :I 
        agent.days_infected += 1
    end
    if agent.days_infected ≥ model.infection_period
        if rand(model.rng) ≤ model.death_rate
            kill_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
end

function transmit!(agent::AbstractAgent, model::ABM, radius)
    agent.status != :I && return
    for neighbor in nearby_agents(agent, model, radius)
        if osm_is_stationary(agent)
            transmit!(agent, neighbor, model)
        end
    end
end

function transmit!(a1::AbstractAgent, a2::AbstractAgent, model::ABM)
    a2.status == :I && return
    infected, healthy = (a1, a2)
    
    rand(model.rng) > infected.β && return
    
    if healthy.status == :R
        rand(model.rng) > model.reinfection_probability && return
    end
    healthy.status = :I
end

function agent_step!(agent, model)
    move_agent!(agent, model)
    update!(agent)
    transmit!(agent, model, 1)
end


# ----------------
function ac(agent)
    if agent.status == :I
        return :red
    elseif agent.status == :S
        return :blue
    else
        return :green
    end
end

function am(agent)
    if agent.status == :I
        return :utriangle
    elseif agent.status == :S
        return :circle
    else
        return :rect
    end
end

function plotagents(model)
    ids = model.scheduler(model)
    colors = [ac(model[i]) for i in ids]
    markers = [am(model[i]) for i in ids]
    pos = [osm_map_coordinates(model[i], model) for i in ids]
    
    scatter!(
    pos;
    markercolor = colors,
    markershapes = markers,
    label = "",
    markerstrokewidth = 0.5,
    markerstrokecolor = :black,
    markeralpha = 0.7,
    )
end

model = initialise(speed=25, β=0.3)

frames = @animate for i in 1:100
    step!(model, agent_step!)
    plotmap(model.space.m)
    plotagents(model)
end

gif(frames, "plots/epidemy.gif", fps = 15)
