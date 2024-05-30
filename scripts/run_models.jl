using Pkg
Pkg.activate(".")
using Random
using ABMinJulia
using Agents
using CairoMakie
using OSMMakie

"Define agent color"
function agent_color(agent)
  if agent.status == :I
    return :red
  elseif agent.status == :S
    return :blue
  elseif agent.status == :D
    return :black
  elseif agent.status == :R
    return :green
  end
end

"Define agent shape"
function agent_marker(agent)
  if agent.status == :I
    return :utriangle
  elseif agent.status == :S
    return :circle
  else
    return :rect
  end
end

model = ABMinJulia.initialize(β=0.9, initial_infected=20,
  detected_movement=0.05, detection_time=5, N=200,
  infection_period=15, speed=0.4, movement_prob=0.05,
  n_public_places=15, n_fav_places=4, transmission_radius=1, seed=9977)

# Create a video of the simulation
abmvideo("plots/Epidemy.mp4", model;
  agent_color=agent_color, 
  agent_marker=agent_marker, agent_size=10,
  showstep=true, framerate=10, dt=1
)

# Redefine the model
model = ABMinJulia.initialize(β = 0.9, initial_infected = 20,
detected_movement = 0.05, detection_time = 5, N = 200,
infection_period=15, speed=0.4, movement_prob=0.05,
n_public_places=15, n_fav_places=4, transmission_radius=1, seed=9977)

# Define the functions to count the number of agents in each state
nS(model) = count(a -> a.status == :S, allagents(model))
nI(model) = count(a -> a.status == :I, allagents(model))
nR(model) = count(a -> a.status == :R, allagents(model))
nD(model) = count(a -> a.status == :D, allagents(model))

# Run the simulation and collect the data
nsteps = 1000
_, mdata = run!(model, nsteps, mdata = [nS, nI, nR, nD])

# Plot the data
fig = Figure();
ax = Axis(fig[1, 1], xlabel="Step", ylabel="Count")

lines!(ax, 0:nsteps, mdata.nS, color=:blue, label="S")
lines!(ax, 0:nsteps, mdata.nI, color=:red, label="I")
lines!(ax, 0:nsteps, mdata.nR, color=:green, label="R")
lines!(ax, 0:nsteps, mdata.nD, color=:orange, label="D")

# Add a legend
leg = Legend(fig[1, 2], ax, "SIR Model")
fig[1, 1] = ax

# Save the figure
CairoMakie.save("plots/sir_without_replicates.png", fig)

####
# Run the same simulation but with 7 public places
####

model = ABMinJulia.initialize(β=0.9, initial_infected=20,
  detected_movement=0.05, detection_time=5, N=200,
  infection_period=15, speed=0.4, movement_prob=0.05,
  n_public_places=15, n_fav_places=7, transmission_radius=1, seed=4710)

nsteps = 1000
_, mdata = run!(model, nsteps, mdata = [nS, nI, nR, nD])

fig = Figure();
ax = Axis(fig[1, 1], xlabel="Step", ylabel="Count")

lines!(ax, 0:nsteps, mdata.nS, color=:blue, label="S")
lines!(ax, 0:nsteps, mdata.nI, color=:red, label="I")
lines!(ax, 0:nsteps, mdata.nR, color=:green, label="R")
lines!(ax, 0:nsteps, mdata.nD, color=:orange, label="D")

# Add a legend
leg = Legend(fig[1, 2], ax, "SIR Model")
fig[1, 1] = ax

# Save the figure
CairoMakie.save("plots/sir_without_replicates_7public.png", fig)
