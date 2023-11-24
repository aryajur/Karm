-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to list all tasks of the 1st loaded spore
local Spore
local str = ""
local count = 0
-- Get the first loaded spore from the Karm.SporeData table
for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		-- This is the 1st spore
		local task = v[1]
		while task do
			if task.Schedules and task.Status == "Not Started" then
				task.Status = "On Track"
				count = count + 1
				str = str..task.Title.."\n"
			end
			task = Karm.TaskObject.NextInSequence(task)
		end
	end
end

-- Display Done
if count > 0 then
	-- Refresh the Gantt here
	Karm.GUI.fillTaskTree()
	wx.wxMessageBox("Updated "..tostring(count).." Tasks:\n"..str)
else
	wx.wxMessageBox("No Tasks to update!")
end
