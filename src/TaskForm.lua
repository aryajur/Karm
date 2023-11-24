-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Task Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     4/11/2012
-----------------------------------------------------------------------------

local prin
if Karm.Globals.__DEBUG then
	prin = print
end
local error = error
local tonumber = tonumber
local tostring = tostring
local print = prin 
local modname = ...
local wx = wx
local wxaui = wxaui
local setfenv = setfenv
local pairs = pairs
local GUI = Karm.GUI
local bit = bit
local Globals = Karm.Globals
local XMLDate2wxDateTime = Karm.Utility.XMLDate2wxDateTime
local toXMLDate = Karm.Utility.toXMLDate
local task2IncSchTasks = Karm.TaskObject.incSchTasks
local getLatestScheduleDates = Karm.TaskObject.getLatestScheduleDates
local getWorkDoneDates = Karm.TaskObject.getWorkDoneDates
local tableToString = Karm.Utility.tableToString
local getEmptyTask = Karm.getEmptyTask
local copyTask = Karm.TaskObject.copy
local collectFilterDataHier = Karm.accumulateTaskDataHier
local togglePlanningDate = Karm.TaskObject.togglePlanningDate
local type = type
local checkTask = function() 
					return checkTask
				end
local SData = function()
		return Karm.SporeData
	end

local CW = require("CustomWidgets")

----------------------------------------------------------
--module(modname)
-- NOT USING THE module KEYWORD SINCE IT DOES THIS ALSO _G[modname] = M
local M = {}
package.loaded[modname] = M
setfenv(1,M)
----------------------------------------------------------

local taskData	-- To store the task data locally
local filterData = {}

local function dateRangeChangeEvent(event)
	setfenv(1,package.loaded[modname])
	local startDate = dateStartPick:GetValue()
	local finDate = dateFinPick:GetValue()
	taskTree:dateRangeChange(startDate,finDate)
	wdTaskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

local function dateRangeChange()
	local startDate = dateStartPick:GetValue()
	local finDate = dateFinPick:GetValue()
	taskTree:dateRangeChange(startDate,finDate)
	wdTaskTree:dateRangeChange(startDate,finDate)
end

-- Function to create the task
-- If task is not nil then the previous schedules from that are copied over by starting with a copy of the task
local function makeTask(task)
	if not task then
		error("Need a task object with at least a task ID",2)
	end
	-- Copy the task, just link the sub tasks, do not remove DBDATA and update the sub task parents
	local newTask = copyTask(task,false,false,true)
--	if task then
--		-- Since copyTask does not replicate that
--		newTask.DBDATA = task.DBDATA
--	end
	newTask.Modified = true
	if pubPrivate:GetValue() == "Public" then
		newTask.Private = false
	else
		newTask.Private = true
	end 
	newTask.Title = titleBox:GetValue()
	if newTask.Title == "" then
		wx.wxMessageBox("The task Title cannot be blank. Please enter a title", "No Title Entered",wx.wxOK + wx.wxCENTRE, frame)
	    return nil
	end
	newTask.Start = toXMLDate(dateStarted:GetValue():Format("%m/%d/%Y"))
	-- newTask.TaskID = task.TaskID -- Already has task ID from copyTask
	-- Status
	newTask.Status = status:GetValue()
	-- Fin
	local todayDate = wx.wxDateTime()
	todayDate:SetToCurrent()
	todayDate = toXMLDate(todayDate:Format("%m/%d/%Y"))
	if task and task.Status ~= "Done" and newTask.Status == "Done" then
		newTask.Fin = todayDate
	elseif newTask.Status ~= "Done" then
		newTask.Fin = nil
	end
	if priority:GetValue() ~= "" then
		newTask.Priority = priority:GetValue()
	else
		newTask.Priority = nil
	end
	if DueDateEN:GetValue() then
		newTask.Due = toXMLDate(dueDate:GetValue():Format("%m/%d/%Y"))
	else
		newTask.Due = nil
	end
	-- Estimate
	if not estimate:GetValue()=="" and not tonumber(estimate:GetValue()) then
		wx.wxMessageBox("The estimate should be a number.", "Estimate not a number",wx.wxOK + wx.wxCENTRE, frame)
	    return nil
	elseif tonumber(estimate:GetValue()) then
		newTask.Estimate = 	tostring(tonumber(estimate:GetValue()))
	end
	-- Who List
	local list = whoList:getAllItems()
	if list[1] then
		local WhoTable = {[0]="Who", count = #list}
		-- Loop through all the items in the list
		for i = 1,#list do
			WhoTable[i] = {ID = list[i].itemText, Status = list[i].checked}
		end
		newTask.Who = WhoTable
	else
		wx.wxMessageBox("The task should be assigned to someone. It cannot be blank. Please choose the people responsible.", "Task not assigned",wx.wxOK + wx.wxCENTRE, frame)
	    return nil
	end
	-- Access List
	list = accList:getAllItems()
	if list[1] then
		local AccTable = {[0]="Access", count = #list}
		-- Loop through all the items in the Locked element Access List
		for i = 1,#list do
			AccTable[i] = {ID = list[i].itemText, Status = list[i].checked}
		end
		newTask.Access = AccTable
	else
		newTask.Access = nil
	end		
	-- Assignee List
	list = {}
	local itemNum = -1
	while assigList:GetNextItem(itemNum) ~= -1 do
		itemNum = assigList:GetNextItem(itemNum)
		local itemText = assigList:GetItemText(itemNum)
		list[#list + 1] = itemText
	end
	if list[1] then
		local assignee = {[0]="Assignee", count = #list}
		-- Loop through all the items in the Assignee List
		for i = 1,#list do
			assignee[i] = {ID = list[i]}
		end				
		newTask.Assignee = assignee					
	else
		newTask.Assignee = nil
	end		
	-- Comments
	if commentBox:GetValue() ~= "" then
		newTask.Comments = commentBox:GetValue()
	else 
		newTask.Comments = nil
	end
	-- Category
	if Category:GetValue() ~= "" then
		newTask.Cat = Category:GetValue()
	else
		newTask.Cat = nil
	end
	--SubCategory
	if SubCategory:GetValue() ~= "" then 
		newTask.SubCat = SubCategory:GetValue()
	else
		newTask.SubCat = nil
	end
	-- Tags
	list = TagsCtrl:getSelectedItems()
	if list[1] then
		local tagTable = {[0]="Tags", count = #list}
		-- Loop through all the items in the Tags element
		for i = 1,#list do
			tagTable[i] = list[i]
		end
		newTask.Tags = tagTable
	else
		newTask.Tags = nil
	end		
	-- Normal Schedule
	if HoldPlanning:GetValue() then
		newTask.Planning = taskTree.taskList[1].Task.Planning
	else
		list = getLatestScheduleDates(taskTree.taskList[1].Task,true)
		if list then
			local list1 = getLatestScheduleDates(newTask)
			-- Compare the schedules
			local same = true
			if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and 
			  not(list1.typeSchedule=="Commit" and list.typeSchedule == "Revs")) then
				same = false
			else
				for i = 1,#list do
					if list[i] ~= list1[i] then
						same = false
						break
					end
				end
			end
			if not same then
				-- Add the schedule here
				if not newTask.Schedules then
					newTask.Schedules = {}
				end
				if not newTask.Schedules[list.typeSchedule] then
					-- Schedule type does not exist so create it
					newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}
				end
				-- Schedule type already exists so just add it to the next index
				local newSched = {[0]=list.typeSchedule}
				local str = "WD"
				if list.typeSchedule ~= "Actual" then
					if schCommentBox:GetValue() ~= "" then
						newSched.Comment = schCommentBox:GetValue()
					end
					newSched.Updated = todayDate
					str = "DP"
				else
					error("Got Actual schedule type while processing schedule.")
				end
				-- Update the period
				newSched.Period = {[0] = "Period", count = #list}
				for i = 1,#list do
					newSched.Period[i] = {[0] = str, Date = list[i]}
				end
				newTask.Schedules[list.typeSchedule][list.index] = newSched
				newTask.Schedules[list.typeSchedule].count = list.index
			end
		end		-- if list ends here
		newTask.Planning = nil
	end		-- if HoldPlanning.GetValue() then ends
	-- Work done Schedule
	if wdHoldPlanning:GetValue() then
		newTask.PlanWorkDone = wdTaskTree.taskList[1].Task.PlanWorkDone
	else
		list = getWorkDoneDates(wdTaskTree.taskList[1].Task,true)
		if list then
			local list1 = getWorkDoneDates(newTask)
			-- Compare the schedules
			local same = true
			if not list1 or #list1 ~= #list then
				same = false
			else
				for i = 1,#list do
					if list[i] ~= list1[i] then
						same = false
						break
					end
				end
			end
			if not same then
				-- Add the schedule here
				if not newTask.Schedules then
					newTask.Schedules = {}
				end
				if not newTask.Schedules[list.typeSchedule] then
					-- Schedule type does not exist so create it
					newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}
				end
				-- Schedule type already exists so just add it to the next index
				local newSched = {[0]=list.typeSchedule, Updated = todayDate}
				local str = "WD"
				-- Update the period
				newSched.Period = {[0] = "Period", count = #list}
				for i = 1,#list do
					newSched.Period[i] = wdTaskTree.taskList[1].Task.PlanWorkDone.Period[i]
				end
				newTask.Schedules[list.typeSchedule][list.index] = newSched
				newTask.Schedules[list.typeSchedule].count = list.index
			end
		end		-- if list ends here
	end
--	print(tableToString(list))
--	print(tableToString(newTask))
	local chkTask = checkTask()
	if type(chkTask) == "function" then
		local err,msg = chkTask(newTask)
		if not err then
			msg = msg or "Error in the task. Please review."
			wx.wxMessageBox(msg, "Task Error",wx.wxOK + wx.wxCENTRE, frame)
			return nil
		end
	end
	return newTask
end

function taskFormActivate(parent, callBack, task)
	local SporeData = SData()
	-- Accumulate Filter Data across all spores
	-- Loop through all the spores
	for k,v in pairs(SporeData) do
		if k~=0 then
			collectFilterDataHier(filterData,v)
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(SporeData) do ends
	frame = wx.wxFrame(parent, wx.wxID_ANY, "Task Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)

	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		-- Create the tab book
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)
		-- Basic Task Info
		TInfo = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
				local sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				local textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Title:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				if task and task.Title then
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Title, wx.wxDefaultPosition, wx.wxDefaultSize)
				else
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
				end				
				sizer2:Add(titleBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					-- Start Date
					local sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Start Date:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Start then
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Start), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					else
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					end					
					sizer3:Add(dateStarted, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Due Date
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Due Date:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					DueDateEN = wx.wxCheckBox(TInfo, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					DueDateEN:SetValue(false)
					sizer4:Add(DueDateEN, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					if task and task.Due then
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Due), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					else
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					end	
					-- dueDate:SetRange(XMLDate2wxDateTime("1900-01-01"),XMLDate2wxDateTime("3000-01-01"))					
					sizer4:Add(dueDate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer3:Add(sizer4,1,bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Priority
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Priority:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local list = {""}
					for i = 1,#Globals.PriorityList do
						list[i+1] = Globals.PriorityList[i]
					end
					if task and task.Priority then
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Priority, wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					else
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,"", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					end
					sizer3:Add(priority, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					-- Private/Public
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Private/Public:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {"Public","Private"}
					if task and task.Private then
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,"Private", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					else
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,"Public", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					end
					sizer3:Add(pubPrivate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Status
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Status:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Status then
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Status, wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)
					else
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,Globals.StatusList[1], wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)
					end					
					sizer3:Add(status, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Estimated time
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					if Globals.EstimateUnit == "H" then
						textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Estimated Hours:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					else
						textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Estimated Days:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					end
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Estimate then
						estimate = wx.wxTextCtrl(TInfo, wx.wxID_ANY,task.Estimate, wx.wxDefaultPosition, wx.wxDefaultSize)
					else
						estimate = wx.wxTextCtrl(TInfo, wx.wxID_ANY,"", wx.wxDefaultPosition, wx.wxDefaultSize)
					end					
					sizer3:Add(estimate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				-- Comment
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Comment:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				if task and task.Comments then
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Comments, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
				else
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
				end
				sizer2:Add(commentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				

				
				TInfo:SetSizer(sizer1)
			sizer1:SetSizeHints(TInfo)
		MainBook:AddPage(TInfo, "Basic Info")				

		-- Classification Page
		TClass = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)

				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Category:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {""}
					for i = 1,#Globals.Categories do
						list[i+1] = Globals.Categories[i]
					end
					if task and task.Cat then
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,task.Cat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					else
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					end					
					sizer3:Add(Category, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Sub-Category:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {""}
					for i = 1,#Globals.SubCategories do
						list[i+1] = Globals.SubCategories[i]
					end
					if task and task.SubCat then
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,task.SubCat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					else
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					end					
					sizer3:Add(SubCategory, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Tags:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer1:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				TagsCtrl = CW.MultiSelectCtrl(TClass,filterData.Tags,nil,false,true)
				if task and task.Tags then
					TagsCtrl:AddSelListData(task.Tags)
				end
				sizer1:Add(TagsCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				TClass:SetSizer(sizer1)
			sizer1:SetSizeHints(TClass)
		MainBook:AddPage(TClass, "Classification")				

		-- People Page
		TPeople = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				-- Resources
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "People:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				resourceList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
				resourceList:InsertColumn(0,"Options")
				-- Populate the resources
				if not Globals.Resources or #Globals.Resources == 0 then
					wx.wxMessageBox("There are no people in the Globals.Resources setting. Please add a list of people to which task can be assigned", "No People found",wx.wxOK + wx.wxCENTRE, frame) 
					frame:Close()
					callBack(nil)
					return
				end
				
				for i = 1,#Globals.Resources do
					CW.InsertItem(resourceList,Globals.Resources[i])
				end
				CW.InsertItem(resourceList,Globals.User)
				sizer2:Add(resourceList, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				-- Selection boxes and buttons
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Who: (Checked=InActive)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				whoList = CW.CheckListCtrl(TPeople,false,"Inactive","Active")
				if task and task.Who then
					for i = 1,#task.Who do
						local id = task.Who[i].ID
						if task.Who[i].Status == "Active" then
							whoList:InsertItem(id)
						else
							whoList:InsertItem(id,true)
						end
					end
				end
				sizer4:Add(whoList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddAccButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveAccButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Access: (Checked=Read/Write)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				accList = CW.CheckListCtrl(TPeople,false,"Read/Write","Read Only")
				if task and task.Access then
					for i = 1,#task.Access do
						local id = task.Access[i].ID
						if task.Access[i].Status == "Read/Write" then
							accList:InsertItem(id,true)
						else
							accList:InsertItem(id)
						end
					end
				end				
				sizer4:Add(accList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Assignee:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				assigList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
				assigList:InsertColumn(0,"Assignees")
				if task and task.Assignee then
					for i = 1,#task.Assignee do
						CW.InsertItem(assigList,task.Assignee[i].ID)
					end
				end
				sizer4:Add(assigList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				TPeople:SetSizer(sizer1)
			sizer1:SetSizeHints(TPeople)
		MainBook:AddPage(TPeople, "People")				

		-- Schedule Page
		TSch = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)	-- To hold the start/end date selection controls
					dateStartPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					startDate = dateStartPick:GetValue()
					local month = wx.wxDateSpan(0,1,0,0)
					dateFinPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					sizer2:Add(dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, wx.wxALIGN_CENTER_VERTICAL), 1)
					sizer2:Add(dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 	wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				local staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, "Work Done")
					wdTaskTree = GUI.TreeGantt.newTreeGantt(TSch)
					wdTaskTree:hideTasksTree()
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					sizer3:Add(wdTaskTree.horSplitWin, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
					local wdDateLabel = wx.wxStaticText(TSch, wx.wxID_ANY, "Date: XX/XX/XXXX", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
					sizer4:Add(wdDateLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local wdHourLabel = wx.wxStaticText(TSch, wx.wxID_ANY, "Hours: ", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
					sizer4:Add(wdHourLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					local wdCommentLabel = wx.wxStaticText(TSch, wx.wxID_ANY, "Comment: ", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer2:Add(wdCommentLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local wdCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY)
					sizer2:Add(wdCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					AddwdInfoButton = wx.wxButton(TSch, wx.wxID_ANY, "Add Info", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					sizer2:Add(AddwdInfoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					wdHoldPlanning = wx.wxCheckBox(TSch, wx.wxID_ANY, "Hold Planning", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					if task.PlanWorkDone then
						wdHoldPlanning:SetValue(true)
					else
						wdHoldPlanning:SetValue(false)
					end
					sizer2:Add(wdHoldPlanning, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					sizer3:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				sizer1:Add(staticBoxSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, "Schedules")
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					taskTree = GUI.TreeGantt.newTreeGantt(TSch)
					taskTree:hideTasksTree()
					sizer3:Add(taskTree.horSplitWin, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					dateRangeChange()
				taskTree:layout()
				wdTaskTree:layout()
				local localTask1, localTask2	-- localTask1 is for the work done gantt chart and localTask2 is for the Scheduling Gantt Chart
				if not task.Title then
					localTask1 = getEmptyTask()
					localTask2 = getEmptyTask()
				else
					localTask1 = copyTask(task)
					localTask2 = copyTask(task)
					-- Since Planning and PlanWorkDone is never copied over by copyTask we do it here
					if task.Planning then
						localTask2.Planning = task.Planning
					end
					if task.PlanWorkDone then
						localTask1.PlanWorkDone = task.PlanWorkDone
					end
				end
				-- Create the 1st row for work done the task
			    wdTaskTree:Clear()
			    wdTaskTree:AddNode{Key=localTask1.TaskID, Text = localTask1.Title, Task = localTask1}
			    wdTaskTree.Nodes[localTask1.TaskID].ForeColor = GUI.nodeForeColor
				-- Create the 1st row for the task
			    taskTree:Clear()
			    taskTree:AddNode{Key=localTask2.TaskID, Text = localTask2.Title, Task = localTask2}
			    taskTree.Nodes[localTask2.TaskID].ForeColor = GUI.nodeForeColor
			    local prevKey = localTask1.TaskID
				-- Get list of mock tasks with incremental schedule
				if task and task.Schedules then
					local taskList = task2IncSchTasks(task)
					-- Now add these tasks
					for i = 1,#taskList do
						taskList[i].Planning = nil	-- To make sure that a task already having Planning does not propagate that in successive schedules
		            	taskTree:AddNode{Relative=prevKey, Relation=Globals.NEXT_SIBLING, Key=taskList[i].TaskID, Text=taskList[i].Title, Task = taskList[i]}
		            	taskTree.Nodes[taskList[i].TaskID].ForeColor = GUI.nodeForeColor
		            	prevKey = taskList[i].TaskID
		            end
				end
				-- Enable planning mode for the task
				taskTree:enablePlanningMode({localTask2},"NORMAL")
				wdTaskTree.ShowActual = true		-- Put it in show work done mode
				wdTaskTree:enablePlanningMode({localTask1},"WORKDONE") 
				-- Add the comment box
				sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				textLabel = wx.wxStaticText(TSch, wx.wxID_ANY, "Comment:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
				sizer4:Add(textLabel, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				HoldPlanning = wx.wxCheckBox(TSch, wx.wxID_ANY, "Hold Planning", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				if task.Planning then
					HoldPlanning:SetValue(true)
				else
					HoldPlanning:SetValue(false)
				end
				sizer4:Add(HoldPlanning, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				schCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
				sizer3:Add(schCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				sizer1:Add(staticBoxSizer, 2, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				TSch:SetSizer(sizer1)
			sizer1:SetSizeHints(TSch)
		MainBook:AddPage(TSch, "Schedules")	
		
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	sizer1:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	DoneButton = wx.wxButton(frame, wx.wxID_ANY, "Done", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	sizer1:Add(DoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(sizer1, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

	frame:SetSizer(MainSizer)

	-- Event handler for the Work Done elements
	local workDoneHourCommentEntry = function(task,row,col,date)
		-- First check whether the date is in the schedule
		local exist = false
		local prevHours, prevComment
		if localTask1.PlanWorkDone then
			for i = 1,#localTask1.PlanWorkDone.Period do
				if date == localTask1.PlanWorkDone.Period[i].Date then
					prevHours = localTask1.PlanWorkDone.Period[i].Hours or ""
					prevComment = localTask1.PlanWorkDone.Period[i].Comment or ""
					exist = true
					break
				end
			end
		end
		if exist then
			local wdFrame = wx.wxFrame(frame, wx.wxID_ANY, "Work Done Details for date "..date, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_FRAME_STYLE)
			local wdSizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
				-- Data entry UI
				local wdSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
					local wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, "Hours:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local wdList = {"1", "2","3","4","5","6","7","8","9","10"}
					local wdHours = wx.wxComboBox(wdFrame, wx.wxID_ANY,prevHours, wx.wxDefaultPosition, wx.wxDefaultSize,wdList)
					wdSizer3:Add(wdHours, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, "Comment:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					local w = 0.5*GUI.initFrameW
					local l = 0.5*GUI.initFrameH
					w = w - w%1
					l = l - l%1
					local wdComment = wx.wxTextCtrl(wdFrame, wx.wxID_ANY, prevComment, wx.wxDefaultPosition, wx.wxSize(w, l), wx.wxTE_MULTILINE)
					wdSizer2:Add(wdComment, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				wdSizer1:Add(wdSizer2, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Buttons
				wdSizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					local wdCancelButton = wx.wxButton(wdFrame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					wdSizer2:Add(wdCancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					local wdDoneButton = wx.wxButton(wdFrame, wx.wxID_ANY, "Done", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					wdSizer2:Add(wdDoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				wdSizer1:Add(wdSizer2, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			wdFrame:SetSizer(wdSizer1)
			wdSizer1:SetSizeHints(wdFrame)
			wdCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
				function (event)
					wdFrame:Close()
				end
			)
			wdDoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
				function (event)
					setfenv(1,package.loaded[modname])
					local hours = wdHours:GetValue()
					local comment = wdComment:GetValue()
					if tonumber(hours) then
						hours = tostring(tonumber(hours))
					else
						hours = ""
					end
					if hours ~= "" or comment ~= "" then
						-- Add the hours and Comment information to the task here
						for i = 1,#localTask1.PlanWorkDone.Period do
							if localTask1.PlanWorkDone.Period[i].Date == date then
								if hours ~= "" then
									localTask1.PlanWorkDone.Period[i].Hours = hours
								end
								if comment ~= "" then
									localTask1.PlanWorkDone.Period[i].Comment = comment
								end
								break
							end
						end
						-- Update the hours and comment box
						wdDateLabel:SetLabel("Date: "..date:sub(-5,-4).."/"..date:sub(-2,-1).."/"..date:sub(1,4))
						wdHourLabel:SetLabel("Hours: "..hours)
						wdCommentBox:SetValue(comment)
					end		-- if hours ~= "" or comment ~= "" then ends
					wdFrame:Close()
				end
			)
		    wdFrame:Layout() -- help sizing the windows before being shown
		    wdFrame:Show(true)
		end	-- if exist then ends		
	end
	
	local prevDate, wdPlanning
	wdPlanning = {PlanWorkDone = {Type = "Actual", index = 1}}
	
	local function updateHoursComment(task,row,col,date)
		if not prevDate then
			prevDate = date
		end
		-- First check whether the date is in the schedule
		local exist = false
		local existwd = false
		local perNum, wdNum
		if localTask1.PlanWorkDone then
			for i = 1,#localTask1.PlanWorkDone.Period do
				if date == localTask1.PlanWorkDone.Period[i].Date then
					perNum = i
					exist = true
					break
				end
			end
		end
		if wdPlanning.PlanWorkDone.Period then
			for i = 1,#wdPlanning.PlanWorkDone.Period do
				if date == wdPlanning.PlanWorkDone.Period[i].Date then
					wdNum = i
					existwd = true
					break
				end
			end
		end
		
		if exist then
			if not existwd then
				-- Add it to wdPlanning
				if not wdPlanning.PlanWorkDone.Period then
					wdPlanning.PlanWorkDone.Period = {}
				end
				wdPlanning.PlanWorkDone.Period[#wdPlanning.PlanWorkDone.Period + 1] = localTask1.PlanWorkDone.Period[perNum]
			end
		else
			if existwd then
				if prevDate ~= date then
					-- Add it back in the task
					togglePlanningDate(localTask1,date,"WORKDONE")
					for i = 1,#localTask1.PlanWorkDone.Period do
						if localTask1.PlanWorkDone.Period[i].Date == date then
							localTask1.PlanWorkDone.Period[i].Hours = wdPlanning.PlanWorkDone.Period[wdNum].Hours
							localTask1.PlanWorkDone.Period[i].Comment = wdPlanning.PlanWorkDone.Period[wdNum].Comment
							break
						end
					end
					-- Update GUI
					wdTaskTree:RefreshNode(localTask1)
				else
					-- Remove it from wdPlanning
					for i = wdNum,#wdPlanning.PlanWorkDone.Period - 1 do
						wdPlanning.PlanWorkDone.Period[i] = wdPlanning.PlanWorkDone.Period[i+1]
					end
					wdPlanning.PlanWorkDone.Period[#wdPlanning.PlanWorkDone.Period] = nil
				end
			end
		end
		prevDate = date
		local hours, comment
		-- Extract the hours and comments
		if localTask1.PlanWorkDone then
			for i = 1,#localTask1.PlanWorkDone.Period do
				if date == localTask1.PlanWorkDone.Period[i].Date then
					hours = localTask1.PlanWorkDone.Period[i].Hours
					comment = localTask1.PlanWorkDone.Period[i].Comment
					break
				end
			end
		end
		-- Update the hours and comment box
		wdDateLabel:SetLabel("Date: "..date:sub(-5,-4).."/"..date:sub(-2,-1).."/"..date:sub(1,4))
		if hours then
			wdHourLabel:SetLabel("Hours: "..hours)
		else
			wdHourLabel:SetLabel("Hours: ")
		end
		if comment then
			wdCommentBox:SetValue(comment)
		else
			wdCommentBox:SetValue("")
		end		
	end		-- local function updateHoursComment(task,row,col,date) ends
	
	wdTaskTree:associateEventFunc({ganttCellDblClickCallBack = workDoneHourCommentEntry, ganttCellClickCallBack = updateHoursComment})
	-- Connect event handlers to the buttons
	RemoveAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				accList.List:DeleteItem(item)			
				item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	RemoveAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				assigList:DeleteItem(item)			
				item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	RemoveWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local selItems = {}
			local item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				whoList.List:DeleteItem(item)
				item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	AddAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				accList:InsertItem(itemText)			
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)
	
	AddAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				CW.InsertItem(assigList,itemText)		
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	AddWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				whoList:InsertItem(itemText)			
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])		
			frame:Close()
			callBack(nil)
		end
	)
	
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
		function (event)
			setfenv(1,package.loaded[modname])		
			event:Skip()
			callBack(nil)
		end
	)

	DoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local newTask = makeTask(task)
			if newTask then
				callBack(newTask)
				frame:Close()
			end
		end		
	)
	
	DueDateEN:Connect(wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			if DueDateEN:GetValue() then
				dueDate:Enable(true)
			else
				dueDate:Disable()
			end
		end
	)
	
	-- Date Picker Events
	dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)
	dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)
	

    frame:Layout() -- help sizing the windows before being shown
    frame:Show(true)

end	-- function taskFormActivate(parent, callBack)