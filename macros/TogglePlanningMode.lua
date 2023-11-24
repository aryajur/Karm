-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to toggle the planning mode for the Tree and GAntt Chart UI
if not Karm.GUI.taskTree.Planning then 	-- Is planning mode off?
	-- Enable Planning Mode 
	Karm.GUI.taskTree:enablePlanningMode() 
else 
	-- Disable Planning Mode 
	Karm.GUI.taskTree:disablePlanningMode() 
end