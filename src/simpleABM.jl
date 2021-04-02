pyplot()

mutable struct SimpleAgentFlexible{T<:Signed}
    id::T
    x::T
    y::T
end

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

function update_env!(env, agent)  
    env[agent.x, agent.y] = 1  
end

env = zeros(Int, 10, 10)
agent1 = SimpleAgentFlexible(Int32(1), Int32(4), Int32(5))

env = zeros(Int, 100, 100)
agents = [SimpleAgentFlexible(i, rand(1:100), rand(1:100)) for i in 1:10]

plots = []
for timestep in 1:200
    for agent in agents
        update_env!(env, agent)
        move!(agent, env)
    end
end
p = heatmap(env, aspect_ratio = 1,
    xaxis=false,yaxis=false,xticks=false,yticks=false,legend=false
    )
savefig("plots/simple100x100.png")
