-- Macro to mark Done all tasks inside a task Marked done if they are marked as "On Track", "Not Started", "Behind" or "Pending"
local markMode, count
count = 0
for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		-- This is a spore
		if v[1].Status == "Done" then
			markMode = v[1]
		end
		--wx.wxMessageBox(v[1].Title.." "..v[1].Status)
		local nextTask = Karm.TaskObject.NextInSequence(v[1])
		while nextTask do
			if markMode then
				if Karm.TaskObject.IsUnder(nextTask,markMode) then
					if nextTask.Status == "On Track" or nextTask.Status == "Not Started" or nextTask.Status == "Behind" or nextTask.Status == "Pending" then
						nextTask.Status = "Done"
					end
				else
					if nextTask.Status == "Done" then
						markMode = nextTask
					else
						markMode = nil
					end
				end
			else
				if nextTask.Status == "Done" then
					markMode = nextTask
				end
			end
			--wx.wxMessageBox(nextTask.Title.." "..nextTask.Status.." child?"..tostring(Karm.TaskObject.IsUnder(nextTask,v[1])))
			nextTask = Karm.TaskObject.NextInSequence(nextTask)
		end
	end
end

-- Now Refresh the task tree
Karm.GUI.fillTaskTree()
