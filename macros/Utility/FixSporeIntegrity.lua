-- Fix Spore integrity for previous and Next links
function FixSporeIntegrity(Spore)
	local spore 
	spore = Spore
	local fixFunc = function(task)
		local pa = task.Parent
		local index
		for i = 1,#pa.SubTasks do
			if pa.SubTasks[i] == task then
				index = i
				break
			end
		end
		if index then
			if (index > 1 and pa.SubTasks[index - 1] ~= task.Previous) then
				task.Previous = pa.SubTasks[index-1]
			elseif (index == 1 and task.Previous) then
				task.Previous = nil
			end
			if (index < #pa.SubTasks and pa.SubTasks[index + 1] ~= task.Next) then
				task.Next = pa.SubTasks[index + 1]
			elseif (index == #pa.SubTasks and task.Next) then
				task.Next = nil
			end		
			-- Fix parents of all subTasks
			if task.SubTasks then
				for i = 1,#task.SubTasks do
					if task.SubTasks[i].Parent ~= task then
						task.SubTasks[i].Parent = task
					end
				end
				if task.SubTasks.parent ~= task.Parent.SubTasks then
					task.SubTasks.parent = task.Parent.SubTasks
				end
			end
		end
	end
	for i = 1,#spore do
		if (i > 1  and spore[i-1] ~= spore[i].Previous) then
			spore[i].Previous = spore[i-1]
		elseif (i == 1 and spore[i].Previous) then
			spore[i].Previous = nil
		end
		if (i < #spore and spore[i + 1] ~= spore[i].Next) then
			spore[i].Next = spore[i + 1]
		elseif (i == #spore and spore[i].Next) then
			spore[i].Next = nil
		end		
		if spore[i].SubTasks then
			for j = 1,#spore[i].SubTasks do
				if spore[i].SubTasks[j].Parent ~= spore[i] then
					spore[i].SubTasks[j].Parent = spore[i]
				end
			end
			if spore[i].SubTasks.parent ~= spore then	
				spore[i].SubTasks.parent = spore
			end
		end	
		spore[i]:applyFuncHier(fixFunc, nil, true)
	end
end

for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		local tasksBefore, tasksAfter
		local taskList = Karm.FilterObject.applyFilterHier(nil, v)
		tasksBefore = #taskList
		FixSporeIntegrity(v)
		local taskList = Karm.FilterObject.applyFilterHier(nil, v)
		tasksAfter = #taskList
		wx.wxMessageBox("Spore: "..k.." Tasks Before: "..tasksBefore.." Tasks After: "..tasksAfter)
	end
end

