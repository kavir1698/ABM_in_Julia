using ABMinJulia
using Agents
using Plots
using OpenStreetMapXPlot

"Define agent color"
function ac(agent)
    if agent.status == :I
        return :red
    elseif agent.status == :S
        return :blue
    elseif agent.status == :D
        return :black
    else
        return :green
    end
end

"Define agent shape"
function am(agent)
    if agent.status == :I
        return :utriangle
    elseif agent.status == :S
        return :circle
    else
        return :rect
    end
end

"Scatter plot the agents"
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
        markeralpha = 0.7
    )
end

model = ABMinJulia.initialize(speed = 50, β = 0.1, initial_infected = 80)

frames = @animate for i = 1:300
    plotmap(model.space.m)
    plotagents(model)
    step!(model, sir_step!, 1)
end

gif(frames, "plots/epidemy.gif", fps = 10)

nS(model) = count(a -> a.status == :S, allagents(model))
nI(model) = count(a -> a.status == :I, allagents(model))
nR(model) = count(a -> a.status == :R, allagents(model))
nD(model) = count(a -> a.status == :D, allagents(model))

model = ABMinJulia.initialize(β = 0.9, initial_infected = 20,
    detected_movement = 0.05, detection_time = 5, N = 200,
    infection_period = 15, movement_per_day = 5, speed = 400,
    n_public_places = 15)

nsteps = 500
_, mdata = run!(model, sir_step!, nsteps, mdata = [nS, nI, nR, nD])

plot(0:nsteps, mdata.nS, label = "S", c = :blue, xlabel = "Step", ylabel = "Count")
plot!(0:nsteps, mdata.nI, label = "I", c = :red)
plot!(0:nsteps, mdata.nR, label = "R", c = :green)
plot!(0:nsteps, mdata.nD, label = "D", c = :orange)

savefig("plots/sir_without_replicates.png")

model = ABMinJulia.initialize(β = 0.9, initial_infected = 20,
    detected_movement = 0.05, detection_time = 5, N = 200,
    infection_period = 15, movement_per_day = 5, speed = 400,
    n_public_places = 5)

nsteps = 500
_, mdata = run!(model, sir_step!, nsteps, mdata = [nS, nI, nR, nD])

plot(0:nsteps, mdata.nS, label = "S", c = :blue, xlabel = "Step", ylabel = "Count")
plot!(0:nsteps, mdata.nI, label = "I", c = :red)
plot!(0:nsteps, mdata.nR, label = "R", c = :green)
plot!(0:nsteps, mdata.nD, label = "D", c = :orange)

savefig("plots/sir_without_replicates_5public.png")