-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to finalize the Planning Schedules of all the tasks in GUI, it will convert and store the planning schedule as a set schedule in the task
if Karm.GUI.taskTree.taskList then	-- Are there tasks in Planning in the GUI?
	while #Karm.GUI.taskTree.taskList > 0 do	-- Do for all planning tasks
		Karm.finalizePlanning(Karm.GUI.taskTree.taskList[1])	-- finalize Planning removes the task from the Karm.GUI.taskTree.taskList so the list shrinks and index 1 always has a fresh task
	end
end
