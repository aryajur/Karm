-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to display the Parent Hierarchy of the selected task
-- Get the list of selected tasks
local taskList = Karm.GUI.taskTree.Selected
if #taskList == 0 then
	-- No task selected - nothing to do
	wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
else
	local currTask = taskList[1].Task
	local hier = "--> "..currTask.Title
	while currTask.Parent do
		hier = "--> "..currTask.Parent.Title.."\n"..hier
		currTask = currTask.Parent
	end
	-- Display the hierarchy
	wx.wxMessageBox(hier)
end
