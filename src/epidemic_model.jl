export initialise, sir_step!

@agent struct Person(OSMAgent)
  destination::Tuple{Int,Int,Float64}
  days_infected::Int  # number of days since is infected
  status::Symbol  # :S, :I, :R, or :D (susceptible, infected, recovered or detected)
  β::Float64  #  transmission probability
  fav_places::Vector{Int}  # a number of places the agent frequently visits
end

function initialize(;
  n_public_places = 15,
  map_path = "data/zurich_oerlikon.osm",
  infection_period = 20,
  detection_time = 3,
  reinfection_probability = 0.05,
  detected_movement = 0.1,
  death_rate = 0.03,
  N = 200,
  initial_infected = 40,
  β = 0.1,
  n_fav_places = 3,
  speed = 0.1, # km/step
  movement_prob = 0.05,
  transmission_radius = 0.05,
  seed = 1234
  )
  
  m = OpenStreetMapSpace(map_path)
  model = StandardABM(Person, m,
  properties=Dict(
  :public => Vector{Tuple{Int64,Int64,Float64}}(),
  :n_public_places => n_public_places,
  :infection_period => infection_period,
  :detection_time => detection_time,
  :reinfection_probability => reinfection_probability,
  :death_rate => death_rate,
  :speed => speed,
  :movement_prob => movement_prob,
  :detected_movement => detected_movement,
  :transmission_radius => transmission_radius
  ),
  agent_step! = sir_step!,
  rng=Random.MersenneTwister(seed)
  )
  
  model.public = [random_position(model) for i = 1:n_public_places]
  
  for ind in 1:N
    start = random_position(model)
    fav_places = rand(1:n_public_places, n_fav_places)
    finish = deepcopy(model.public[fav_places[1]])
    agent = add_agent!(start, model, finish, 0, :S, β, fav_places)
    plan_route!(agent, agent.destination, model)
  end
  
  for inf in 1:initial_infected
    model[inf].days_infected = 1
    model[inf].status = :I
  end
  
  return model
end

function sir_move!(agent, model)
  if agent.status == :D && rand(abmrng(model)) > model.detected_movement
    return
  end
  
  if !is_stationary(agent, model)
    move_along_route!(agent, model, model.speed)
  end
  if is_stationary(agent, model) && rand(abmrng(model)) <= model.movement_prob
    # make sure the agent does choose the same place
    fav_places_copy = deepcopy(agent.fav_places)
    deleteat!(fav_places_copy, findfirst(x -> model.public[x] == agent.destination, fav_places_copy))
    agent.destination = model.public[rand(fav_places_copy)]

    plan_route!(agent, agent.destination, model)
    move_along_route!(agent, model, model.speed)
  end
end

function update!(agent, model)
  if agent.status == :I || agent.status == :D
    agent.days_infected += 1
    if agent.days_infected ≥ model.infection_period
      if rand(abmrng(model)) ≤ model.death_rate
        remove_agent!(agent, model)
      else
        agent.status = :R
        agent.days_infected = 0
      end
    elseif agent.days_infected >= model.detection_time && agent.status == :I
      agent.status = :D
    end
  end
end

function transmit!(agent::AbstractAgent, model::ABM)
  if agent.status != :I && agent.status != :D
    return
  end
  for neighbor in nearby_agents(agent, model, model.transmission_radius)
    transmit!(agent, neighbor, model)
  end
end

function transmit!(infected::AbstractAgent, a2::AbstractAgent, model::ABM)
  if a2.status == :I || a2.status == :D
    return
  elseif a2.status == :R && rand(abmrng(model)) > model.reinfection_probability
    return
  elseif rand(abmrng(model)) > infected.β
    return
  else
    a2.status = :I
  end
end

function sir_step!(agent, model)
  transmit!(agent, model)
  update!(agent, model)
  sir_move!(agent, model)
end
