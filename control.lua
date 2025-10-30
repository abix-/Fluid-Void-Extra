-------------------------------------------------------------------------------
--FACTORIO MOD: Fluid Void Extra
--A mod, redesigned from Rseding91's Fluid Void Mod, to work properly for newer versions.
--Author: Nibuja05
--Date: 15.1.2019
-------------------------------------------------------------------------------
--Date: 2025-10-30
--- Fixed crash "Fluid amount has to be positive" by removing invalid parameter from flush() call
-------------------------------------------------------------------------------

local pipeSpeed = {1000, 500, 200, 100, 50, 25, 10, 5, 1}
local defaultSpeedIndex = 3
local randomTickValue = nil

function getRandomTick()
    if not randomTickValue then
        randomTickValue = math.random(2, 59)
    end
    return randomTickValue
end

script.on_event(defines.events.on_built_entity,
	function (event)
		savePipe(event.entity)	
	end
)

script.on_event(defines.events.on_robot_built_entity,
	function (event)
		savePipe(event.entity)	
	end
)

script.on_event({defines.events.on_tick},
	function(event)
		processPipes(event)
	end
)

function savePipe(entity)
	if entity.name == "void-pipe" then
		if storage.pipes == nil then
			storage.pipes = {}
		end
		if not storage.pipes.speedClass then
			storage.pipes.speedClass = {}
		end
		if not storage.pipes.speedClass[defaultSpeedIndex] then
			storage.pipes.speedClass[defaultSpeedIndex] = {}
		end
		table.insert(storage.pipes.speedClass[defaultSpeedIndex], entity)
	end
end

function processPipes(event)
	local tick = event.tick + getRandomTick()
	local speedMultiplier = settings.global["fluid-void-extra-speedmultiplier"].value
	for k,speed in pairs(pipeSpeed) do
		if tick % (speed / speedMultiplier) == 0 then
			if storage.pipes == nil then
				return
			end
			if not storage.pipes.speedClass then
				storage.pipes.speedClass = {}
			end
			if not storage.pipes.speedClass[k] then
				storage.pipes.speedClass[k] = {}
			end
			processPipesWithSpeed(k)
		end
	end
end

function processPipesWithSpeed(speed)
	if storage.pipes ~= nil then
		for k, pipe in pairs(storage.pipes.speedClass[speed]) do
			if pipe.valid then
				if pipe.fluidbox[1] then
					local content = pipe.fluidbox.get_fluid_segment_contents(1)
                    local _, amount = next(content)
                    local capacity = pipe.fluidbox.get_capacity(1)
                    
                    -- FIX: Flush without passing the fluidbox contents to avoid invalid amount errors
                    pipe.fluidbox.flush(1)
                    
                    if amount and capacity then
                        local fill = (amount / capacity) * 100
                        
                        if settings.global["fluid-void-extra-emit-pollution"].value then
                            -- ticks per minute 3600
                            -- 50 pollution per minute: 0.0138888889 per tick
                            -- 25000 container
                            -- expected void per minute: 25000 * 10 = 250000 fluid per minute
                            -- expected fluid per tick: 250000 / 3600 = 69.44444444444444
                            -- per fluid pollution: 0.0138888889 / 69.44444444444444 = 0.0002
                            local pollutionPerAmount = 0.0002
                            local pollution = pollutionPerAmount * amount * settings.global["fluid-void-extra-pollution-multiplier"].value
                            pipe.surface.pollute(pipe.position, pollution)
                        end

                        if fill > 80 and speed < #pipeSpeed then
                            table.remove(storage.pipes.speedClass[speed], k)
                            if not storage.pipes.speedClass[speed + 1] then
                                storage.pipes.speedClass[speed + 1] = {}
                            end
                            table.insert(storage.pipes.speedClass[speed + 1], pipe)
                        elseif fill < 30 and speed > 1 then
                            table.remove(storage.pipes.speedClass[speed], k)
                            if not storage.pipes.speedClass[speed - 1] then
                                storage.pipes.speedClass[speed - 1] = {}
                            end
                            table.insert(storage.pipes.speedClass[speed - 1], pipe)
                        end
                    end
				end
			else
				table.remove(storage.pipes.speedClass[speed], k)
				if #storage.pipes.speedClass[speed] == 0 then
					storage.pipes.speedClass[speed] = nil
				end
			end
		end
	end
end