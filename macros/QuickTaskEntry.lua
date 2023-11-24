-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to create a task under the selected task quickly
-- The user ID in the system currently is put in the People list of the task as the responsible person
-- Get the task Title
local title = wx.wxGetTextFromUser("Please enter the task Title (Blank to Cancel)", "New Task under", "")
if title ~= "" then
	-- Create a new Event that the NewTask function needs and tell it it is SUB TASK creation
	local evt = wx.wxCommandEvent(0,Karm.GUI.ID_NEW_SUB_TASK)
	-- Create a new Task 
	Karm.NewTask(evt,title)	-- Function automatically looks for the selected node and creates a new task in relation to the selected task
end
