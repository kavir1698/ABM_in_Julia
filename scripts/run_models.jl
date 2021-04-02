using ABMinJulia
using Agents
using Plots
using OpenStreetMapXPlot

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

model = initialise(speed=50, β=0.1, initial_infected=80)

frames = @animate for i in 1:300
    plotmap(model.space.m)
    plotagents(model)
    step!(model, sir_step!, 1)
end

gif(frames, "plots/epidemy.gif", fps = 10)

nS(model) = count(a -> a.status == :S, allagents(model)) 
nI(model) = count(a -> a.status == :I, allagents(model)) 
nR(model) = count(a -> a.status == :R, allagents(model)) 

model = initialise(speed=50, β=0.1, initial_infected=80, detected_movement=0.05, detection_time=10)
_, mdata = run!(model, sir_step!, 200, mdata = [nS, nI, nR])

plot(1:201, mdata.nS, label="S", c=:blue)
plot!(1:201, mdata.nI, label="I", c=:red)
plot!(1:201, mdata.nR, label="R", c=:green)