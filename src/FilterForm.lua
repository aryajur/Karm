-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Criteria Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     2/09/2012
-----------------------------------------------------------------------------
local prin
if Karm.Globals.__DEBUG then
	prin = print
end
local print = prin 
local wx = wx
local io = io
local wxaui = wxaui
local bit = bit
local GUI = Karm.GUI
local tostring = tostring
local loadfile = loadfile
local loadstring = loadstring
local setfenv = setfenv
local string = string
local Globals = Karm.Globals
local setmetatable = setmetatable
local NewID = Karm.NewID
local type = type
local math = math
local error = error
local modname = ...
local tableToString = Karm.Utility.tableToString
local pairs = pairs
local applyFilterHier = Karm.FilterObject.applyFilterHier
local collectFilterDataHier = Karm.accumulateTaskDataHier
local CW = require("CustomWidgets")


local GlobalFilter = function() 
		return Karm.Filter 
	end
	
local SData = function()
		return Karm.SporeData
	end

local MainFilter
local SporeData

----------------------------------------------------------
--module(modname)
-- NOT USING THE module KEYWORD SINCE IT DOES THIS ALSO _G[modname] = M
local M = {}
package.loaded[modname] = M
setfenv(1,M)
----------------------------------------------------------

-- Local filter table to store the filter criteria
local filter = {}
local filterData = {}
local FCombMap = {count = 0}


local noStr = {
	Cat = Globals.NoCatStr,
	SubCat = Globals.NoSubCatStr,
	Priority = Globals.NoPriStr,
	Due = Globals.NoDateStr,
	Fin = Globals.NoDateStr,
	ScheduleRange = Globals.NoDateStr,
	Tags = Globals.NoTagStr,
	Access = Globals.NoAccessIDStr
}

local function SelTaskPress(event)
	setfenv(1,package.loaded[modname])
	local frame = wx.wxFrame(frame, wx.wxID_ANY, "Select Task", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
	local taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*GUI.initFrameW, 0.9*GUI.initFrameH),bit.bor(wx.wxTR_SINGLE,wx.wxTR_HAS_BUTTONS))
	MainSizer:Add(taskTree, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
	local OKButton = wx.wxButton(frame, wx.wxID_ANY, "OK", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CheckBox = wx.wxCheckBox(frame, wx.wxID_ANY, "Subtasks", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	
	if filter.TasksSet and filter.TasksSet[1].Children then
		CheckBox:SetValue(true)
	end
	buttonSizer:Add(OKButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CheckBox,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
	-- Now populate the tree with all the tasks
	
	-- Add the root
	local root = taskTree:AddRoot("Task Spores")
	local treeData = {}
	treeData[root:GetValue()] = {Key = Globals.ROOTKEY, Parent = nil, Title = "Task Spores"}
    if SporeData[0] > 0 then
-- Populate the tree control view
		local count = 0
		-- Loop through all the spores
        for k,v in pairs(SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				-- Find the name of the file
				local strVar
        		local intVar1 = -1
				count = count + 1
            	for intVar = #k,1,-1 do
                	if string.sub(k, intVar, intVar) == "." then
                    	intVar1 = intVar
                	end
                	if string.sub(k, intVar, intVar) == "\\" or string.sub(k, intVar, intVar) == "/" then
                    	strVar = string.sub(k, intVar + 1, intVar1-1)
                    	break
                	end
            	end
            	-- Add the spore node
	            local currNode = taskTree:AppendItem(root,strVar)
				treeData[currNode:GetValue()] = {Key = Globals.ROOTKEY..k, Parent = root, Title = strVar}
				if filter.TasksSet and #filter.TasksSet[1].TaskID > #Globals.ROOTKEY and 
				  string.sub(filter.TasksSet[1].TaskID,#Globals.ROOTKEY + 1, -1) == k then
					taskTree:EnsureVisible(currNode)
					taskTree:SelectItem(currNode)
				end
				local taskList = applyFilterHier(filter, v)
-- Now add the tasks under the spore in the TaskTree
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	                -- Add the 1st element under the spore
	                local parent = currNode
		            currNode = taskTree:AppendItem(parent,taskList[1].Title)
					treeData[currNode:GetValue()] = {Key = taskList[1].TaskID, Parent = parent, Title = taskList[1].Title}
	                for intVar = 2,taskList.count do
	                	local cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k
	                	local cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key
	                	local cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = treeData[currNode:GetValue()].Parent
		                	cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k
		                	cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key
		                	cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
		                parent = currNode
			            currNode = taskTree:AppendItem(parent,taskList[intVar].Title)
						treeData[currNode:GetValue()] = {Key = taskList[intVar].TaskID, Parent = parent, Title = taskList[intVar].Title}
                    end
	            end  -- if taskList.count > 0 then ends
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(SporeData) do ends
    end  -- if SporeData[0] > 0 then ends
    
	-- Expand the root element
	taskTree:Expand(root)
	
	-- Connect the button events
	OKButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
	function (event)
		setfenv(1,package.loaded[modname])
		local sel = taskTree:GetSelection()
		-- Setup the filter
		filter.TasksSet = {}
		if treeData[sel:GetValue()].Key == Globals.ROOTKEY then
			filter.TasksSet = nil
		else
			filter.TasksSet[1] = {}
			-- This is a spore node
			if CheckBox:GetValue() then
				filter.TasksSet[1].Children = true
			end
			filter.TasksSet[1].TaskID = treeData[sel:GetValue()].Key
			filter.TasksSet[1].Title =  treeData[sel:GetValue()].Title
		end
		-- Setup the label properly
		if filter.TasksSet then
			if filter.TasksSet[1].Children then
				FilterTask:SetLabel(taskTree:GetItemText(sel).." and Children")
			else
				FilterTask:SetLabel(taskTree:GetItemText(sel))
			end
		else
			FilterTask:SetLabel("No Task Selected")
		end	
		frame:Close()
	end
	)
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
	function (event)
		setfenv(1,package.loaded[modname])		
		frame:Close()
	end
	)
	
	
	frame:SetSizer(MainSizer)
	MainSizer:SetSizeHints(frame)
	frame:Layout()
	frame:Show(true)
end		-- local function SelTaskPress(event) ends

local function initializeFilterForm(filterData)
	-- Clear Task Selection
	FilterTask:SetLabel("No Task Selected")
	-- Clear Category
	CatCtrl:ResetCtrl()
	-- Clear Sub-Category
	SubCatCtrl:ResetCtrl()
	-- Clear Priority
	PriCtrl:ResetCtrl()
	-- Clear Status
	StatCtrl:ResetCtrl()
	-- Clear Tags List
	TagList:DeleteAllItems()
	TagBoolCtrl:ResetCtrl()
	-- Clear Dates
	dateStarted:ResetCtrl()
	dateFinished:ResetCtrl()
	dateDue:ResetCtrl()
	-- Who and Access
	whoCtrl:ResetCtrl()
	WhoBoolCtrl:ResetCtrl()
	accCtrl:ResetCtrl()
	accBoolCtrl:ResetCtrl()
	-- Schedules
	schDateRanges:ResetCtrl()
	SchBoolCtrl:ResetCtrl()
	filter = {}		-- Clear the filter
	-- Fill the data in the controls
	CatCtrl:AddListData(filterData.Cat)
	SubCatCtrl:AddListData(filterData.SubCat)
	PriCtrl:AddListData(filterData.Priority)
	StatCtrl:AddListData(Globals.StatusList)
	ScriptBox:Clear()
	if filterData.Tags then
		for i=1,#filterData.Tags do
			CW.InsertItem(TagList,filterData.Tags[i])
		end
	end
	if filterData.Who then
		for i=1,#filterData.Who do
			whoCtrl:InsertItem(filterData.Who[i], false)
		end
	end
	
	if filterData.Access then
		for i=1,#filterData.Access do
			accCtrl:InsertItem(filterData.Access[i], false)
		end
	end
end

local function setfilter(f)
	-- Initialize the form
	initializeFilterForm(filterData)
	if f.Map then
		-- This is a filter Combination
		local fil = f
		-- Fill the tree
		FCombBoolCtrl:setExpression(fil.Bool)
		FCombMap = fil.Map
		f = fil.Map["F"..fil.Map.count].Filter	-- This would set this filter in the GUI
		dnBox:SetValue(fil.Map["F"..fil.Map.count].Name)
		ApplyCombButton:SetLabel("Apply Combination")
		ApplyCombButton:Enable(true)
	end
	-- Set the task details
	local str = ""
	if f.Tasks then
		filter.TasksSet = {[1]={}}  -- TO store the already selected task
		if f.Tasks[1].Title then
			str = f.Tasks[1].Title
			filter.TasksSet[1].Title = str
		else
			for k,v in pairs(SporeData) do
				if k~=0 then
					local taskList = applyFilterHier({Tasks={[1]={TaskID = f.Tasks.TaskID}}},v)
					if #taskList then
						str = taskList[1].Title
						break
					end
				end		-- if k~=0 then ends
			end		-- for k,v in pairs(SporeData) do ends
			if not str then
				str = "TASK ID: "..f.Tasks[1].TaskID
				filter.TasksSet[1].Title = str
			end
		end	
		filter.TasksSet[1].TaskID = f.Tasks[1].TaskID
		filter.TasksSet[1].Children = f.Tasks[1].Children
		if f.Tasks[1].Children then
			str = str.." and Children"
		end
		FilterTask:SetLabel(str)
	end
	-- Set the ShowHierarchy flag
	if f.DontShowHierarchy then
		ShowHierarchyBox:SetValue(false)
	else
		ShowHierarchyBox:SetValue(true)
	end
	-- Set Category data
	if f.Cat then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local catStr = string.match(f.Cat,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(catStr,-1,-1)~="," then
			catStr = catStr .. ","
		end
		local items = {}
		for cat in string.gmatch(catStr,"(.-),") do
			-- Trim leading and trailing spaces
			cat = string.match(cat,"^%s*(.-)%s*$")			
			-- Check if it matches Globals.NoCatStr
			if cat == Globals.NoCatStr then
				CatCtrl.CheckBox:SetValue(true)
			else
				items[#items + 1] = cat
			end
		end
		CatCtrl:AddSelListData(items)
	end		-- if f.Cat then ends
	-- Set Sub-Category data
	if f.SubCat then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local subCatStr = string.match(f.SubCat,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(subCatStr,-1,-1)~="," then
			subCatStr = subCatStr .. ","
		end
		local items = {}
		for subCat in string.gmatch(subCatStr,"(.-),") do
			-- Trim leading and trailing spaces
			subCat = string.match(subCat,"^%s*(.-)%s*$")			
			-- Check if it matches Globals.NoSubCatStr
			if subCat == Globals.NoSubCatStr then
				SubCatCtrl.CheckBox:SetValue(true)
			else
				items[#items + 1] = subCat
			end
		end
		SubCatCtrl:AddSelListData(items)
	end		-- if f.Cat then ends
	if f.Tags then
		TagBoolCtrl:setExpression(f.Tags)
	end		-- if f.Tags then ends
	-- Set Priority data
	if f.Priority then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local priStr = string.match(f.Priority,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(priStr,-1,-1)~="," then
			priStr = priStr .. ","
		end
		local items = {}
		for pri in string.gmatch(priStr,"(.-),") do
			-- Trim leading and trailing spaces
			pri = string.match(pri,"^%s*(.-)%s*$")			
			-- Check if it matches Globals.NoPriStr
			if pri == Globals.NoPriStr then
				PriCtrl.CheckBox:SetValue(true)
			else
				items[#items + 1] = pri
			end
		end
		PriCtrl:AddSelListData(items)
	end		-- if f.Priority then ends
	-- Set Status data
	if f.Status then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local statStr = string.match(f.Status,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(statStr,-1,-1)~="," then
			statStr = statStr .. ","
		end
		local items = {}
		for stat in string.gmatch(statStr,"(.-),") do
			-- Trim leading and trailing spaces
			stat = string.match(stat,"^%s*(.-)%s*$")			
			items[#items + 1] = stat
		end
		StatCtrl:AddSelListData(items)
	end		-- if f.Status then ends
	-- Who items
	if f.Who then
		WhoBoolCtrl:setExpression(f.Who)
	end
	-- Access items
	if f.Access then
		accBoolCtrl:setExpression(f.Access)
	end		-- if f.Tags then ends
	-- Set Start Date data
	if f.Start then
		do
			-- Separate out the items in the comma
			-- Trim the string from leading and trailing spaces
			local strtStr = string.match(f.Start,"^%s*(.-)%s*$")
			-- Make sure the string has "," at the end
			if string.sub(strtStr,-1,-1)~="," then
				strtStr = strtStr .. ","
			end
			local items = {}
			for strt in string.gmatch(strtStr,"(.-),") do
				-- Trim leading and trailing spaces
				strt = string.match(strt,"^%s*(.-)%s*$")
				if strt ~= "" then			
					items[#items + 1] = strt
				end
			end
			dateStarted:setRanges(items)
		end		-- do for f.Start
	end	
	-- Set Due Date data
	if f.Due then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local dueStr = string.match(f.Due,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(dueStr,-1,-1)~="," then
			dueStr = dueStr .. ","
		end
		local items = {}
		dateDue:setCheckBoxState(nil)
		for due in string.gmatch(dueStr,"(.-),") do
			-- Trim leading and trailing spaces
			due = string.match(due,"^%s*(.-)%s*$")
			if due == noStr.Due then
				dateDue:setCheckBoxState(true)
			elseif due ~= "" then			
				items[#items + 1] = due
			end
		end
		dateDue:setRanges(items)
	end		-- if f.Due ends here	
	-- Set Finish Date data
	if f.Fin then
		-- Separate out the items in the comma
		-- Trim the string from leading and trailing spaces
		local finStr = string.match(f.Fin,"^%s*(.-)%s*$")
		-- Make sure the string has "," at the end
		if string.sub(finStr,-1,-1)~="," then
			finStr = finStr .. ","
		end
		local items = {}
		dateFinished:setCheckBoxState(nil)
		for fin in string.gmatch(finStr,"(.-),") do
			-- Trim leading and trailing spaces
			fin = string.match(fin,"^%s*(.-)%s*$")
			if fin == noStr.Fin then
				dateFinished:setCheckBoxState(true)
			elseif fin ~= "" then			
				items[#items + 1] = fin
			end
		end
		dateFinished:setRanges(items)
	end		-- if f.Due ends here	
	-- Set the Schedules Data
	if f.Schedules then
		SchBoolCtrl:setExpression(f.Schedules)
	end		-- if f.Schedules ends here
	-- Custom Script
	if f.Script then
		ScriptBox:SetValue(f.Script)
	end
end

local function synthesizeFilter()
	local f = {}
	-- Get the tasks information
	if filter.TasksSet then
		f.Tasks = filter.TasksSet
	end
	-- Get the ShowHierarchy Information
	if ShowHierarchyBox:GetValue() then
		f.DontShowHierarchy = nil
	else
		f.DontShowHierarchy = true
	end
	-- Get Who information here
	f.Who = WhoBoolCtrl:BooleanExpression()
	-- Date Started
	local str = ""
	local items = dateStarted:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end
	if str ~= "" then 
		f.Start = str:sub(1,-2)
	end
	-- Date Finished
	str = ""
	items = dateFinished:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end 
	if items[0] then
		str = str..Globals.NoDateStr..","
	end
	if str ~= "" then
		f.Fin = str:sub(1,-2)
	end
	-- Access information
	f.Access = accBoolCtrl:BooleanExpression()
	-- Status Information
	str = ""
	items = StatCtrl:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end
	if str ~= "" then 
		f.Status = str:sub(1,-2)
	end
	-- Priority
	str = ""
	items = PriCtrl:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end 
	if items[0] then
		str = str..Globals.NoPriStr..","
	end
	if str ~= "" then
		f.Priority = str:sub(1,-2)
	end
	-- Due Date
	str = ""
	items = dateDue:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end 
	if items[0] then
		str = str..Globals.NoDateStr..","
	end
	if str ~= "" then
		f.Due = str:sub(1,-2)
	end
	-- Category
	str = ""
	items = CatCtrl:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end 
	if items[0] then
		str = str..Globals.NoCatStr..","
	end
	if str ~= "" then
		f.Cat = str:sub(1,-2)
	end
	-- Sub-Category
	str = ""
	items = SubCatCtrl:getSelectedItems()
	for i = 1,#items do
		str = str..items[i]..","
	end 
	if items[0] then
		str = str..Globals.NoSubCatStr..","
	end
	if str ~= "" then
		f.SubCat = str:sub(1,-2)
	end
	-- Tags
	f.Tags = TagBoolCtrl:BooleanExpression()
	if TagCheckBox:GetValue() then
		f.Tags = "("..f.Tags..") or "..Globals.NoTagStr
	end
	-- Schedule
	f.Schedules = SchBoolCtrl:BooleanExpression()
	-- Custom Script
	if ScriptBox:GetValue() ~= "" then
		local script = ScriptBox:GetValue()
		local result, msg = loadstring(script)
		if not result then
			wx.wxMessageBox("Unable to compile the script. Error: "..msg..".\n Please correct and try again.",
                            "Script Compile Error",wx.wxOK + wx.wxCENTRE, frame)
            return nil
		end
		f.Script = script
	end
	return f
end

local function loadFilter(event)
	setfenv(1,package.loaded[modname])
	local ValidFilter = function(file)
		local safeenv = {}
		setmetatable(safeenv, {__index = Globals.safeenv})
		local f,message = loadfile(file)
		if not f then
			return nil,message
		end
		setfenv(f,safeenv)
		f()
		if safeenv.filter and type(safeenv.filter) == "table" then
			if safeenv.filter.Script then
				f, message = loadstring(safeenv.filter.Script)
				if not f then
					return nil,"Cannot compile custom script in filter. Error: "..message
				end
			end
			if safeenv.filter.Map then
				-- This is a combination filter
				for i = 1,safeenv.filter.Map.count do
					if safeenv.filter.Map["F"..i].Filter.Script then
						f, message = loadstring(safeenv.filter.Map["F"..i].Filter.Script)
						if not f then
							return nil,"Cannot compile custom script in filter: "..safeenv.filter.Map["F"..i].Name.."\nError: "..message
						end
					end
				end
			end
			return safeenv.filter
		else
			return nil,"Cannot find a valid filter in the file."
		end
	end
    local fileDialog = wx.wxFileDialog(frame, "Open file",
                                       "",
                                       "",
                                       "Karm Filter files (*.kff)|*.kff|Karm Filter Combination files (*.kfc)|*.kfc|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local result,message = ValidFilter(fileDialog:GetPath())
        if not result then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.\n "..message,
                            "File Load Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        else
        	setfilter(result)
        end
    end
    fileDialog:Destroy()
end

local function saveFilter(event)
	setfenv(1,package.loaded[modname])
    local fileDialog = wx.wxFileDialog(frame, "Save File",
                                       "",
                                       "",
                                       "Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxFD_SAVE)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local file,err = io.open(fileDialog:GetPath(),"w+")
    	if not file then
            wx.wxMessageBox("Unable to save as file '"..fileDialog:GetPath().."'.\n "..err,
                            "File Save Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        else
        	local fil = synthesizeFilter()
        	if fil then
        		file:write("filter="..tableToString(fil))
        	end
        	file:close()
        end
    end
    fileDialog:Destroy()

end

local function synthesizeFComb()
	local fil = FCombBoolCtrl:BooleanExpression()
	if not fil then 
		return
	end
	local newFComb = {count = 0}
	for i = 1,FCombMap.count do
		if string.find(fil,"'"..FCombMap["F"..i].Name.."'",1,true) then
			-- This filter is present
			newFComb.count = newFComb.count + 1
			newFComb["F"..newFComb.count] = FCombMap["F"..i]
		end
	end
	-- Update FCombMap
	FCombMap = newFComb
	return {Map = FCombMap,Bool = fil}
end

local function saveFilterComb(event)
	setfenv(1,package.loaded[modname])
	if not FCombBoolCtrl:BooleanExpression()then
		return
	end
    local fileDialog = wx.wxFileDialog(frame, "Save File",
                                       "",
                                       "",
                                       "Karm Filter Combination files (*.kfc)|*.kfc|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxFD_SAVE)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local file,err = io.open(fileDialog:GetPath(),"w+")
    	if not file then
            wx.wxMessageBox("Unable to save as file '"..fileDialog:GetPath().."'.\n "..err,
                            "File Save Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        else
			local fil = synthesizeFComb()
			if fil then
        		file:write("filter="..tableToString(fil))
			end
        	file:close()
        end
    end
    fileDialog:Destroy()
end

-- Customized multiselect control
do

	local UpdateFilter = function(o)
		local SelList = o:getSelectedItems()
		local filterIndex = o.filterIndex
		local str = ""
		for i = 1,#SelList do
			str = str..SelList[i]..","
		end
		-- Finally Check if none also selected
		if SelList[0] then
			str = str..noStr[filterIndex]..","
		end
		if str ~= "" then
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it
		else
			filter[filterIndex]=nil
		end
	end

	MultiSelectCtrl = function(parent, filterIndex, noneSelection, LItems, RItems)
		if not filterIndex then
			error("Need a filterIndex for the MultiSelect Control",2)
		end
		local o = CW.MultiSelectCtrl(parent,LItems,RItems,noneSelection)
		o.filterIndex = filterIndex
		o.UpdateFilter = UpdateFilter
		return o
	end

end

-- Customized Date Range control
do

	local UpdateFilter = function(o)
		local SelList = o:getSelectedItems()
		local filterIndex = o.filterIndex
		local str = ""
		for i = 1,#SelList do
			str = str..SelList[i]..","
		end
		-- Finally Check if none also selected
		if SelList[0] then
			str = str..noStr[filterIndex]..","
		end
		if str ~= "" then
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it
		else
			filter[filterIndex]=nil
		end
	end

	DateRangeCtrl = function(parent, filterIndex, noneSelection, heading)
		if not filterIndex then
			error("Need a filterIndex for the Date Range Control",2)
		end
		local o = CW.DateRangeCtrl(parent, noneSelection, heading)
		o.filterIndex = filterIndex
		o.UpdateFilter = UpdateFilter
		return o
	end

end

-- Customized Boolean Tree Control
do

	local UpdateFilter = function(o)
		local filterText = o:BooleanExpression()
		if filterText == "" then
			filter[o.filterIndex]=nil
		else
			filter[o.filterIndex]=filterText
		end
	end
	
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc,filterIndex)
		if not filterIndex then
			error("Need a filterIndex for the Boolean Tree Control",2)
		end
		local o = CW.BooleanTreeCtrl(parent,sizer,getInfoFunc)
		o.filterIndex = filterIndex
		o.UpdateFilter = UpdateFilter
		return o	
	end

end

-- Customized Check List Control
do
	local getSelectionFunc = function(obj)
		-- Return the selected item in List
		local o = obj		-- Declare an upvalue
		return function()
			local items = o:getSelectedItems()
			if not items[1] then
				return nil
			else
				return items[1].itemText..","..items[1].checked
			end
		end
	end
	
	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText)
		local o = CW.CheckListCtrl(parent,noneSelection,checkedText,uncheckedText,true)
		o.getSelectionFunc = getSelectionFunc
		return o
	end

end

function filterFormActivate(parent, callBack)
	MainFilter = GlobalFilter()
	SporeData = SData()
	-- Accumulate Filter Data across all spores
	-- Loop through all the spores
	for k,v in pairs(SporeData) do
		if k~=0 then
			collectFilterDataHier(filterData,v)
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(SporeData) do ends
	
	frame = wx.wxFrame(parent, wx.wxID_ANY, "Filter Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	-- Create tool bar
	ID_LOAD = NewID()
	ID_SAVE = NewID()
	ID_SAVE_COMB = NewID()
	local toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	local toolBmpSize = toolBar:GetToolBitmapSize()

	toolBar:AddTool(ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Filter Criteria")
	toolBar:AddTool(ID_SAVE, "Save", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save Filter Criteria")
	toolBar:AddTool(ID_SAVE_COMB, "Save Filter Combination", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize), "Save filter combination to disk")
	toolBar:Realize()
	
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)

		-- Task, Categories and Sub-Categories Page
		TandC = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local TandCSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				local TaskSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
				SelTaskButton = wx.wxButton(TandC, wx.wxID_ANY, "Select Task", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				TaskSizer:Add(SelTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				FilterTask = wx.wxStaticText(TandC, wx.wxID_ANY, "No Task Selected", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				TaskSizer:Add(FilterTask, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				ClearTaskButton = wx.wxButton(TandC, wx.wxID_ANY, "Clear Task", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				TaskSizer:Add(ClearTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Checkbox for ShowHierarchy
				ShowHierarchyBox = wx.wxCheckBox(TandC, wx.wxID_ANY, "Show Parent Hierarchy", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ShowHierarchyBox:SetValue(true)
				TaskSizer:Add(ShowHierarchyBox,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				TandCSizer:Add(TaskSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				CategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				TandCSizer:Add(CategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Category List boxes and buttons
				CatCtrl = MultiSelectCtrl(TandC,"Cat",true,filterData.Cat)
				TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Sub-Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Sub Category Listboxes and Buttons
				SubCatCtrl = MultiSelectCtrl(TandC,"SubCat",true,filterData.SubCat)
				TandCSizer:Add(SubCatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			TandC:SetSizer(TandCSizer)
			TandCSizer:SetSizeHints(TandC)
		MainBook:AddPage(TandC, "Task and Category")
		
		-- Priorities Status and Tags page
		PSandTag = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local PSandTagSizer = wx.wxBoxSizer(wx.wxVERTICAL) 
				PriorityLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Priorities", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(PriorityLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Priority List boxes and buttons
				PriCtrl = MultiSelectCtrl(PSandTag,"Priority",true,filterData.Priority)
				PSandTagSizer:Add(PriCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				StatusLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Status", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(StatusLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Status List boxes and buttons
				StatCtrl = MultiSelectCtrl(PSandTag,"Status",false,Globals.StatusList)
				PSandTagSizer:Add(StatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				TagsLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Tags", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(TagsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Tag List box, buttons and tree
				local TagSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					local TagListSizer = wx.wxBoxSizer(wx.wxVERTICAL)
						TagList = wx.wxListCtrl(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),
							bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER,wx.wxLC_SINGLE_SEL))
						-- Populate the tag list here
						--local col = wx.wxListItem()
						--col:SetId(0)
						TagList:InsertColumn(0,"Tags")
						if filterData.Tags then
							for i=1,#filterData.Tags do
								CW.InsertItem(TagList,filterData.Tags[i])
							end
						end
						TagListSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						TagCheckBox = wx.wxCheckBox(PSandTag, wx.wxID_ANY, "None Also passes", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagListSizer:Add(TagCheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						
					TagSizer:Add(TagListSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					TagBoolCtrl = BooleanTreeCtrl(PSandTag,TagSizer,
						function()
							-- Return the selected item in Tag List
							local item = TagList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
							if item == -1 then
								return nil
							else 
								return TagList:GetItemText(item)		
							end
						end, 
					"Tags")
				PSandTagSizer:Add(TagSizer, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			PSandTag:SetSizer(PSandTagSizer)
			PSandTagSizer:SetSizeHints(PSandTag)
		MainBook:AddPage(PSandTag, "Priorities,Status and Tags")
		
		-- Date Started, Date Finished and Due Date Page
		DatesPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local DatesPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			
			-- Date Started Control
			dateStarted = DateRangeCtrl(DatesPanel,"Start",false,"Date Started")
			DatesPanelSizer:Add(dateStarted.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Date Finished Control
			dateFinished = DateRangeCtrl(DatesPanel,"Fin",true,"Date Finished")
			DatesPanelSizer:Add(dateFinished.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Due Date Control
			dateDue = DateRangeCtrl(DatesPanel,"Due",true,"Due Date")
			DatesPanelSizer:Add(dateDue.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			

			DatesPanel:SetSizer(DatesPanelSizer)
			DatesPanelSizer:SetSizeHints(DatesPanel)
		MainBook:AddPage(DatesPanel, "Dates:Due,Started,Finished")

		-- Who and Access IDs page
		AccessPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local AccessPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			
			local whoSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local accSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			
			local whoLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, "Select Responsible People (Check means Inactive)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			AccessPanelSizer:Add(whoLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			whoCtrl = CheckListCtrl(AccessPanel,false,"I","A")
			-- Populate the IDs
			if filterData.Who then
				for i = 1,#filterData.Who do
					whoCtrl:InsertItem(filterData.Who[i], false)
				end
			end
			whoSizer:Add(whoCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			WhoBoolCtrl = BooleanTreeCtrl(AccessPanel,whoSizer,whoCtrl:getSelectionFunc(), "Who")
			AccessPanelSizer:Add(whoSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			
			local accLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, "Select People for access (Check means Read/Write Access)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			AccessPanelSizer:Add(accLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			accCtrl = CheckListCtrl(AccessPanel,false,"W","R")
			-- Populate the IDs
			if filterData.Access then
				for i = 1,#filterData.Access do
					accCtrl.InsertItem(accCtrl,filterData.Access[i], false)
				end
			end
			accSizer:Add(accCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			accBoolCtrl = BooleanTreeCtrl(AccessPanel,accSizer,accCtrl:getSelectionFunc(), "Access")
			AccessPanelSizer:Add(accSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			AccessPanel:SetSizer(AccessPanelSizer)
			AccessPanelSizer:SetSizeHints(AccessPanel)
		MainBook:AddPage(AccessPanel, "Access")
		
		-- Schedules Page
		SchPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local SchPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			local duSizer = wx.wxBoxSizer(wx.wxVERTICAL)	-- Sizer for Date unit elements
			
			local typeMatchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Type of Matching", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(typeMatchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			TypeMatch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{"Full","Overlap"})
			duSizer:Add(TypeMatch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			TypeMatch:SetSelection(1)
			
			local typeSchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Type of Schedule", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(typeSchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			TypeSch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{"Estimate","Committed","Revisions","Actual", "Latest"})
			duSizer:Add(TypeSch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			TypeSch:SetSelection(2)
						
			local SchRevLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Revision (Latest, Planning or number)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(SchRevLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			SchRev = wx.wxComboBox(SchPanel, wx.wxID_ANY,"Latest",wx.wxDefaultPosition, wx.wxDefaultSize,{"Latest"})
			duSizer:Add(SchRev,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			-- Event connect to enable disable SchRev
			TypeSch:Connect(wx.wxEVT_COMMAND_CHOICE_SELECTED,function(event) 
				setfenv(1,package.loaded[modname])
				if TypeSch:GetString(TypeSch:GetSelection()) == "Estimate" or TypeSch:GetString(TypeSch:GetSelection()) == "Revisions" then
					SchRev:Enable(true)
				else
					SchRev:Enable(false)
				end
			end 
			)

			local DateRangeLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Date Ranges", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(DateRangeLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Date Ranges Control
			schDateRanges = DateRangeCtrl(SchPanel,"ScheduleRange",true,"Date Ranges") 
			duSizer:Add(schDateRanges.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			SchPanelSizer:Add(duSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			-- Now add the Boolean Control
			local getSchUnit = function()
				-- Get the full schedule boolean unit
				local unit = TypeMatch:GetString(TypeMatch:GetSelection())..","..TypeSch:GetString(TypeSch:GetSelection())
				if SchRev:IsEnabled() then
					if string.upper(SchRev:GetValue()) == "LATEST" or string.upper(SchRev:GetValue()) == "L" then
						unit = unit.."(L)"
					elseif string.upper(SchRev:GetValue()) == "PLANNING" or string.upper(SchRev:GetValue()) == "P" then
						unit = unit.."(P)"
					else
						unit = unit.."("..tostring(SchRev:GetValue())..")"
					end
				end
				schDateRanges:UpdateFilter()
				if not filter.ScheduleRange then
					unit = nil
				else
					unit = unit..","..filter.ScheduleRange
				end
				return unit
			end 

			SchBoolCtrl = BooleanTreeCtrl(SchPanel,SchPanelSizer,getSchUnit, "Schedules")

			

			SchPanel:SetSizer(SchPanelSizer)
			SchPanelSizer:SetSizeHints(SchPanel)
		MainBook:AddPage(SchPanel, "Schedules")
		
		-- Custom Script Entry Page
		ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL) 
			
			-- Text Instruction
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, "Enter a custom script to filte out tasks additional to the Filter set in the form. The task would be present in the environment in the table called 'task'. Apart from that the environment is what is setup in Globals.safeenv. The 'result' variable should be updated to true if pass or false if does not pass.", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			InsLabel:Wrap(frame:GetSize():GetWidth()-25)
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			

			ScriptPanel:SetSizer(ScriptPanelSizer)
			ScriptPanelSizer:SetSizeHints(ScriptPanel)
		MainBook:AddPage(ScriptPanel, "Custom Script")
		
		-- Filter Combination Panel
		FCombPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local FCombPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			local dnSizer = wx.wxBoxSizer(wx.wxVERTICAL)	-- Sizer for Descriptive names
			local dnSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
			
			local dnLabel = wx.wxStaticText(FCombPanel, wx.wxID_ANY, "Descriptive name for the filter unit", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			dnSizer:Add(dnLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			dnBox = wx.wxTextCtrl(FCombPanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
			dnSizer:Add(dnBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
	
			dnSizer1:Add(dnSizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL, wx.wxALIGN_CENTER_VERTICAL), 1)
			FCombPanelSizer:Add(dnSizer1,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local applyButton
			-- Now add the Boolean Control
			local getFilterUnit = function()
				-- Get the full schedule boolean unit
				local f = synthesizeFilter()
				if not f then
					return
				end
				local dn = dnBox:GetValue()
				if dn == "" then
					wx.wxMessageBox("Please enter a name for the current filter first.")
					return
				elseif string.find(dn,"'") then
					wx.wxMessageBox("Name cannot contain single quotes ('). Please use double quotes instead.")
					return
				end
				FCombMap.count = FCombMap.count + 1
				FCombMap["F"..FCombMap.count] = {Name = "F"..FCombMap.count..":"..dn, Filter = f}
				applyButton:SetLabel("Apply Combination")
				applyButton:Enable(true)
				return FCombMap["F"..FCombMap.count].Name
			end 

			FCombBoolCtrl = BooleanTreeCtrl(FCombPanel,FCombPanelSizer,getFilterUnit, "FComb")
			FCombBoolCtrl:associateEventFunc({
				clickEventFunc = function(selText)
					for i = #selText,1,-1 do
						-- Find this in FCombMap
						local found = nil
						for j = 1,FCombMap.count do
							if selText[i] == FCombMap["F"..j].Name then
								found = FCombMap["F"..j].Filter
								break
							end
						end
						if found then
							-- Set this in the filter GUI
							dnBox:SetValue(string.sub(selText[i],string.find(selText[i],":")+1,-1))
							setfilter(found)
							break
						end
					end
				end
			})
			
			FCombPanel:SetSizer(FCombPanelSizer)
			FCombPanelSizer:SetSizeHints(FCombPanel)
		MainBook:AddPage(FCombPanel, "Logically Combine Filters")

	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	local ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
	ApplyCombButton = wx.wxButton(frame, wx.wxID_ANY, "Apply Combination", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	applyButton = ApplyCombButton
	ButtonSizer:Add(ApplyCombButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	ApplyCombButton:Disable()
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	ApplyButton = wx.wxButton(frame, wx.wxID_ANY, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(ApplyButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	ResetButton = wx.wxButton(frame, wx.wxID_ANY, "Reset Filter", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(ResetButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	frame:SetSizer(MainSizer)
	--MainSizer:SetSizeHints(frame)
	
	-- MainBook Events
	MainBook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CHANGED,
		function(event)
			setfenv(1,package.loaded[modname])	
			if MainBook:GetPageText(event:GetSelection()) == "Logically Combine Filters" then
				local f = synthesizeFilter()
				if not f then
					return
				end
				dnBox:SetValue(tableToString(f))
				dnBox:SetSelection(-1,-1)
			end
		end
	)
	
	-- Connect event handlers to the buttons
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])		
			frame:Close()
			callBack(nil)
		end
	)
	
	ResetButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])
			initializeFilterForm(filterData)		
		end
	)

	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
		function (event)
			setfenv(1,package.loaded[modname])		
			event:Skip()
			callBack(nil)
		end
	)

	ApplyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local f = synthesizeFilter()
			if not f then
				return
			end
			--print(tableToString(f))
			frame:Close()
			callBack(f)
		end		
	)

	ApplyCombButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local f = synthesizeFComb()
			if not f then
				ApplyCombButton:SetLabel("No Combination")
				ApplyCombButton:Disable()
				return
			end
			frame:Close()
			callBack(f)
		end		
	)
--	Connect(wxID_ANY,wxEVT_CLOSE_WINDOW,(wxObjectEventFunction)&CriteriaFrame::OnClose);

	-- Task Selection/Clear button press event
	SelTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, SelTaskPress)
	ClearTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])
			filter.TasksSet = nil
			FilterTask:SetLabel("No Task Selected")
		end
	)
	
	frame:Connect(wx.wxEVT_SIZE,
		function(event)
			setfenv(1,package.loaded[modname])
			InsLabel:SetLabel("Enter a custom script to filte out tasks additional to the Filter set in the form. The task would be present in the environment in the table called 'task'. Apart from that the environment is what is setup in Globals.safeenv. The 'result' variable should be updated to true if pass or false if does not pass.")
			InsLabel:Wrap(frame:GetSize():GetWidth()-25)
			event:Skip()
		end
	)

	-- Toolbar button events
	frame:Connect(ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,loadFilter)
	frame:Connect(ID_SAVE,wx.wxEVT_COMMAND_MENU_SELECTED,saveFilter)
	frame:Connect(ID_SAVE_COMB,wx.wxEVT_COMMAND_MENU_SELECTED,saveFilterComb)
	
    frame:Layout() -- help sizing the windows before being shown
    frame:Show(true)
    setfilter(MainFilter)
end		-- function filterFormActivate(parent) ends
