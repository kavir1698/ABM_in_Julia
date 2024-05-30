"""
A mutable structure representing an agent in a 2D environment. 
The agent has an id and a position (x, y).
"""
mutable struct SimpleAgentFlexible{T<:Signed}
  id::T
  x::T
  y::T
end

"""
move!(agent, env)

Move the agent in a random direction in the environment `env`.
The agent's position is adjusted to stay within the bounds of the environment.
"""
function move!(agent, env)
  agent.x += rand(-1:1)
  agent.y += rand(-1:1)
  envsize = size(env)
  if agent.x < 1
    agent.x = 1
  elseif agent.x > envsize[1]
    agent.x = envsize[1]
  end
  if agent.y < 1
    agent.y = 1
  elseif agent.y > envsize[2]
    agent.y = envsize[2]
  end
end

"""
update_env!(env, agent)

Update the environment `env` based on the agent's position.
"""
function update_env!(env, agent)  
  env[agent.x, agent.y] = 1  
end

# Initialize environment and agent
env = zeros(Int, 10, 10)
agent1 = SimpleAgentFlexible(Int32(1), Int32(4), Int32(5))

# Initialize a larger environment and multiple agents
env = zeros(Int, 100, 100)
agents = [SimpleAgentFlexible(i, rand(1:100), rand(1:100)) for i in 1:10]

# Simulate agent movement for 200 timesteps
for timestep in 1:200
  for agent in agents
    update_env!(env, agent)
    move!(agent, env)
  end
end

# Create a figure and axis for plotting
fig = Figure(size=(600, 600), aspect=1)
ax = Axis(fig[1, 1])
hidespines!(ax)  # # Hide the axis lines
hidexdecorations!(ax)  # No x-ticks
hideydecorations!(ax)  # No y-ticks

# Plot the environment using a heatmap
CairoMakie.heatmap!(ax, env, colormap=:greys)

# Save the plot to a file
save("plots/simple100x100.png", fig)
