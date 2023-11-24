-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application main file forms the frontend and handles the GUI
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
-- For windows distribution
package.cpath = ";?.dll;./?.dll;"

-- For linux distribution
--package.cpath = ";./?.so;/usr/lib/?.so;/usr/local/lib/?.so;"

require("wx")

-- DO ALL CONFIGURATION
Karm = {}
-- Table to store the core functions when they are being overwritten
Karm.Core = {}
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.key and not Karm.Core.key then
			Karm.Core.key = Karm.key
		end
		rawset(Karm,key,val)
	end
	setmetatable(Karm,KarmMeta)
end]]
-- Table to store all the Spores data 
Karm.SporeData = {}


-- Creating GUI the main table containing all the GUI objects and data
Karm.GUI = {
	-- Node Colors
	nodeForeColor = {Red=0,Green=0,Blue=0},
	nodeBackColor = {Red=255,Green=255,Blue=255},
	-- Gantt Colors
	noScheduleColor = {Red=210,Green=210,Blue=210},
	ScheduleColor = {Red=0,Green=180,Blue=215},
	emptyDayColor = {Red=255,Green=255,Blue=255},
	sunDayOffset = {Red = 30, Green=30, Blue = 30},
	bubbleOffset = {Red = 20, Green=20, Blue = 20},
	defaultColor = {Red=0,Green=0,Blue=0},
	highLightColor = {Red=120,Green=120,Blue=120},
  dueColor = {Red=200,Green=50,Blue=50},
	
	
	-- Task status colors
	-- Main Menu
	MainMenu = {
					-- 1st Menu
					{	
						Text = "&File", Menu = {
												{Text = "Change &ID\tCtrl-I", HelpText = "Change the User ID", Code = [[
	local user = wx.wxGetTextFromUser("Enter the user ID (Blank to cancel)", "User ID", "")
	if user ~= "" then
		Karm.Globals.User = user
		Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
	end											
												]]},
												{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "Karm.GUI.frame:Close(true)"}
										}
					},
					-- 2nd Menu
					{	
						Text = "&Tools", Menu = {
												{Text = "&Planning Mode\tCtrl-P", HelpText = "Toggle Planning mode", Code = [[
		local menuItem = Karm.GUI.menuBar:FindItem(myID)
		if menuItem:IsChecked() then 
			-- Enable Planning Mode 
			Karm.GUI.taskTree:enablePlanningMode() 
		else 
			-- Disable Planning Mode 
			Karm.GUI.taskTree:disablePlanningMode() 
		end											
												]], ItemKind = wx.wxITEM_CHECK},
												{Text = "Planning Mode ON for &Tasks\tCtrl-T", HelpText = "Turn on Planning Mode for the selected tasks", Code = [[
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
			wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		else
			-- Turn on Planning Mode
			local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
			menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):Check(true) 
			local list = {}
			for i = 1,#taskList do
				-- Select nodes that only have actual tasks and which are not spores 
				if taskList[i].Task and not Karm.TaskObject.IsSpore(taskList[i].Task) then
					list[#list + 1] = taskList[i].Task
					-- Mark the unsaved spores list so saving message is displayed
					Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
				end
			end
			Karm.GUI.taskTree:enablePlanningMode(list)
		end
												
												]]},
												{Text = "&Finalize all Planning Schedules\tCtrl-F", HelpText = "Finalize all Planning schedules in the tasks in the UI", Code = [[
	if Karm.GUI.taskTree.taskList then
		while #Karm.GUI.taskTree.taskList > 0 do
			Karm.finalizePlanning(Karm.GUI.taskTree.taskList[1].Task, Karm.GUI.taskTree.Planning.Type)
		end
	end
												]]},
												{Text = "&Quick Enter Task Under\tCtrl-Q", HelpText = "Quick Entry of task under this task", Code = [[
		-- Get the task Title
		local title = wx.wxGetTextFromUser("Please enter the task Title (Blank to Cancel)", "New Task under", "")
		if title ~= "" then
			local task = {}
			Karm.TaskObject.MakeTaskObject(task)
			task.Title = title
			task.Who = {[0]="Who", count = 1, [1] = {ID = Karm.Globals.User, Status = "Active"}}
			task.Private = false
			task.Modified = true
			task.Status = "Not Started"		
			Karm.NewTask(Karm.Globals.CHILD,task)
		end
												]]},								
												{Text = "&Schedule Bubble\tCtrl-B", HelpText = "Bubble up the Schedules", Code = [[local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
	if menuItems:Item(4):GetData():DynamicCast('wxMenuItem'):IsChecked() then 
		-- Enable Bubbling Mode 
		Karm.GUI.taskTree.Bubble = true
		Karm.GUI.fillTaskTree()
	else 
		-- Disable Bubbling Mode 
		Karm.GUI.taskTree.Bubble = false
		Karm.GUI.fillTaskTree()
	end]] , ItemKind = wx.wxITEM_CHECK},										
												{Text = "&Show Work Done\tCtrl-W", HelpText = "Show Actual Work Done", Code = [[
		Karm.GUI.taskTree.ShowActual = true
		Karm.GUI.fillTaskTree()
												]]},										
												{Text = "&Show Normal Schedule\tCtrl-N", HelpText = "Show Normal Schedule", Code = [[
		Karm.GUI.taskTree.ShowActual = nil
		Karm.GUI.fillTaskTree()
												]]},									
										}	-- Menu Ends
					},
					-- 3rd Menu
					{	
						Text = "&Filters", Menu = {
												{Text = "&Show Not Done Tasks under also\tCtrl-1", HelpText = "All not done tasks under this task will also show", Code = [[
	-- Get selected task first
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end			
	if #taskList > 1 then
		wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end	
	local filter = Karm.Filter
	if filter.Map then
		-- This is already a filter combination
		filter.Map.count = filter.Map.count + 1
		filter.Map["F"..filter.Map.count] = {Name = "F"..filter.Map.count..":"..taskList[1].Task.Title.." and not done Children", Filter = {Status="Behind,Not Started,On Track",Tasks={[1]={TaskID=taskList[1].Task.TaskID,Title=taskList[1].Task.Title,Children="true"}}}}
		filter.Bool = filter.Bool.." or '"..filter.Map["F"..filter.Map.count].Name.."'"
	else
		-- Make this a filter combination
		Karm.Filter = {
					Map = {count = 2,
					F1 = {Name = "F1:Previous Filter", Filter = Karm.Filter},
					F2 = {Name = "F2:"..taskList[1].Task.Title.." and not done Children", Filter = {Status="Behind,Not Started,On Track",Tasks={[1]={TaskID=taskList[1].Task.TaskID,Title=taskList[1].Task.Title,Children="true"}}}} 
					},
					Bool = "'F1:Previous Filter' or 'F2:"..taskList[1].Task.Title.." and not done Children'"
		}
	end
	Karm.GUI.fillTaskTree()
												]]},
												{Text = "&Scheduled but not done\tCtrl-4", HelpText = "Tasks scheduled before today and not marked done", Code = [[
	local year = os.date("%Y")
	local month = os.date("%m")
	local day = os.date("%d")
	local finDay = os.time{year=year,month=month,day=day-1}
	Karm.Filter={Status="Behind,Not Started,On Track",Schedules="'Full,Latest,01/01/2010-"..os.date("%m",finDay).."/"..os.date("%d",finDay).."/"..os.date("%Y",finDay).."'"}
	Karm.GUI.fillTaskTree()
												]]},
												{Text = "&Coming Week not Done\tCtrl-5", HelpText = "Tasks scheduled in the coming week", Code = [[
	local year = os.date("%Y")
	local month = os.date("%m")
	local day = os.date("%d")
	local today = os.time{year=year,month=month,day=day}
	local startDay = os.date("%m",today).."/"..os.date("%d",today).."/"..os.date("%Y",today)
	local aweeklater = os.time{year=year,month=month,day=day+6}
	local finDay = os.date("%m",aweeklater).."/"..os.date("%d",aweeklater).."/"..os.date("%Y",aweeklater)
	Karm.Filter={Status="Behind,Not Started,On Track",Schedules="('Overlap,Revisions(L),"..startDay.."-"..finDay.."' or 'Overlap,Committed,"..startDay.."-"..finDay.."' or 'Overlap,Estimate(L),"..startDay.."-"..finDay.."')"}
	Karm.GUI.fillTaskTree()
												]]},
												{Text = "&Today Not Done\tCtrl-6", HelpText = "Tasks scheduled for today", Code = [[
	local year = os.date("%Y")
	local month = os.date("%m")
	local day = os.date("%d")
	local today = os.time{year=year,month=month,day=day}
	local startDay = os.date("%m",today).."/"..os.date("%d",today).."/"..os.date("%Y",today)
	local finDay = os.date("%m",today).."/"..os.date("%d",today).."/"..os.date("%Y",today)
	Karm.Filter={Status="Behind,Not Started,Obsolete,On Track",Schedules="('Overlap,Revisions(L),"..startDay.."-"..finDay.."' or 'Overlap,Committed,"..startDay.."-"..finDay.."' or 'Overlap,Estimate(L),"..startDay.."-"..finDay.."')"}
	Karm.GUI.fillTaskTree()
												]]},
												{Text = "All &Not Done, Non Obsolete\tCtrl-7", HelpText = "Tasks scheduled for today", Code = [[
	Karm.Filter = {Status="Behind,Not Started,On Track,Pending"}
	Karm.GUI.fillTaskTree()
												]]},
												{Text = "&All Tasks\tCtrl-8", HelpText = "Show all loaded Tasks", Code = [[
	Karm.Filter = {}
	Karm.GUI.fillTaskTree()
												]]}
										}
					},
					-- 4th Menu
					{	
						Text = "&Help", Menu = {
													{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = [[
			wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n    Version: '..Karm.Globals.KARM_VERSION.."\nFor Help:\n    wiki.karm.amved.com\n    group.karm.amved.com\n    karm@amved.com", 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,Karm.GUI.frame)]]
													}
										}	-- Menu ends
					}	-- 4th Menu ends
	},		-- Main Menu ends here
	
	-- Toolbar
	Tools = {
		{	-- Load XML file
			Text = "Load XML",
			Code = "Karm.loadXML()",
			HelpText = "Load XML Spore from Disk",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/load_xml.png"
			}
		},
		{	-- Load Spore file
			Text = "Load",
			HelpText = "Load Spore from Disk",
			Code = "Karm.openKarmSpore()",
			Image = { Data = wx.wxART_GO_DIR_UP	}
		},
		{	-- UnLoad Spore file
			Text = "Unload",
			HelpText = "Unload current spore",
			Code = "Karm.unloadSpore()",
			Image = { Data = wx.wxART_FOLDER	}
		},
		{	-- Save all spores to Disk
			Text = "Save All",
			HelpText = "Save All Spores to Disk",
			Code = "Karm.SaveAllSpores()",
			Image = { Data = wx.wxART_FILE_SAVE	}
		},
		{	-- Save current spore to Disk
			Text = "Save Current",
			HelpText = "Save current spore to disk",
			Code = "Karm.SaveCurrSpore()",
			Image = { Data = wx.wxART_FILE_SAVE_AS	}
		},
		"SEPARATOR",		
		{	-- Set Filter Criteria
			Text = "Set Filter",
			Code = "Karm.SetFilter()",
			HelpText = "Set Filter Criteria",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/filter.png"
					}
		},
		{	-- Create New Task Under
			Text = "Create Sub-task",
			Code = "Karm.NewTask(Karm.Globals.CHILD)",
			HelpText = "Create Sub-task",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/new_under.png"
					}
		},
		{	-- Create New Task Below
			Text = "Create Next Task",
			Code = "Karm.NewTask(Karm.Globals.NEXT_SIBLING)",
			HelpText = "Creat Next Task",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/new_below.png"
					}
		},
		{	-- Create New Task Above
			Text = "Create Previous Task",
			Code = "Karm.NewTask(Karm.Globals.PREV_SIBLING)",
			HelpText = "Creat Previous task",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/new_above.png"
					}
		},
		{	-- Edit Task
			Text = "Edit Task",
			Code = "Karm.EditTask()",
			HelpText = "Edit Task",
			Image = { Data = wx.wxART_REPORT_VIEW	}
		},
		{	-- Delete Task
			Text = "Delete Task",
			Code = "Karm.DeleteTask()",
			HelpText = "Delete Task",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/delete.png"
					}
		},
		{	-- Move Task Under
			Text = "Move Under",
			HelpText = "Move Task Under...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.CHILD)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/move_under.png"
					}
		},
		{	-- Move Task Above
			Text = "Move Above",
			HelpText = "Move Task Above...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.PREV_SIBLING)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/move_above.png"
					}
		},
		{	-- Move Task Below
			Text = "Move Below",
			HelpText = "Move Task Below...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.NEXT_SIBLING)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/move_below.png"
					}
		},
		"SEPARATOR",
		{	-- Copy Task Under
			Text = "Copy Under",
			HelpText = "Copy Task Under...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.CHILD, true)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/copy_under.png"
					}
		},
		{	-- Copy Task Above
			Text = "Copy Above",
			HelpText = "Copy Task Above...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.PREV_SIBLING, true)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/copy_above.png"
					}
		},
		{	-- Copy Task Below
			Text = "Copy Below",
			HelpText = "Copy Task Below...",
			Code = "Karm.InitiateMoveCopy(Karm.Globals.NEXT_SIBLING, true)",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/copy_below.png"
					}
		},
		"SEPARATOR",
		{	-- Run Macro
			Text = "Run Lua Macro",
			HelpText = "Run Lua Macro...",
			Code = "Karm.Macro()",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/lua_macro.png"
					}
		}
	}	-- Tools ends here
}		-- Karm.GUI ends here

Karm.GUI.initFrameW, Karm.GUI.initFrameH = wx.wxDisplaySize()
Karm.GUI.initFrameW = 0.75*Karm.GUI.initFrameW
Karm.GUI.initFrameH = 0.75*Karm.GUI.initFrameH
Karm.GUI.initFrameW = Karm.GUI.initFrameW - Karm.GUI.initFrameW%1
Karm.GUI.initFrameH = Karm.GUI.initFrameH - Karm.GUI.initFrameH%1

Karm.Core.GUI = {}
setmetatable(Karm.GUI,{__index = _G})
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.GUI.key and not Karm.Core.GUI.key then
			Karm.Core.GUI.key = Karm.GUI.key
		end
		rawset(Karm.GUI,key,val)
	end
	KarmMeta.__index = _G
	setmetatable(Karm.GUI,KarmMeta)
end
]]

-- Global Declarations
Karm.Globals = {
	ROOTKEY = "T0",
	KARM_VERSION = "1.14.6.18",
	PriorityList = {'1','2','3','4','5','6','7','8','9'},
	EstimateUnit = "H", -- This can be H or D indicating Hours or Days
	StatusList = {'Not Started','On Track','Behind','Done','Obsolete', 'Pending'},
	StatusNodeColor = {
				{	ForeColor = {Red=100,Green=100,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=230,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=230},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=200,Green=200,Blue=200},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=230,Green=50,Blue=200},
					BackColor = {Red=255,Green=255,Blue=255}
				}
	},
	NoDateStr = "__NO_DATE__",
	NoTagStr = "__NO_TAG__",
	NoAccessIDStr = "__NO_ACCESS__",
	NoCatStr = "__NO_CAT__",
	NoSubCatStr = "__NO_SUBCAT__",
	NoPriStr = "__NO_PRI__",
	__DEBUG = true,		-- For debug mode
	--PlanningMode = false,	-- Flag to indicate Schedule Planning mode is on. THIS IS NOT USED IT IS USED IN THE RESPECTIVE GANTT GUI OBJECT
	unsavedSpores = {},	-- To store list of unsaved Spores
	safeenv = {},
	UserIDPattern = "%'([%w%.%_%,]+)%'",
	
	-- CONSTANTS
	NEXT_SIBLING = 0,
	PREV_SIBLING = 1,
	CHILD = 2,
	safeenv = {}	-- safe environment table used to run scripts
}

setmetatable(Karm.Globals.safeenv,{__index = _G})

-- Generate a unique new wxWindowID
do
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
	function Karm.NewID()
	    ID_IDCOUNTER = ID_IDCOUNTER + 1
	    return ID_IDCOUNTER
	end
end

-- FINISH CONFIGURATION

-- INCLUDE ALL CODE

-- Include the XML handling module
require("LuaXml")

-- Karm files
require("Filter")
require("DataHandler")
Karm.GUI.FilterForm = require("FilterForm")		-- Containing all Filter Form GUI code
Karm.GUI.TaskForm = require("TaskForm")		-- Containing all Task Form GUI code
Karm.GUI.TreeGantt = require("ganttwidget")

-- FINISH CODE INCLUSION

-- Function to generate and return the node color of a TaskTree node
function Karm.GUI.getNodeColor(node)
	-- Get the node colors according to the status
	if not node.Task then
		return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
	else
		if Karm.Globals.StatusNodeColor then
			for i = 1,#Karm.Globals.StatusList do
				if node.Task.Status == Karm.Globals.StatusList[i] and Karm.Globals.StatusNodeColor[i] then
					local foreColor = Karm.GUI.nodeForeColor
					local backColor = Karm.GUI.nodeBackColor
					if Karm.Globals.StatusNodeColor[i].ForeColor and Karm.Globals.StatusNodeColor[i].ForeColor.Red and 
					  Karm.Globals.StatusNodeColor[i].ForeColor.Blue and Karm.Globals.StatusNodeColor[i].ForeColor.Green then
						foreColor = Karm.Globals.StatusNodeColor[i].ForeColor
					end
					if Karm.Globals.StatusNodeColor[i].BackColor and Karm.Globals.StatusNodeColor[i].BackColor.Red and 
					  Karm.Globals.StatusNodeColor[i].BackColor.Blue and Karm.Globals.StatusNodeColor[i].BackColor.Green then
						backColor = Karm.Globals.StatusNodeColor[i].BackColor
					end
					return foreColor, backColor
				end
			end
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		else
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		end	
	end
end

function Karm.GUI.addTask(task)
	local parent = task.Parent
	while parent do
		if Karm.GUI.taskTree.Nodes[parent.TaskID] then
			-- Put the task under this node
			local currNode = Karm.GUI.taskTree:AddNode{Relative=parent.TaskID, Relation=Karm.Globals.CHILD, Key=task.TaskID, Text=task.Title, Task=task}
			currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
			return true
		end
	end
	-- No hierarchy was found so this has to be the root node in a spore
	if not Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..task.SporeFile] then
		-- Spore also does not exist
		Karm.GUI.addSpore(task.SporeFile, Karm.SporeData[task.SporeFile])
		return true
	end
	local currNode = Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY..task.SporeFile, Relation=Karm.Globals.CHILD, Key=task.TaskID, Text=task.Title, Task=task}
	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	return true	
end

function Karm.GUI.addTaskListToParent(taskList,parentID)
	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	    -- Add the 1st element under the spore
	    local currNode = Karm.GUI.taskTree:AddNode{Relative=parentID, Relation=Karm.Globals.CHILD, Key=taskList[1].TaskID, 
	    		Text=taskList[1].Title, Task=taskList[1]}
		currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    for intVar = 2,taskList.count do
	    	local cond1 = currNode.Key ~= parentID
	    	local cond2 = #taskList[intVar].TaskID > #currNode.Key
	    	local cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	    	while cond1 and not (cond2 and cond3) do
	        	-- Go up the hierarchy
	        	currNode = currNode.Parent
	        	cond1 = currNode.Key ~= parentID
	        	cond2 = #taskList[intVar].TaskID > #currNode.Key
	        	cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	        end
	    	-- Now currNode has the node which is the right parent
	        currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation=Karm.Globals.CHILD, Key=taskList[intVar].TaskID, 
	        		Text=taskList[intVar].Title, Task = taskList[intVar]}
	    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    end
	end  -- if taskList.count > 0 then ends
end

function Karm.GUI.addSpore(key,Spore)
	-- Add the spore node
	Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY, Relation=Karm.Globals.CHILD, Key=Karm.Globals.ROOTKEY..key, Text=Spore.Title, Task = Spore}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].ForeColor,Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key])
	local taskList = Karm.FilterObject.applyFilterHier(Karm.Filter, Spore)
	-- Now add the tasks under the spore in the TaskTree
	Karm.GUI.addTaskListToParent(taskList,Karm.Globals.ROOTKEY..key)
end

--****f* Karm/Karm.GUI.fillTaskTree
-- FUNCTION
-- Function to recreate the task tree based on the global filter criteria from all the loaded spores
--
-- SOURCE
function Karm.GUI.fillTaskTree()
-- ALGORITHM

	local prevSelect, restorePrev
	local expandedStatus = {}
	local visibleNodes = {}
	local planningTasks = {}		-- To carry over the planning mode tasks after the tree is refreshed
	Karm.GUI.taskTree.update = false		-- stop GUI updates for the time being    
    if Karm.GUI.taskTree.nodeCount > 0 then
-- Check if the task Tree has elements then get the current selected nodekey this will be selected again after the tree view is refreshed
        for i,v in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
        	if v.Expanded then
        		-- NOTE: i is the same as the TaskID i.e. i == Karm.GUI.taskTree.Nodes[i].Task.TaskID
            	expandedStatus[i] = true
            end
            if v.Selected then
            	-- Get the Y coordinate for the node and store it
              -- Cycle all cells in the row in case any cell is not visible
            	for j = 1,#Karm.GUI.taskTree.taskTreeConfig do
            		if Karm.GUI.taskTree.treeGrid:BlockToDeviceRect(wx.wxGridCellCoords(v.Row-1,j),wx.wxGridCellCoords(v.Row-1,j)):GetY()~=0 then
            			prevSelect= {i,Karm.GUI.taskTree.treeGrid:BlockToDeviceRect(wx.wxGridCellCoords(v.Row-1,j),wx.wxGridCellCoords(v.Row-1,j)):GetY()}
            			break
            		end
            	end
            	if not prevSelect then
            		prevSelect = {i,0}
            	end
            end
            if v.Row then
            	-- This node is visible
            	-- Get the Y coordinate for the node and store it
            	for j = 1,#Karm.GUI.taskTree.taskTreeConfig do
            		if Karm.GUI.taskTree.treeGrid:BlockToDeviceRect(wx.wxGridCellCoords(v.Row-1,j),wx.wxGridCellCoords(v.Row-1,j)):GetY()~=0 then
            			visibleNodes[i]= Karm.GUI.taskTree.treeGrid:BlockToDeviceRect(wx.wxGridCellCoords(v.Row-1,j),wx.wxGridCellCoords(v.Row-1,j)):GetY()
            			break
            		end
            	end
            	if not visibleNodes[i] then
            		visibleNodes[i] = 0
            	end
            end
        end
        if Karm.GUI.taskTree.taskList and Karm.GUI.taskTree.Planning then
			for i = 1,#Karm.GUI.taskTree.taskList do
				planningTasks[#planningTasks + 1] = Karm.GUI.taskTree.taskList[i].Task
			end        
	        Karm.GUI.taskTree:disablePlanningMode()
        end
        restorePrev = true
        -- Also get the scroll bar status for both windows to restore to the right point
    end
    
-- Clear the treeview and add the root element
    Karm.GUI.taskTree:Clear()
    Karm.GUI.taskTree:AddNode{Key=Karm.Globals.ROOTKEY, Text = "Task Spores"}
    Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY])

    if Karm.SporeData[0] > 0 then
-- Populate the tree control view
        for k,v in pairs(Karm.SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				Karm.GUI.addSpore(k,v)
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(Karm.SporeData) do ends
    end  -- if Karm.SporeData[0] > 0 then ends
	Karm.GUI.taskTree.update = true		-- Resume the tasktree update    
    local selected
    if restorePrev then
-- Update the tree status to before the refresh
        for k,currNode in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
			-- If the node was expanded then expand it now also
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
			-- If node was visible then expand all parents to make the node visible again
			if visibleNodes[k] then
				local node = currNode
				while node.Parent do
					node.Parent.Expanded = true
					node = node.Parent
				end
			end
        end
        for k,currNode in Karm.GUI.taskTree.tvpairs(Karm.GUI.taskTree) do
            if prevSelect and currNode.Key == prevSelect[1] then
                currNode.Selected = true
                selected = currNode.Task
				if prevSelect[2] ~= 0 then
					-- Set the scroll bar to the right position
					local xp,yp,yf
					xp,yp = Karm.GUI.taskTree.treeGrid:GetScrollPixelsPerUnit()
					for j = 1,#Karm.GUI.taskTree.taskTreeConfig do
						if Karm.GUI.taskTree.treeGrid:CellToRect(currNode.Row-1,j):GetY() ~= 0 then
							yf = (Karm.GUI.taskTree.treeGrid:CellToRect(currNode.Row-1,j):GetY()-prevSelect[2])/yp
							break
						end
					end
					if yf then
						Karm.GUI.taskTree.treeGrid:Scroll(-1,yf)
						Karm.GUI.taskTree.ganttGrid:Scroll(-1,yf)
					end
				end
            end
        end
		if not (selected and prevSelect[2]~=0) then
			for k,currNode in Karm.GUI.taskTree.tvpairs(Karm.GUI.taskTree) do
				for i,v in pairs(visibleNodes) do
					if k == i and v~=0 then
						-- Set the scroll bar to the right position
						local xp,yp,yf
						xp,yp = Karm.GUI.taskTree.treeGrid:GetScrollPixelsPerUnit()
						for j = 1,#Karm.GUI.taskTree.taskTreeConfig do
							if Karm.GUI.taskTree.treeGrid:CellToRect(currNode.Row-1,j):GetY() ~= 0 then
								yf = (Karm.GUI.taskTree.treeGrid:CellToRect(currNode.Row-1,j):GetY()-v)/yp
							end
						end
						if yf then
							Karm.GUI.taskTree.treeGrid:Scroll(-1,yf)
							Karm.GUI.taskTree.ganttGrid:Scroll(-1,yf)
						end
					end
				end
			end
		end
        if #planningTasks > 0 then
        	Karm.GUI.taskTree:enablePlanningMode(planningTasks)
        end
    else
 		Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].Expanded = true
    end
	-- Update the Filter summary
	if Karm.Filter then
		Karm.GUI.taskFilter:SetValue(Karm.FilterObject.getSummary(Karm.Filter))
	else
	    Karm.GUI.taskFilter:SetValue("No Filter")
	end
    Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(selected))
end
--@@END@@

function Karm.GUI.frameResize(event)
	local winSize = event:GetSize()
	local hei = 0.6*winSize:GetHeight()
	if winSize:GetHeight() - hei > 400 then
		hei = winSize:GetHeight() - 400
	end
	Karm.GUI.vertSplitWin:SetSashPosition(hei)
	event:Skip()
end

function Karm.GUI.dateRangeChangeEvent(event)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

function Karm.GUI.dateRangeChange()
	-- Clear the GanttGrid
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
end

function Karm.createNewSpore(title, relation, relative)
	if not relative then
		if relation then
			return nil, "relation specified but not relative"
		end
	else
		if not relation then
			if relative ~= Karm.Globals.ROOTKEY then 
				relation = Karm.Globals.NEXT_SIBLING
			else
				relation = Karm.Globals.CHILD
			end
		else
			if (relative == Karm.Globals.ROOTKEY and relation ~= Karm.Globals.CHILD) or (relative and relative ~= Karm.Globals.ROOTKEY and relation == Karm.Globals.CHILD) then
				return nil
			end
		end
	end
	local SporeName
	if title then
		SporeName = title
	else
		SporeName = wx.wxGetTextFromUser("Enter the New Spore File name under which to move the task (Blank to cancel):", "New Spore", "")
	end
	if SporeName == "" then
		return
	end
	relation = relation or Karm.Globals.CHILD
	relative = relative or Karm.Globals.ROOTKEY
	Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
	Karm.SporeData[SporeName].Modified = "YES"
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	Karm.TaskObject.MakeTaskObject(Karm.SporeData[SporeName])
	Karm.GUI.taskTree:AddNode{Relative=relative, Relation=relation, Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName])
	Karm.Globals.unsavedSpores[SporeName] = Karm.SporeData[SporeName].Title
	return Karm.Globals.ROOTKEY..SporeName
end

-- Function to display the task tree with the same expansions as the GUI tree
function Karm.GUI.SelectTask(callBack, dispMessage,multipleSelect)
  if type(callBack) ~= "function" then
    return nil,"Need Call back function to pass on the selected task"
  end
	local frame = wx.wxFrame(Karm.GUI.frame, wx.wxID_ANY, "Select Task", wx.wxDefaultPosition,
		wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
  if dispMessage and dispMessage ~= "" then
    local msgLabel = wx.wxStaticText(frame, wx.wxID_ANY, dispMessage, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
    MainSizer:Add(msgLabel,0,bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
  end
	local taskTree 
  if multipleSelect then
    taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*Karm.GUI.initFrameW, 0.9*Karm.GUI.initFrameH),bit.bor(wx.wxTR_MULTIPLE,wx.wxTR_HAS_BUTTONS))
  else
    taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*Karm.GUI.initFrameW, 0.9*Karm.GUI.initFrameH),bit.bor(wx.wxTR_SINGLE,wx.wxTR_HAS_BUTTONS))
  end
	MainSizer:Add(taskTree, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
	local OKButton = wx.wxButton(frame, wx.wxID_ANY, "OK", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local ChangeFilterButton = wx.wxButton(frame, wx.wxID_ANY, "Change Filter", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CheckBox = wx.wxCheckBox(frame, wx.wxID_ANY, "Show All Tasks", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	
	buttonSizer:Add(OKButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(ChangeFilterButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CheckBox,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
  local treeData
  
  local function populateTasks(filter)
    taskTree:DeleteAllItems()
    -- Add the root
    local root = taskTree:AddRoot("Task Spores")
    treeData = {}
    treeData[root:GetValue()] = {Key = Karm.Globals.ROOTKEY, Parent = nil, Title = "Task Spores", Task = nil,node=root}
      if Karm.SporeData[0] > 0 then
  -- Populate the tree control view
      local count = 0
      -- Loop through all the spores
          for k,v in pairs(Karm.SporeData) do
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
              treeData[currNode:GetValue()] = {Key = Karm.Globals.ROOTKEY..k, Parent = root, Title = strVar,Task=v,node=currNode}
              local taskList = Karm.FilterObject.applyFilterHier(filter, v)
  -- Now add the tasks under the spore in the TaskTree
              if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
                -- Add the 1st element under the spore
                local parent = currNode
                currNode = taskTree:AppendItem(parent,taskList[1].Title)
                treeData[currNode:GetValue()] = {Key = taskList[1].TaskID, Parent = parent, Title = taskList[1].Title, Task = taskList[1], node=currNode}
                for intVar = 2,taskList.count do
                  local cond1 = treeData[currNode:GetValue()].Key ~= Karm.Globals.ROOTKEY..k
                  local cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key
                  local cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key.."_"
                  while cond1 and not (cond2 and cond3) do
                    -- Go up the hierarchy
                    currNode = treeData[currNode:GetValue()].Parent
                    cond1 = treeData[currNode:GetValue()].Key ~= Karm.Globals.ROOTKEY..k
                    cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key
                    cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key.."_"
                  end
                  -- Now currNode has the node which is the right parent
                  parent = currNode
                  currNode = taskTree:AppendItem(parent,taskList[intVar].Title)
                  treeData[currNode:GetValue()] = {Key = taskList[intVar].TaskID, Parent = parent, Title = taskList[intVar].Title, Task = taskList[intVar], node = currNode}
                end
              end  -- if taskList.count > 0 then ends
            end		-- if k~=0 then ends
          -- Repeat for all spores
          end		-- for k,v in pairs(SporeData) do ends
      end  -- if SporeData[0] > 0 then ends
      
    -- Expand the root element
    taskTree:Expand(root)
    -- Now expand all the expanded elements in the 
    for k,v in Karm.GUI.taskTree:tvpairs() do
      if v.Expanded then
        for i,j in pairs(treeData) do
          if v.Key == j.Key then
            taskTree:Expand(j.node)
            break
          end
        end
      end
    end
  end
	
  -- Now populate the tree with all the tasks
  populateTasks(Karm.Filter)
  
	-- Connect the button events
	OKButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function (event)
      local sel, tasks
      if multipleSelect then
        sel = taskTree:GetSelections(sel)
        for i = 1,#sel do
          if treeData[sel[i]:GetValue()].Task then
            tasks[#tasks + 1] = treeData[sel[i]:GetValue()].Task
          else
            tasks[#tasks + 1] = "ROOT"
          end
        end
      else
        sel = taskTree:GetSelection()
        if treeData[sel:GetValue()].Task then
          tasks = treeData[sel:GetValue()].Task
        else
          tasks = "ROOT"
        end
      end
      callBack(tasks)
      frame:Close()
    end
	)
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function (event)
      frame:Close()
    end
  )

	ChangeFilterButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function(event)
      local filterWindowOpen = false
      local function SetFilterCallBack(filter)
        filterWindowOpen = false
        package.loaded["FilterForm"] = Karm.GUI.FilterForm
        if filter then
            populateTasks(filter)
            CheckBox:SetValue(false)
        end
      end
      if not filterWindowOpen then
        package.loaded["FilterForm"] = nil   -- To reload the filterForm (instantiate it again)
        filterWindowOpen = require("FilterForm")
        filterWindowOpen.filterFormActivate(frame,SetFilterCallBack)
      else
        filterWindowOpen.frame:SetFocus()
      end
    end
  )
	
	frame:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
          frame:MakeModal(false)
          frame:Destroy()
        end
  )
  CheckBox:Connect(wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
    function(event)
      if CheckBox then
          populateTasks({})
      else
          populateTasks(Karm.Filter)
      end      
    end
  )

	frame:SetSizer(MainSizer)
	MainSizer:SetSizeHints(frame)
	frame:Layout()
	frame:Show(true)
  frame:MakeModal(true)
end		-- local function SelectTask() ends


-- info contains the following
-- action = ID
-- task = task table that has to be moved/copied
-- dTask = destination relative
-- if copy is true it does a copy otherwise a move
function Karm.moveCopyTask(info,copy)
	-- Do the move/copy task here
  if type(info) ~= "table" or type(info.task) ~= "table" or type(info.dTask) ~= "table" then
    return nil, "info structure not valid"
  end
  if not info.task:IsValidTask() or not info.dTask:IsValidTask() then
    return nil,"Passed task or dTask not a valid task object"
  end
	if info.dTask ~= info.task or (info.dTask == info.task and copy)then
		-- Start the move/copy
		if info.dTask.TaskID == Karm.Globals.ROOTKEY then
			-- Relative is the Root node
			if not copy and (info.action == Karm.Globals.PREV_SIBLING or info.action == Karm.Globals.NEXT_SIBLING) then
				return nil, "Can only move a task under the root task!"
			end
			if copy and (info.action == Karm.Globals.NEXT_SIBLING or info.action == Karm.Globals.NEXT_SIBLING) then
				return nil, "Can only copy a task under the root task!"
			end
			-- This is to move/copy the task into a new Spore
			-- Create a new Spore here and make that the target parent instead of the root node
			info.dTask = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()].Task
		end
		local task, str 
		if not copy then
			task = info.task
			str = "Move"
		else
			-- Make a copy of the task and all its sub tasks and remove any DBDATA from the task to make a new task
			task = Karm.TaskObject.copy(info.task, true, true,true)
			str = "Copy"
		end
		if info.dTask.TaskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Relative is Spore
			if (info.action == Karm.Globals.PREV_SIBLING or info.action == Karm.Globals.NEXT_SIBLING) then
				-- Create a new spore and move/copy it under there (set that the new target parent)
				info.dTask = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()].Task
			end
			-- This is to move/copy the task into this spore
			local taskID
			-- Get a new task ID
			taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
			if taskID == "" then
				-- Cancel the move/copy
				return
			end
			-- Check if the task ID exists in all the loaded spores
			while true do
				local redo = nil
				for k,v in pairs(Karm.SporeData) do
        			if k~=0 then
						local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
						if #list > 0 then
							redo = true
							break
						end
					end
				end
				if redo then
					taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
					if taskID == "" then
						-- Cancel the move/copy
						return
					end
				else
					break
				end
			end		
			
			if not copy then	
				-- Delete it from db
				-- Delete from Spores
				-- Parent of a root node is nil
				Karm.TaskObject.DeleteFromDB(task)
				-- Delete from task Tree GUI
				Karm.GUI.taskTree:DeleteTree(task.TaskID)
				-- Check if the parent of the task needs to be in the GUI
				local done = false
				local currTask = task.Parent
				while not done and currTask do
					if not Karm.Filter.DontShowHierarchy then
						if #Karm.FilterObject.applyFilterList(Karm.Filter,{currTask}) == 0 then
							Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
							currTask = currTask.Parent
						else
							done = true
						end
					end
				end
			end
			Karm.TaskObject.updateTaskID(task,taskID)
			task.Parent = nil
			task.SporeFile = string.sub(info.dTask.TaskID,#Karm.Globals.ROOTKEY+1,-1)
			Karm.GUI.TaskWindowOpen = {Spore = true, Relative = info.dTask.TaskID, Relation = Karm.Globals.CHILD}
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task		
			if task.SubTasks then
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end					
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				Karm.GUI.addTaskListToParent(addList,task.TaskID)
			end		-- if task.SubTasks then ends
			if Karm.GUI.taskTree.Nodes[task.TaskID].Row then
				Karm.GUI.taskTree.Nodes[task.TaskID].Selected = true
				Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(task))
			else
				Karm.GUI.taskTree.Nodes[info.dTask.TaskID].Selected = true
			end
		else		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- This is to move/copy the task in relation to this task
			-- This relative might be a Spore root task or a normal hierarchy task
			if info.action == Karm.Globals.CHILD then
				-- Sub task handling is same in both cases
				if not copy then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
					-- Check if the parent of the task needs to be in the GUI
					local done = false
					local currTask = task.Parent
					while not done and currTask do
						if not Karm.Filter.DontShowHierarchy then
							if #Karm.FilterObject.applyFilterList(Karm.Filter,{currTask}) == 0 then
								Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
								currTask = currTask.Parent
							else
								done = true
							end
						end
					end
				end
				Karm.TaskObject.updateTaskID(task, Karm.TaskObject.getNewChildTaskID(info.dTask))
				task.Parent = info.dTask
				Karm.GUI.TaskWindowOpen = {Relative = info.dTask.TaskID, Relation = Karm.Globals.CHILD}
			else		-- if info.action == Karm.Globals.CHILD then else
				local parent, taskID
				if not info.dTask.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task", "")
					if taskID == "" then
						-- Cancel the move
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
								if #list > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task", "")
							if taskID == "" then
								-- Cancel the move
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil	
				else				
					taskID = Karm.TaskObject.getNewChildTaskID(info.dTask.Parent)
					parent = info.dTask.Parent
				end		-- if not taskList[1].Task.Parent then ends
				if info.action == Karm.Globals.PREV_SIBLING then
					-- Move/Copy Above
					Karm.GUI.TaskWindowOpen = {Relative = info.dTask.TaskID, Relation = Karm.Globals.PREV_SIBLING}
				else
					-- Move/Copy Below
					Karm.GUI.TaskWindowOpen = {Relative = info.dTask.TaskID, Relation = Karm.Globals.NEXT_SIBLING}
				end
				if not copy then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree Karm.GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
					-- Check if the parent of the task needs to be in the GUI
					local done = false
					local currTask = task.Parent
					while not done and currTask do
						if not Karm.Filter.DontShowHierarchy then
							if #Karm.FilterObject.applyFilterList(Karm.Filter,{currTask}) == 0 then
								Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
								currTask = currTask.Parent
							else
								done = true
							end
						end
					end
				end
				Karm.TaskObject.updateTaskID(task,taskID)
				task.Parent = parent
			end		-- if info.action == Karm.Globals.CHILD then ends				
			task.SporeFile = info.dTask.SporeFile
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task
			if task.SubTasks then
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end										
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				Karm.GUI.addTaskListToParent(addList,task.TaskID)
			end		-- if task.SubTasks then ends
			if Karm.GUI.taskTree.Nodes[task.TaskID].Row then
				Karm.GUI.taskTree.Nodes[task.TaskID].Selected = true
				Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(task))
			else
				Karm.GUI.taskTree.Nodes[info.dTask.TaskID].Selected = true
			end
		end		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then ends
		Karm.Globals.unsavedSpores[info.dTask.SporeFile] = Karm.SporeData[info.dTask.SporeFile].Title
    Karm.Globals.unsavedSpores[info.task.SporeFile] = Karm.SporeData[info.task.SporeFile].Title
	end		-- if info.dTask ~= info.task then ends
 end		-- function Karm.ends

function Karm.GUI.taskClicked(task)
	Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(task))
end		-- function taskClicked(task) ends here

function Karm.LoadFilter(file)
	local safeenv = {}
	setmetatable(safeenv, {__index = Karm.Globals.safeenv})
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

function Karm.SetFilterCallBack(filter)
	Karm.GUI.FilterWindowOpen = false
	if filter then
		Karm.Filter = filter
		Karm.GUI.fillTaskTree()
	end
end

function Karm.SetFilter(event)
	if not Karm.GUI.FilterWindowOpen then
		Karm.GUI.FilterForm.filterFormActivate(Karm.GUI.frame,Karm.SetFilterCallBack)
		Karm.GUI.FilterWindowOpen = true
	else
		Karm.GUI.FilterForm.frame:SetFocus()
	end
end

-- Relative = relative of this new node (should be a task ID) 
-- Relation = relation of this new node to the Relative. This can be Karm.Globals.CHILD, Karm.Globals.NEXT_SIBLING, Karm.Globals.PREV_SIBLING
function Karm.NewTaskCallBack(task)
	if task then
		if AutoFillTask then
			AutoFillTask(task)
		end
		if Karm.GUI.TaskWindowOpen.Spore then
			-- Add child to Spore i.e. Create a new root task in the spore
			-- Add the task to the Karm.SporeData
			Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
		else
			-- Normal Hierarchy add
			if Karm.GUI.TaskWindowOpen.Relation == Karm.Globals.CHILD then
				-- Add child
				Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
			elseif Karm.GUI.TaskWindowOpen.Relation == Karm.Globals.NEXT_SIBLING then
				-- Add as next sibling
				if not task.Parent then
					-- Task is a root task in a spore
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER")
					-- Now modify the GUI keys
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
				end		-- if not task.Parent then ends here
			else
				-- Add as previous sibling
				if not task.Parent then
					-- Task is a root spore node
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE")
					-- Now modify the Karm.GUI keys and add it to the UI
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
					-- Move the relative also
					Karm.GUI.taskTree:UpdateKeys(currNode)
					-- Since the Relative ID has changed update the ID in TaskWindowOpen here
					Karm.GUI.TaskWindowOpen.Relative = currNode.Key
				end		-- if not task.Parent then ends here
			end		-- if Karm.GUI.TaskWindowOpen.Relation == Karm.Globals.CHILD then ends here
		end		-- if Karm.GUI.TaskWindowOpen.Spore then ends here
		local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
		if #taskList == 1 then
		    Karm.GUI.taskTree:AddNode{Relative=Karm.GUI.TaskWindowOpen.Relative, Relation=Karm.GUI.TaskWindowOpen.Relation, Key=task.TaskID, Text=task.Title, Task=task}
	    	Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
	    end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
    end		-- if task then ends
	Karm.GUI.TaskWindowOpen = false
end

function Karm.EditTaskCallBack(task, noGUI)
	if task then
		-- Replace task into Karm.GUI.TaskWindowOpen.Task
		if not Karm.GUI.TaskWindowOpen.Task.Parent then
			-- This is a root task in the Spore
			local Spore = Karm.SporeData[Karm.GUI.TaskWindowOpen.Task.SporeFile]
			for i=1,#Spore do
				if Spore[i] == Karm.GUI.TaskWindowOpen.Task then
					Spore[i] = task
					-- The task already has correct links to its neighbors and parent
					-- We just need to update the neighbor links to the task to completely delink the previous task table.
					if task.Previous then
						task.Previous.Next = task
					end
					if task.Next then
						task.Next.Previous = task
					end
					break
				end
			end
		else
			local parentTask = Karm.GUI.TaskWindowOpen.Task.Parent
			for i=1,#parentTask.SubTasks do
				if parentTask.SubTasks[i] == Karm.GUI.TaskWindowOpen.Task then
					parentTask.SubTasks[i] = task
					-- The task already has correct links to its neighbors and parent
					-- We just need to update the neighbor links to the task to completely delink the previous task table.
					if task.Previous then
						task.Previous.Next = task
					end
					if task.Next then
						task.Next.Previous = task
					end
					break
				end
			end
		end
		if not noGUI then
			-- Update the task in the Karm.GUI here
			-- Check if the task passes the filter now
			local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
			if #taskList == 1 then
				-- Check if planning mode if present is still on
				if not task.Planning and not task.PlanWorkDone and Karm.GUI.taskTree.taskList then
					for i = 1,#Karm.GUI.taskTree.taskList do
						if Karm.GUI.taskTree.Nodes[task.TaskID] == Karm.GUI.taskTree.taskList[i] then
							-- The node is in the planning mode list in taskTree but planning has ended in the task so remove it from the list of planning mode tasks
							for k = i + 1, #Karm.GUI.taskTree.taskList - 1 do
								Karm.GUI.taskTree.taskList[k-1] = Karm.GUI.taskTree.taskList[k]
							end
							Karm.GUI.taskTree.taskList[#Karm.GUI.taskTree.taskList] = nil
							break
						end							
					end
				end
				-- It passes the filter so update the task
			    Karm.GUI.taskTree:UpdateNode(task)
				Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
				Karm.GUI.taskClicked(task)
		    else
		    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
		    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
		    	-- Check if the parent of the task needs to be in the GUI
		    	local done = false
		    	local currTask = task.Parent
		    	while not done and currTask do
			    	if not Karm.Filter.DontShowHierarchy then
			    		taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{currTask})
			    		if #taskList == 0 then
			    			Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
			    			currTask = currTask.Parent
			    		else
			    			done = true
			    		end
			    	end
			    end
		    end		-- if #taskList == 1 then ends
		end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
	end
	Karm.GUI.TaskWindowOpen = false
end

function Karm.DeleteTask()
	-- Reset any toggle tools
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	for i = 1,#taskList do
		if taskList[i].Key == Karm.Globals.ROOTKEY then
			-- Root node  deleting requested
			wx.wxMessageBox("Cannot delete the root node!","Root Node Deleting", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		end
	end	
	local confirm
	if #taskList > 1 then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete all selected tasks and all their child elements?", "Confirm Multiple Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	else
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete this task:\n"..taskList[1].Title.."\n and all its child elements?", "Confirm Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	end
	local response = confirm:ShowModal()
	if response == wx.wxID_YES then
		for i = 1,#taskList do
			-- Delete from Spores
			if taskList[i].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
				-- This is a Spore node
				Karm.SporeData[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
				Karm.SporeData[0] = Karm.SporeData[0] - 1
				Karm.Globals.unsavedSpores[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
			else
				-- This is a normal task
				Karm.TaskObject.DeleteFromDB(taskList[i].Task)
				Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
			end
			local task = taskList[i].Task
			Karm.GUI.taskTree:DeleteTree(taskList[i].Key)
			-- Check if the parent of the task needs to be in the GUI
			local done = false
			local currTask = task.Parent
			while not done and currTask do
				if not Karm.Filter.DontShowHierarchy then
					taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{currTask})
					if #taskList == 0 then
						Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
						currTask = currTask.Parent
					else
						done = true
					end
				end
			end
		end		-- for i = 1,#taskList do ends
	end
end		-- function Karm.DeleteTask() ends here

function Karm.InitiateMoveCopy(relation, copy)
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
    wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    return
	end			
	if #taskList > 1 then
    if copy then
      wx.wxMessageBox("Just select a single task to copy.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
      wx.wxMessageBox("Just select a single task to move.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    end
    return
	end	
	if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
    if copy then
      wx.wxMessageBox("Cannot copy the root node or a Spore node. Please select a task to be copied.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
      wx.wxMessageBox("Cannot move the root node or a Spore node. Please select a task to be moved.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    end
    return
	end	
	local info = {}

	info.action = relation
	info.task = taskList[1].Task
	local status
  local function doMove(task)
    if not task then 
      return
    end
    if task == "ROOT" then
      task = nil
    end
    info.dTask = task
    Karm.moveCopyTask(info, copy)
  end
  
  Karm.GUI.SelectTask(doMove,"Select the task to move the task: ".." under")
	return true
end

function Karm.EditTask()
	-- Reset any toggle tools
	if not Karm.GUI.TaskWindowOpen then
		-- Get the selected task
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end		
		-- Get the new task task ID
		local taskID = taskList[1].Key
		if taskID == Karm.Globals.ROOTKEY then
			-- Root node editing requested
			wx.wxMessageBox("Nothing editable in the root node","Root Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		elseif taskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Spore node editing requested
			wx.wxMessageBox("Nothing editable in the spore node","Spore Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		else
			-- A normal task editing requested
			Karm.GUI.TaskWindowOpen = {Task = taskList[1].Task}
			Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.EditTaskCallBack,taskList[1].Task)
		end
	end
end

function Karm.NewTask(relation, readyMadeTask)
	if (relation == Karm.Globals.PREV_SIBLING or relation == Karm.Globals.NEXT_SIBLING or relation == Karm.Globals.CHILD) and ((readyMadeTask and type(readyMadeTask)=="table" and getmetatable(readyMadeTask)==Karm.TaskObject) or not readyMadeTask) then
		-- Reset any toggle tools
		if not Karm.GUI.TaskWindowOpen then
			local taskList = Karm.GUI.taskTree.Selected
			if #taskList == 0 then
	            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	            return
			end			
			if #taskList > 1 then
	            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	            return
			end		
			-- Get the new task task ID
			local relativeID = taskList[1].Key
			local task
			if readyMadeTask then
				task = readyMadeTask:copy(true,true,true)
			else
				task = {}
				Karm.TaskObject.MakeTaskObject(task)
			end
			-- There are 4 levels that need to be handled
			-- 1. Root node on the tree
			-- 2. Spore Node
			-- 3. Root task node in a Spore
			-- 4. Normal task node
			if relativeID == Karm.Globals.ROOTKEY then
				-- 1. Root node on the tree
				if relation == Karm.Globals.PREV_SIBLING or relation == Karm.Globals.NEXT_SIBLING then
		            wx.wxMessageBox("A sibling for the root node cannot be created.","Root Node Sibling", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		            return
				end						
				-- This is the root so the request is to create a new spore
				Karm.createNewSpore(task.Title)
			elseif relativeID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
				-- 2. Spore Node
				if relation == Karm.Globals.PREV_SIBLING or relation == Karm.Globals.NEXT_SIBLING then
					Karm.createNewSpore(task.Title, relation, relativeID)
				else
					-- This is a Spore so the request is to create a new root task in the spore
					task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
					if task.TaskID == "" then
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
								if #taskList > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
							if task.TaskID == "" then
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil		
					task.SporeFile = string.sub(Karm.GUI.taskTree.Nodes[relativeID].Key,#Karm.Globals.ROOTKEY+1,-1)
					Karm.GUI.TaskWindowOpen = {Spore = true, Relative = relativeID, Relation = Karm.Globals.CHILD}
					if readyMadeTask then
						if task:IsValidTask() then
							Karm.NewTaskCallBack(task)
						else
							Karm.GUI.TaskWindowOpen = nil
						end						
					else
						Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
					end
				end
			else	-- if for checking the task level
				-- 3. Root task node in a Spore
				-- 4. Normal task node
				-- This is a normal task so the request is to create a new task relative to this task
				if relation == Karm.Globals.CHILD then
					-- Sub task handling is same in both cases
					task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task)
					task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = Karm.Globals.CHILD}
				else
					if not Karm.GUI.taskTree.Nodes[relativeID].Task.Parent then
						-- This is a spore root node so will have to ask for the task ID from the user
						task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
						if task.TaskID == "" then
							return
						end
						-- Check if the task ID exists in all the loaded spores
						while true do
							local redo = nil
							for k,v in pairs(Karm.SporeData) do
			        			if k~=0 then
									local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
									if #taskList > 0 then
										redo = true
										break
									end
								end
							end
							if redo then
								task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
								if task.TaskID == "" then
									return
								end
							else
								break
							end
						end		
						-- Parent of a root node is nil	
					else				
						task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task.Parent)
						task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task.Parent
					end
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = relation}
				end
				task.SporeFile = Karm.GUI.taskTree.Nodes[relativeID].Task.SporeFile
				if readyMadeTask then
					if task:IsValidTask() then
						Karm.NewTaskCallBack(task)
					else
						Karm.GUI.TaskWindowOpen = nil
					end						
				else
					Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
				end
			end		-- if relativeID == Karm.Globals.ROOTKEY then ends
		else
			Karm.GUI.TaskForm.frame:SetFocus()
		end
	end	-- Validating relation if ends here	
end

function Karm.CharKeyEvent(event)
	print("Caught Keypress")
	local kc = event:GetKeyCode()
	if kc == wx.WXK_ESCAPE then
		print("Caught Escape")
		-- Check possible ESCAPE actions
	end
end

function Karm.connectKeyUpEvent(win)
	if win then
		pcall(win.Connect,win,wx.wxID_ANY, wx.wxEVT_KEY_UP, Karm.CharKeyEvent)
		local childNode = win:GetChildren():GetFirst()
		while childNode do
			Karm.connectKeyUpEvent(childNode:GetData())
			childNode = childNode:GetNext()
		end
	end
end

function Karm.SaveAllSpores()
	-- Reset any toggle tools
	for k,v in pairs(Karm.SporeData) do
		if k ~= 0 then
			Karm.saveKarmSpore(k)
		end
	end
	Karm.Globals.unsavedSpores = {}
end

function Karm.saveKarmSpore(Spore)
	-- Check Spore integrity
	local file,err,path
	err = Karm.TaskObject.CheckSporeIntegrity(nil,Karm.SporeData[Spore])
	if #err > 0 then
		path = "Errors in Spore: "..Spore.."\n"
		for i = 1,#err do
			path = path.."Task: "..err[i].Task.Title.." ERROR: "..err[i].Error.."\n"
		end
		wx.wxMessageBox(path,"Integrity Error in Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end
	if Karm.SporeData[Spore].Modified then
		local notOK = true
		while notOK do
		    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Save Spore: "..Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore].Title,
		                                       "",
		                                       "",
		                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
		                                       wx.wxFD_SAVE)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	if Karm.SporeData[path] then
		    		wx.wxMessageBox("Spore already exist select a different name please.","Name Conflict", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		    	else
		    		notOK = nil
			    	path = fileDialog:GetPath()
			    	file,err = io.open(path,"w+")
			    end
		    else
		    	return
		    end
		    fileDialog:Destroy()
		end
	else
		path = Spore
		file,err = io.open(path,"w+")
	end		-- if Karm.SporeData[Spore].Modified then ends
	if not file then
        wx.wxMessageBox("Unable to save as file '"..path.."'.\n "..err, "File Save Error", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
    	if Spore ~= path then
    		-- Update the Spore File name in all the tasks and the root Spore
			Karm.SporeData[path] = Karm.SporeData[Spore]    
			Karm.SporeData[Spore] = nil
			Karm.SporeData[path].SporeFile = path
			Karm.SporeData[path].TaskID = Karm.Globals.ROOTKEY..path
			Karm.SporeData[path].Title = Karm.sporeTitle(path)		
			Karm.GUI.taskTree:UpdateKeys(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore],true)
			Karm.GUI.taskTree:UpdateNode(Karm.SporeData[path])
			-- Now update all sub tasks
			local taskList = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[path])
			if #taskList > 0 then
				for i = 1,#taskList do
					taskList[i].SporeFile = path
				end
			end
    	end
    	Karm.SporeData[path].Modified = false
    	file:write(Karm.Utility.tableToString2(Karm.SporeData[path]))
    	file:close()
    	Karm.Globals.unsavedSpores[Spore] = nil
    end
end

function Karm.SaveCurrSpore()
	-- Reset any toggle tools
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 or (#taskList>0 and not taskList[1].Task) then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be Saved
	Karm.saveKarmSpore(Spore)
end

function Karm.loadXML()
	-- Reset any toggle tools
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open XML Spore file",
                                       "",
                                       "",
                                       "XML Spore files (*.xml)|*.xml|All files (*)|*",
                                       wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
		Karm.SporeData[fileDialog:GetPath()] = Karm.XML2Data(xml.load(fileDialog:GetPath()), fileDialog:GetPath())
		Karm.SporeData[fileDialog:GetPath()].Modified = true
		Karm.SporeData[0] = Karm.SporeData[0] + 1
    end
    fileDialog:Destroy()
end

-- Function to load a Spore given the Spore file path in the data structure and the GUI
-- Inputs:
-- file - the file name with full path of the Spore to load
-- commands - A table containin the set of commands on behavior
--		onlyData - if true then only the Spore Data is loaded GUI is not touched or queried
--		forceReload - if true reloads the data over the existing data
-- Returns true if successful otherwise throws an error
-- Error Codes returned:
--		 1 - Spore Already loaded
-- 		 2 - Task ID in the Spore already exists in the memory
--		 3 - No valid Spore found in the file
--		 4 - File load error
function Karm.loadKarmSpore(file, commands)
	local Spore
	do
		local safeenv = {}
		setmetatable(safeenv, {__index = Karm.Globals.safeenv})
		local f,message = loadfile(file)
		if not f then
			error({msg = "loadKarmSpore:4 "..message, code = "loadKarmSpore:4"},2)
		end
		setfenv(f,safeenv)
		f()
		if Karm.validateSpore(safeenv.t0) then
			Spore = safeenv.t0
		else
			error({msg = "loadKarmSpore:3 No valid Spore found in the file", code = "loadKarmSpore:3"},2)
		end
	end
	-- Update the SporeFile in all the tasks and set the metatable
	Spore.SporeFile = file
	-- Now update all sub tasks
	local list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	if #list1 > 0 then
		for i = 1,#list1 do
			list1[i].SporeFile = Spore.SporeFile
			Karm.TaskObject.MakeTaskObject(list1[i])
		end
	end        	
	-- First update the Karm.Globals.ROOTKEY
	Spore.TaskID = Karm.Globals.ROOTKEY..Spore.SporeFile
	Karm.TaskObject.MakeTaskObject(Spore)
	-- Get list of task in the spore
	list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	local reload = nil
	-- Now check if the spore is already loaded in the dB
	for k,v in pairs(Karm.SporeData) do
		if k~=0 then
			if k == Spore.SporeFile then
				if commands.forceReload then
					-- Reload the spore
					reload = true
				else
					error({msg = "loadKarmSpore:1 Spore already loaded", code = "loadKarmSpore:1"},2)
				end
			end		-- if k == Spore.SporeFile then ends
			-- Check if any task ID is clashing with the existing tasks
			local list2 = Karm.FilterObject.applyFilterHier(nil,v)
			for i = 1,#list1 do
				for j = 1,#list2 do
					if list1[i].TaskID == list2[j].TaskID then
						error({msg = "loadKarmSpore:2 Task ID in the Spore already exists in the memory", code = "loadKarmSpore:2"},2)
					end
				end		-- for j = 1,#list2 do ends
			end		-- for i = 1,#list1 do ends
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(Karm.SporeData) do ends
	if reload then
		-- Delete the current spore
		Karm.SporeData[Spore.SporeFile] = nil
		if not commands.onlyData and Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore.SporeFile] then
			Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore.SporeFile)
		end
	end
	-- Load the spore here
	Karm.SporeData[Spore.SporeFile] = Spore
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	if not commands.onlyData then
		-- Load the Spore in the Karm.GUI here
		Karm.GUI.addSpore(Spore.SporeFile,Spore)
	end
	return true
end		-- function Karm.loadKarmSpore(file, commands) ends here

function Karm.openKarmSpore()
	-- Reset any toggle tools
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open Spore file",
                                       "",
                                       "",
                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local result,message = pcall(Karm.loadKarmSpore,fileDialog:GetPath(),{})
        if not result then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.\n "..message.msg,
                            "File Load Error",
                            wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        end
    end
    fileDialog:Destroy()
end		-- function Karm.openKarmSpore()ends

function Karm.unloadKarmSpore(Spore)
	if not Karm.SporeData[Spore] then
		error("Cannot find the Spore:"..Spore.." in loaded data",2)
	end
	Karm.SporeData[Spore] = nil
	Karm.SporeData[0] = Karm.SporeData[0] - 1
	Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore)
	Karm.Globals.unsavedSpores[Spore] = nil
end

function Karm.unloadSpore()
	-- Reset any toggle tools
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be unloaded
	local confirm, response
	if Karm.Globals.unsavedSpores[Spore] then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"The spore "..Karm.Globals.unsavedSpores[Spore].." has unsaved changes. Are you sure you want to unload the spore and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT)
		response = confirm:ShowModal()
	else
		response = wx.wxID_YES
	end
	if response == wx.wxID_YES then
		Karm.unloadKarmSpore(Spore)
	end
end

function Karm.GUI.menuEventHandlerFunction(ID, code, file)
	if not ID or (not code and not file) or (code and file) then
		error("menuEventHandler: invalid parameters passed, need the ID and only 1 of code chunk or file name.")
	end
	local handler
	if code then
		handler = function(event)
			local f,message = loadstring("local myID="..tostring(ID).."\n"..code)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()
		end
	else
		handler = function(event)
	    	local fil,err = io.open(file,"r")
	    	local str
	    	if not fil then
	            error("Unable to load file '"..file.."'.\n "..err, 1)
	        else
	        	str = fil:read("*all")
	        	fil:close()
	        end
			local f,message = loadstring("local myID="..tostring(ID).."\n"..str)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()		
		end
	end
	return handler
end

function Karm.finalizePlanningAll(taskList, type)
	for i = 1,#taskList do
		Karm.finalizePlanning(taskList[i], type)
	end
end

-- To finalize the planning of a task and convert it to a normal schedule
function Karm.finalizePlanning(task, planType)
	if not Karm.TaskObject.IsValidTask(task) then
		error("Invalid Task Object passed to finalizePlanning", 2)
	end
	planType = planType or "NORMAL"
	local list
	if planType == "NORMAL" then
		list = Karm.TaskObject.getLatestScheduleDates(task,true)
	else
		list = Karm.TaskObject.getWorkDoneDates(task,true)
	end
	if list and #list > 0 then
		local todayDate = wx.wxDateTime()
		todayDate:SetToCurrent()
		todayDate = Karm.Utility.toXMLDate(todayDate:Format("%m/%d/%Y"))	
		local list1
		if planType =="NORMAL" then
			list1 = Karm.TaskObject.getLatestScheduleDates(task)
		else
			list1 = Karm.TaskObject.getWorkDoneDates(task)
		end
		-- Compare the schedules
		local same = true
		if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and 
		  not(list1.typeSchedule=="Commit" and list.typeSchedule == "Revs")) then
		  	-- If latest was Commit and Planning was Revs then if the dates are the same the schedules are the same
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
			if not task.Schedules then
				task.Schedules = {}
			end
			if not task.Schedules[list.typeSchedule] then
				-- Schedule type does not exist so create it
				task.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}
			end
			-- Schedule type already exists so just add it to the next index
			local newSched = {[0]=list.typeSchedule}
			local str = "WD"
			if list.typeSchedule ~= "Actual" then
				str = "DP"
			end
			newSched.Updated = todayDate
			-- Update the period
			newSched.Period = {[0] = "Period", count = #list}
			for i = 1,#list do
				newSched.Period[i] = {[0] = str, Date = list[i]}
			end
			task.Schedules[list.typeSchedule][list.index] = newSched
			task.Schedules[list.typeSchedule].count = list.index
		end
	end		-- if list ends here
	-- Make sure the task passes checkTask
	if type(checkTask) == "function" then
		local err,msg = checkTask(task)
		if not err then
			msg = msg or "Error in the task reported by checkTask. Please review."
			wx.wxMessageBox(msg, "Task Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return nil
		end
	end

	if planType =="NORMAL" then
		task.Planning = nil
	else
		task.PlanWorkDone = nil
	end	
	-- Remove the task from the planning list
	if Karm.GUI.taskTree.taskList then
		for i = 1,#Karm.GUI.taskTree.taskList do
			if Karm.GUI.taskTree.taskList[i].Task == task then
				-- Remove this one
				for j = i,#Karm.GUI.taskTree.taskList - 1 do
					Karm.GUI.taskTree.taskList[j] = Karm.GUI.taskTree.taskList[j + 1]
				end
				Karm.GUI.taskTree.taskList[#Karm.GUI.taskTree.taskList] = nil
				break
			end
		end
	end
	-- Check if the task passes the filter now
	local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
	if #taskList == 1 then
		-- It passes the filter so update the task
		if not Karm.GUI.taskTree.Nodes[task.TaskID] then
			Karm.GUI.addTask(task)
		end
	    Karm.GUI.taskTree:UpdateNode(task)
		Karm.GUI.taskClicked(task)
		-- Update all the parents as well
		local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
		while currNode and currNode.Parent do
			currNode = currNode.Parent
			if currNode.Task then
				Karm.GUI.taskTree:UpdateNode(currNode.Task)
			end
		end
    else
    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
    	-- Check if the parent of the task needs to be in the GUI
    	local done = false
    	local currTask = task.Parent
    	while not done and currTask do
	    	if not Karm.Filter.DontShowHierarchy then
	    		taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{currTask})
	    		if #taskList == 0 then
	    			Karm.GUI.taskTree:DeleteSubUpdate(currTask.TaskID)
	    			currTask = currTask.Parent
	    		else
	    			done = true
	    		end
	    	end
	    end
    end
    Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
end		-- function Karm.finalizePlanning ends

function Karm.RunFile(file)
	local f,message = loadfile(file)
	if not f then
		wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running File: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.RunScript(script)
	local f,message = loadstring(script)
	if not f then
		wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running Script: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.Macro()
	-- Get the macro details
	local frame = wx.wxFrame(Karm.GUI.frame, wx.wxID_ANY, "Enter Macro Details", wx.wxDefaultPosition,wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
	local MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)
		local ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, "Enter Script here:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local scriptButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local CompileButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local RunButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local CancelButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			scriptButtonSizer:Add(CompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(RunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ScriptPanelSizer:Add(scriptButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		ScriptPanel:SetSizer(ScriptPanelSizer)
		ScriptPanelSizer:SetSizeHints(ScriptPanel)
	MainBook:AddPage(ScriptPanel, "Run Code")
		local FilePanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local FilePanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local FileInsLabel = wx.wxStaticText(FilePanel, wx.wxID_ANY, "Select Lua script file:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			FilePanelSizer:Add(FileInsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local fileBrowseSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileBox = wx.wxTextCtrl(FilePanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
			fileBrowseSizer:Add(FileBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local BrowseButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Browse...", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			fileBrowseSizer:Add(BrowseButton,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileBrowseSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local fileButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileCompileButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileRunButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileCancelButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			fileButtonSizer:Add(FileCompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileRunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileCancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		FilePanel:SetSizer(FilePanelSizer)
		FilePanelSizer:SetSizeHints(FilePanel)
	MainBook:AddPage(FilePanel, "Run File")
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
	-- Events
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)
	
	FileCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)

	RunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunScript(ScriptBox:GetValue())
			end
		end		
	)

	FileRunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the File
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunFile(FileBox:GetValue())
			end
		end		
	)

	BrowseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
		    local fileDialog = wx.wxFileDialog(frame, "Select file",
		                                       "",
		                                       "",
		                                       "Lua files (*.lua)|*.lua|wxLua files (*.wlua)|*.wlua|All files (*)|*",
		                                       wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	FileBox:SetValue(fileDialog:GetPath())
		    end
		    fileDialog:Destroy()
		end		
	)

	CompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	FileCompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	frame:SetSizer(MainSizer)
	frame:Layout()
	frame:Show(true)
end

function Karm.GUI.refreshToolBar()
	Karm.GUI.toolbar:ClearTools()
	for i = 1,#Karm.GUI.Tools do
		if Karm.GUI.Tools[i] == "SEPARATOR" then
			Karm.GUI.toolbar:AddSeparator()
		elseif type(Karm.GUI.Tools[i]) == "table" then
			local bM
			local toolBmpSize = Karm.GUI.toolbar:GetToolBitmapSize()
			if not Karm.GUI.Tools[i].Image.Type then
				--local toolBmpSize = wx.wxSize(16,16)
				bM = wx.wxArtProvider.GetBitmap(Karm.GUI.Tools[i].Image.Data, wx.wxART_TOOLBAR, toolBmpSize)
			else
				bM = wx.wxImage()
				local err = bM:LoadFile(Karm.GUI.Tools[i].Image.Data,Karm.GUI.Tools[i].Image.Type)
				if not err then
					bM = wx.wxArtProvider.GetBitmap(wx.wxART_INFORMATION, wx.wxART_TOOLBAR, toolBmpSize)
				else
					bM = wx.wxBitmap(bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight()))				
				end
			end
			if Karm.GUI.Tools[i].Type and Karm.GUI.Tools[i].Type ~= wx.wxITEM_NORMAL and Karm.GUI.Tools[i].Type ~= wx.wxITEM_CHECK and Karm.GUI.Tools[i].Type ~= wx.wxITEM_RADIO then
				Karm.GUI.Tools[i].Type = nil
			end
			local ID = Karm.NewID()
			Karm.GUI.toolbar:AddTool(ID, Karm.GUI.Tools[i].Text or "", bM, Karm.GUI.Tools[i].HelpText or "", Karm.GUI.Tools[i].Type or wx.wxITEM_NORMAL)
			-- Connect the event for this
			Karm.GUI.frame:Connect(ID, wx.wxEVT_COMMAND_MENU_SELECTED,Karm.GUI.menuEventHandlerFunction(ID,Karm.GUI.Tools[i].Code,Karm.GUI.Tools[i].File))
		end			
	end	
	Karm.GUI.toolbar:Realize()
end

function Karm.GUI.refreshMenuBar()
	for i = 1,Karm.GUI.menuBar:GetMenuCount() do
		Karm.GUI.menuBar:Remove(0)
	end
    local getMenu
    getMenu = function(menuTable)
		local newMenu = wx.wxMenu()    
		for j = 1,#menuTable do
			if menuTable[j].Text and menuTable[j].HelpText and (menuTable[j].Code or menuTable[j].File) then
				local ID = Karm.NewID()
				newMenu:Append(ID,menuTable[j].Text,menuTable[j].HelpText, menuTable[j].ItemKind or wx.wxITEM_NORMAL)
				-- Connect the event for this
				Karm.GUI.frame:Connect(ID, wx.wxEVT_COMMAND_MENU_SELECTED,Karm.GUI.menuEventHandlerFunction(ID,menuTable[j].Code,menuTable[j].File))
			elseif menuTable[j].Text and menuTable[j].Menu then
				newMenu:Append(wx.wxID_ANY,menuTable[j].Text,getMenu(menuTable[j].Menu))
			end
		end
		return newMenu
    end

    -- create the menubar and attach it
	for i = 1,#Karm.GUI.MainMenu do
		if Karm.GUI.MainMenu[i].Text and Karm.GUI.MainMenu[i].Menu then
			Karm.GUI.menuBar:Append(getMenu(Karm.GUI.MainMenu[i].Menu),Karm.GUI.MainMenu[i].Text)
		end
	end    

end

function Karm.main()
    Karm.GUI.frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE + wx.wxWANTS_CHARS)

	-- Toolbar generation
--[[
Sample Table for a Tool:
		{	-- Load XML file
			Text = "Load XML",
			Code = "Karm.loadXML",
			HelpText = "Load XML Spore from Disk",
			Image = { Type = wx.wxBITMAP_TYPE_PNG,
					  Data = "images/load_xml.png"
			}
		},
]]	
	Karm.GUI.toolbar = Karm.GUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	Karm.GUI.refreshToolBar()
	-- Create the menubar
    Karm.GUI.menuBar = wx.wxMenuBar()
    Karm.GUI.refreshMenuBar()

	-- Create status Bar in the window
    Karm.GUI.statusBar = Karm.GUI.frame:CreateStatusBar(2)
    -- Text for the 1st field in the status bar
    Karm.GUI.frame:SetStatusText("Welcome to Karm", 0)
    Karm.GUI.frame:SetStatusBarPane(-1)
    -- text for the second field in the status bar
    --Karm.GUI.frame:SetStatusText("Test", 1)
    -- Set the width of the second field to 25% of the whole window
    local widths = {}
    widths[1]=-3
    widths[2] = -1
    Karm.GUI.frame:SetStatusWidths(widths)
    Karm.GUI.defaultColor.Red = Karm.GUI.statusBar:GetBackgroundColour():Red()
    Karm.GUI.defaultColor.Green = Karm.GUI.statusBar:GetBackgroundColour():Green()
    Karm.GUI.defaultColor.Blue = Karm.GUI.statusBar:GetBackgroundColour():Blue()
    
    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    Karm.GUI.frame:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
        	local count = 0 
			local sporeList = ""
			for k,v in pairs(Karm.Globals.unsavedSpores) do 
				count = count + 1 
				sporeList = sporeList..Karm.Globals.unsavedSpores[k].."\n"
			end 
			local confirm, response 
			if count > 0 then 
				confirm = wx.wxMessageDialog(Karm.GUI.frame,"The following spores:\n"..sporeList.." have unsaved changes. Are you sure you want to exit and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT) 
				response = confirm:ShowModal() 
			else 
				response = wx.wxID_YES 
			end 
			if response == wx.wxID_YES then 
				Karm.GUI.frame:Destroy() 
			end
        end )

    Karm.GUI.frame:SetMenuBar(Karm.GUI.menuBar)
	Karm.GUI.vertSplitWin = wx.wxSplitterWindow(Karm.GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	Karm.GUI.vertSplitWin:SetMinimumPaneSize(10)
	
	Karm.GUI.taskTree = Karm.GUI.TreeGantt.newTreeGantt(Karm.GUI.vertSplitWin)
	
	-- Panel to contain the task details and filter criteria text boxes
	local detailsPanel = wx.wxPanel(Karm.GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxTAB_TRAVERSAL, "Task Details Parent Panel")
	-- Main sizer in the detailsPanel containing everything
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	-- Static Box sizer to place the text boxes horizontally (Note: This sizer displays a border and some text on the top)
	local staticBoxSizer1 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Task Details")
	
	-- Task Details text box
	Karm.GUI.taskDetails = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Task Selected", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Details Box")
	staticBoxSizer1:Add(Karm.GUI.taskDetails, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	-- Box sizer on the right size to place the Criteria text box and above that the sizer containing the date picker control
	--   to set the dates displayed in the Gantt Grid
	local boxSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
	-- Sizer inside box sizer2 containing the date picker controls
	local boxSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	Karm.GUI.dateStartPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local month = wx.wxDateSpan(0,1,0,0)
	Karm.GUI.dateFinPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	boxSizer3:Add(Karm.GUI.dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer3:Add(Karm.GUI.dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer2:Add(boxSizer3,0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	local staticBoxSizer2 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Filter Criteria")
	Karm.GUI.taskFilter = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Filter", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Filter Criteria")
	staticBoxSizer2:Add(Karm.GUI.taskFilter, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer2:Add(staticBoxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer1:Add(boxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	detailsPanel:SetSizer(boxSizer1)
	boxSizer1:Fit(detailsPanel)
	boxSizer1:SetSizeHints(detailsPanel)
	Karm.GUI.vertSplitWin:SplitHorizontally(Karm.GUI.taskTree.horSplitWin, detailsPanel)
	Karm.GUI.vertSplitWin:SetSashPosition(0.7*Karm.GUI.initFrameH)

	-- ********************EVENTS***********************************************************************
	-- Date Picker Events
	Karm.GUI.dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	Karm.GUI.dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	
	-- Frame resize event
	Karm.GUI.frame:Connect(wx.wxEVT_SIZE, Karm.GUI.frameResize)
	
	-- Task Details click event
	Karm.GUI.taskDetails:Connect(wx.wxEVT_LEFT_DOWN,function(event) print(menuItems) end)
	
    -- Task selection in task tree
    Karm.GUI.taskTree:associateEventFunc({cellClickCallBack = Karm.GUI.taskClicked})
    -- *******************EVENTS FINISHED***************************************************************
    Karm.GUI.frame:Layout() -- help sizing the windows before being shown
    Karm.GUI.dateRangeChange()	-- To create the colums for the current date range in the GanttGrid

    Karm.GUI.taskTree:layout()
    
    -- Fill the task tree now
    Karm.GUI.fillTaskTree()
		
    wx.wxGetApp():SetTopWindow(Karm.GUI.frame)
    
	-- Key Press events
	--connectKeyUpEvent(Karm.GUI.frame)

	-- Get the user ID
    Karm.GUI.frame:Show(true)
	if not Karm.Globals.User then
		local user = ""
		while user == "" do
			user = wx.wxGetTextFromUser("Enter the user ID", "User ID", "")
		end
		Karm.Globals.User = user
	end
    Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end

function Karm.Initialize()
	-- Show the Splash Screen
	wx.wxInitAllImageHandlers()
	local splash = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm", wx.wxDefaultPosition, wx.wxSize(400, 300),
                        wx.wxSTAY_ON_TOP + wx.wxFRAME_NO_TASKBAR)
    local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
    --local textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    --local dc = wx.wxPaintDC(textBox)
    --local wid,height
    --textBox:SetFont(wx.wxFont(30, wx.wxFONTFAMILY_SWISS, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD))
    --wid,height = dc:GetTextExtent("Karm",wx.wxFont(30, wx.wxFONTFAMILY_ROMAN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD) )
    --local textAttr = wx.wxTextAttr()
    --textBox:WriteText("Karm")
    --sizer:Add(textBox, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    local panel = wx.wxPanel(splash, wx.wxID_ANY)
	local image = wx.wxImage("images/SplashImage.jpg",wx.wxBITMAP_TYPE_JPEG)
	--image = image:Scale(100,100)
    sizer:Add(panel, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    local sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
    local textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "Version: "..Karm.Globals.KARM_VERSION, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_LEFT + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    sizer1:Add(textBox, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 5)
    textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "Contact: karm@amved.com", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_RIGHT + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    sizer1:Add(textBox, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 5)
    sizer:Add(sizer1,0,wx.wxALL+wx.wxEXPAND,1)
    panel:Connect(wx.wxEVT_PAINT,function(event)
		    local cdc = wx.wxPaintDC(event:GetEventObject():DynamicCast("wxWindow"))
		    cdc:DrawBitmap(wx.wxBitmap(image),11,0,false)
		    cdc:delete()
	    end
	)
    splash:SetSizer(sizer)
    splash:Centre()
    splash:Layout()
    splash:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    splash:Show(true)
	local done 
    local timer = wx.wxTimer(splash)
    splash:Connect(wx.wxEVT_TIMER,function(event)
								if done then
									splash:Close()
									timer:Stop()
									Karm.main()
								else
									done = true
								end
    						end)
    timer:Start(3000, true)
    -- Load the configuration file and the Task spores
    
	local configFile = "KarmConfig.lua"
	local f=io.open(configFile,"r")
	if f~=nil then 
		io.close(f) 
		-- load the configuration file
		dofile(configFile)
	end
	-- Load all the XML spores
	local count = 1
	Karm.SporeData[0] = 0
	-- print(Spores[count])
	if Karm.Spores then
		while Karm.Spores[count] do
			if Karm.Spores[count].type == "XML" then
				-- XML file
				Karm.SporeData[Karm.Spores[count].file] = Karm.XML2Data(xml.load(Karm.Spores[count].file), Karm.Spores[count].file)
				Karm.SporeData[Karm.Spores[count].file].Modified = true
				Karm.SporeData[0] = Karm.SporeData[0] + 1
			else
				-- Normal Karm File
				local result,message = pcall(Karm.loadKarmSpore,Karm.Spores[count].file, {onlyData=true})
			end
			count = count + 1
		end
	end
	if done then
		splash:Close()
		timer:Stop()
		Karm.main()
	else
		done = true
	end
end		-- function Karm.Initialize() ends

-- Do all the initial Configuration and Initialization
Karm.Initialize()

--main()

-- refreshTree()
-- fillDummyData()

-- updateTree(Karm.SporeData)


-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
