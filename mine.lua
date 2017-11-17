NEVER_BREAK = {'ComputerCraft:CC-TurtleExpanded','minecraft:bedrock','IronChest:BlockIronChest', 'minecraft:chest'}
SHIT 		= {'Railcraft:cube','TConstruct:SearedBrick','chisel:marble','chisel:granite','chisel:diorite','minecraft:obsidian','minecraft:flowing_lava','minecraft:flowing_water','minecraft:lava','minecraft:water','chisel:andesite','chisel:limestone','minecraft:dirt','minecraft:stone','minecraft:gravel', 'minecraft:sand', 'minecraft:cobblestone'}
PROTOCOL 	= 'mine'
HOSTNAME 	= 'mineman'
NUM_RETRIES = 20

position 	= vector.new(0,0,0)
direction	= 0
--[[
		0
 
   3    *    1
 	
		2
--]]
function send(msg)
	local id = rednet.lookup(PROTOCOL, HOSTNAME)
	if id then
		rednet.send(id, os.getComputerLabel() .. ': ' .. msg, PROTOCOL)
	end
end

function is_shit(success, data)
	if success then
		for i = 1, #SHIT do 
			if SHIT[i] == data.name then
				return true
			end
		end
		return false
	end
	return true
end 

function is_important(success, data)
	if success then
		for i = 1, #NEVER_BREAK do 
			if NEVER_BREAK[i] == data.name then
				send("avoided " .. data.name)
				return true
			end
		end
		return false
	end
	return true
end

function dig_vein(i, path, moving_back)
	if path[i] == nil then
		path[i] = {}
	end
	--check up down and forward first, 
	if not moving_back then
		if #path[i] == 0 then
			s, d = turtle.inspectUp()
			if not is_shit(s,d) and not is_important(s,d) then
				path[i][#path[i]+1] = 0
			end
			s, d = turtle.inspectDown()
			if not is_shit(s,d) and not is_important(s,d) then
				path[i][#path[i]+1] = 1
			end
			for j = 1, 4 do--forward, left, back, right
				s, d = turtle.inspect()
				if not is_shit(s,d) and not is_important(s,d) then
					path[i][#path[i]+1] = 1 + j
				end
				turnLeft()
			end
		end
		if #path[i] == 0 then--go back from the path you started
			return dig_vein(i, path, true)
		else
			local dir = path[i][1]
			if dir == 0 then
				digUp()
				up()
			elseif dir == 1 then
				digDown()
				down()
			elseif dir == 2 then
				dig()
				forward()
			elseif dir == 3 then
				turnLeft()
				dig()
				forward()
			elseif dir == 4 then
				turnLeft()
				turnLeft()
				dig()
				forward()
			elseif dir == 5 then
				turnRight()
				dig()
				forward()
			end
			i = i + 1
			return dig_vein(i, path, false)
		end
	else--moving back
		i = i - 1
		if i == 0 then
			return 0
		elseif #path[i] > 0 then
			local dir = path[i][1]
			if dir == 0 then
				down()
			elseif dir == 1 then
				up()
			elseif dir == 2 then
				back()
			elseif dir == 3 then
				back()
				turnRight()
			elseif dir == 4 then
				back()
				turnLeft()
				turnLeft()
			elseif dir == 5 then
				back()
				turnLeft()
			end
			table.remove(path[i], 1)
			if #path[i] > 0 then
				return dig_vein(i, path, false)
			else
				return dig_vein(i, path, true)
			end
		end
	end
end

function refuel(f)
	for k = 1, 16 do
		turtle.select(k)
		if turtle.refuel(f) then
			return true
		end
	end
end

function dropAll()
	foundcoal = false
	for k = 1, 16 do
		turtle.select(k)
		local data = turtle.getItemDetail()
		if not foundcoal and data and data.name == 'minecraft:coal' then
			foundcoal = true
		else
			turtle.dropDown()
		end
	end
end

function hasSpace()
    for slot=1,16 do
        if turtle.getItemDetail(slot) == nil then
        	return true
        end
    end
    return false
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

function turnLeft()
	turtle.turnLeft()
	direction = direction - 1
	if direction < 0 then
		direction = 3
	end
end

function turnRight()
	turtle.turnRight()
	direction = direction + 1
	if direction > 3 then
		direction = 0
	end
end

function isForward()
	return direction == 0
end

function isRight()
	return direction == 1
end

function isBack()
	return direction == 2
end

function isLeft()
	return direction == 3
end

function digDown()
	for i=1,NUM_RETRIES do
		if is_important(turtle.inspectDown()) then
			--wait
		else
			return turtle.digDown()
		end
	end
	return false
end

function digUp()
	for i=1,NUM_RETRIES do
		if is_important(turtle.inspectUp()) then
			--wait
		else
			return turtle.digUp()
		end
	end
	return false
end

function dig()
	for i=1,NUM_RETRIES do
		if is_important(turtle.inspect()) then
			--wait
		else
			return turtle.dig()
		end
	end
	return false
end

function up()
	for i=1,NUM_RETRIES do
		if not turtle.up() then
			digUp()
		else
			position.y = position.y + 1
			return true
		end
	end
	return false
end

function down()
	for i=1,NUM_RETRIES do
		if not turtle.down() then
			digDown()
		else
			position.y = position.y - 1
			return true
		end
	end
	return false
end

function forward()
	for i=1,NUM_RETRIES do
		if not turtle.forward() then
			dig()
		else
			if isForward() then
				position.x = position.x + 1
			elseif isBack() then
				position.x = position.x - 1
			elseif isRight() then
				position.z = position.z + 1
			elseif isLeft() then
				position.z = position.z - 1
			end
			return true
		end
	end
	return false
end

function back()
	for i=1,NUM_RETRIES do
		if not turtle.back() then
			--nothing, we have to assume there is nothing behind us
		else
			if isForward() then
				position.x = position.x - 1
			elseif isBack() then
				position.x = position.x + 1
			elseif isRight() then
				position.z = position.z - 1
			elseif isLeft() then
				position.z = position.z + 1
			end
			return true
		end
	end
	return false
end

function adjust_x(x)
	local diff = position.x - x

	if diff == 0 then
		return true
	elseif diff > 0 then
		while not isBack() do
			turnLeft()
		end
	else
		while not isForward() do
			turnLeft()
		end
	end
	for i=1, math.abs(diff) do
		dig()
		forward()
	end
	local success = position.x == x
	if not success then
		send('could not fix x offset')
	else
		send('x offset was fixed')
	end
	while not isForward() do
		turnLeft()
	end
	return success
end

function adjust_y(y)
	local diff = position.y - y

	if diff == 0 then
		return true
	end
	
	if diff < 0 then
		for i=1,math.abs(diff) do
			digUp()
			up()
		end
	else
		for i=1,math.abs(diff) do
			digDown()
			down()
		end
	end
	local success = position.y == y
	if not success then
		send('could not fix y offset')
	else
		send('y offset was fixed')
	end
	return success
end

function adjust_z(z)
	local diff = position.z - z

	if diff == 0 then
		return true
	elseif diff > 0 then
		while not isLeft() do
			turnLeft()
		end
	else
		while not isRight() do
			turnLeft()
		end
	end
	for i=1, math.abs(diff) do
		dig()
		forward()
	end
	local success = position.x == x
	if not success then
		send('could not fix z offset')
	else
		send('z offset was fixed')
	end
	while not isForward() do
		turnLeft()
	end
	return success
end

function adjust_position(pos)
	if position.y < pos.y then --y first
		if adjust_y(pos.y) and adjust_x(pos.x) and adjust_z(pos.z) then
			send('pos was successfully adjusted')
			return true
		end
	elseif position.y > pos.y then--x first
		if adjust_x(pos.x) and adjust_y(pos.y) and adjust_z(pos.z) then
			send('pos was successfully adjusted')
			return true
		end
	else
		if adjust_x(pos.x) and adjust_z(pos.z) then
			send('pos was successfully adjusted')
			return true
		end
	end
	send('could not adjust position')
	return false
end

function assert_position(pos)
	if pos.x == position.x and pos.y == position.y then
		return true
	else
		local out = pos - position
		send('pos (' .. pos.x .. ', ' .. pos.y .. ')' .. 'position (' .. position.x .. ', ' .. position.y .. ')')
		return adjust_position(pos)
	end
end

function mine(height, length)
	position = vector.new(0,0)
	for i=1,height do
		digUp()
		up()
	end
	if not assert_position(vector.new(0,height,0)) then
		return false
	end
	for i=1,length do
		if turtle.getFuelLevel() < (length*1.2) then
			if not refuel(2) then
				return false
			end
		end
		if not hasSpace() then
			for k = 2, i do
				back()
			end
			for x = 1,height do
				digDown()
				down()
			end
			refuel(5)
			dropAll()
			if turtle.getFuelLevel() < (i*1.2) then
				return false
			end
			for k = 2, i do
				forward()
			end
		end
		
		dig()
		forward()
		dig_vein(1,{},false)
		
		if i % 2 == 1 then
			digDown()
			down()
		else
			digUp()
			up()
		end

		dig_vein(1,{},false)
		
		local even = i % 2 == 0

		if i == length then
			if not even then
				up()
			end
			if not assert_position(vector.new(i,height,0)) then
				return false
			end
		elseif even then
			if not assert_position(vector.new(i,height,0)) then
				return false
			end
		elseif not even then
			if not assert_position(vector.new(i,height-1,0)) then
				return false
			end
		end
	end
	turnLeft()
	turnLeft()

	for i = 1, length do
		forward()
		if turtle.getFuelLevel() == 0 then
			return false
		end
	end
	for i=1,height do
		digDown()
		down()
	end
	if not assert_position(vector.new(0,0,0)) then--only drop loot if we are right above the chest, 					
		return false--otherwise, hold onto it if we cant fix our pos
	else
		dropAll()
		turnLeft()
		turnLeft()
		return true
	end
end

rednet.open('right')

while true do
	local id, msg, prot = rednet.receive()
	local id1 = rednet.lookup(PROTOCOL, HOSTNAME)
	if id1 and id == id1 and prot == PROTOCOL then
		tokens = split(msg, ' ')
		if #tokens == 2 and tokens[1] == 'mine' then
			mine(0,tonumber(tokens[2]))
			send('end of mine, pos: (' .. position.x .. ', ' .. position.y .. ')')
		end
	end
end