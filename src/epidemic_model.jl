export initialise, sir_step!

mutable struct Person <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int,Float64}
    route::Vector{Int}
    destination::Tuple{Int,Int,Float64}
    days_infected::Int  # number of days since is infected
    status::Symbol  # :S, :I, :R, or :D (infected and detected)
    β::Float64  #  transmission probability
    fav_places::Vector{Int}  # a number of places the agent frequently visits
end

function initialise(;
    n_public_places=15,
    map_path = "data/zurich_oerlikon.osm",
    infection_period = 30,
    detection_time = 3,
    reinfection_probability = 0.05,
    detected_movement = 0.1,
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
        :movement_prob => movement_prob,
        :detected_movement => detected_movement
        )
    )
    model.public = [osm_random_road_position(model) for i in 1:n_public_places]
    
    for ind in 1:N
        start = osm_random_road_position(model) # At an intersection
        fav_places = rand(1:n_public_places, n_fav_places)
        finish = deepcopy(model.public[fav_places[1]]) # Somewhere on a road
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

function sir_move!(agent, model)
    if agent.status == :D && rand(model.rng) > model.detected_movement
        return   
    end
    move_agent!(agent, model, model.speed)

    if osm_is_stationary(agent) && rand(model.rng) < model.movement_prob
        new_destination = deepcopy(model.public[rand(agent.fav_places)])
        agent.route = osm_plan_route(agent.pos, new_destination, model)
        move_agent!(agent, model, model.speed)
    end
end

function update!(agent, model)
    if agent.status == :I || agent.status == :D
        agent.days_infected += 1
        if agent.days_infected ≥ model.infection_period
            if rand(model.rng) ≤ model.death_rate
                kill_agent!(agent, model)
            else
                agent.status = :R
                agent.days_infected = 0
            end
        end
    end
end

function transmit!(agent::AbstractAgent, model::ABM, radius)
    agent.status != :I && return
    for neighbor in nearby_agents(agent, model, radius)
        if osm_is_stationary(neighbor)
            transmit!(agent, neighbor, model)
        end
    end
end

function transmit!(infected::AbstractAgent, a2::AbstractAgent, model::ABM)
    if a2.status == :I || a2.status == :D
        return    
    end
    rand(model.rng) > infected.β && return
    
    if a2.status == :R
        rand(model.rng) > model.reinfection_probability && return
    end
    a2.status = :I
end

function sir_step!(agent, model)
    sir_move!(agent, model)
    update!(agent, model)
    transmit!(agent, model, 5)
end



