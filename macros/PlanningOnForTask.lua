-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to turn ON planning mode for GUI (if not already ON) and put the selected task in planning mode
-- Get the list of selected tasks
local taskList = Karm.GUI.taskTree.Selected
if #taskList == 0 then
	-- No task selected - nothing to do
	wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
else
	-- Turn on Planning Mode
	local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
	menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):Check(true) 	-- Check the planning mode menu Item (it was placed in the secon menu as the 1st time by KarmConfig.lua)
	-- Get the Task objects from the taskList which is the GUI node object
	local list = {}
	for i = 1,#taskList do
		-- Select nodes that only have actual tasks and which are not spores 
		if taskList[i].Task and not Karm.TaskObject.IsSpore(taskList[i].Task) then
			list[#list + 1] = taskList[i].Task
			-- Mark the unsaved spores list so saving message is displayed
			Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
		end
	end
	-- Enable the planning mode for the list of tasks
	Karm.GUI.taskTree:enablePlanningMode(list)
end
