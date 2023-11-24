-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to toggle Schedule Bubbling in the Gantt Chart
-- Schedule bubbling is when the schedule of the sub-task is also seen in the parent task
-- The parent task shows that schedule with a alphabet indicating that it is a bubbled schedule date and what type of schedule it has bubbled up
-- E - Estimate
-- C - Commit
-- R - Revision
-- A - Actual
if not Karm.GUI.taskTree.Bubble then
	-- Enable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = true
	Karm.GUI.fillTaskTree()
else 
	-- Disable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = false
	Karm.GUI.fillTaskTree()
end