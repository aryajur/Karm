local modname = ...
local tableToString = Karm.Utility.tableToString
local toXMLDate = Karm.Utility.toXMLDate
local getWeekDay = Karm.Utility.getWeekDay
local XMLDate2wxDateTime = Karm.Utility.XMLDate2wxDateTime
local GUI = Karm.GUI
local getWorkDates = Karm.TaskObject.getWorkDates
local getDates = Karm.TaskObject.getDates
local getLatestScheduleDates = Karm.TaskObject.getLatestScheduleDates
local getWorkDoneDates = Karm.TaskObject.getWorkDoneDates
local getmetatable = getmetatable
local setmetatable = setmetatable
local Globals = Karm.Globals
local togglePlanningType = Karm.TaskObject.togglePlanningType
local togglePlanningDate = Karm.TaskObject.togglePlanningDate
local wx = wx
local type = type
local pairs = pairs
local getfenv = getfenv
local setfenv = setfenv
local loadstring = loadstring
local load = load
local string = string
local pcall = pcall
local tostring = tostring
	
----------------------------------------------------------
local M = {}
package.loaded[modname] = M
if setfenv then
	setfenv(1,M)
else
	_ENV = M
end
----------------------------------------------------------

-- Generate a unique new wxWindowID
do
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
	function NewID()
	    ID_IDCOUNTER = ID_IDCOUNTER + 1
	    return ID_IDCOUNTER
	end
end

-- Object to generate and manage the task Tree and gantt chart widget
do
	local IDMap = {}	-- Map from wxID to object (used to handle events)
	-- Metatable to define a node object's behaviour
	local nodeMeta = {__metatable = "Hidden, Do not change!"}
	local taskTreeINT = {__metatable = "Hidden, Do not change!"} 
	
	-- Function References
	local onScrollTree, onScrollGantt, labelClick, horSashAdjust, widgetResize, refreshTasks, refreshGantt, dispTask, dispGantt
	local cellClick, cellDblClick, ganttCellClick, ganttLabelClick, ganttCellDblClick, onRowResizeGantt, onRowResizeTree

	function newTreeGantt(parent)
		local taskTree = {}	-- Main object
		
		-- Main table to store the task tree that is on display
		-- This table keeps track of all active widgets and is keyed by the taskTree table that is returned to the application
		-- This is done to control access to the properties of the widget
		taskTreeINT[taskTree] = {Nodes = {}, Roots = {}, update = true, nodeCount = 0, actionQ = {}, Planning = nil, taskList = nil, Selected = {},ShowActual = nil, Bubble=nil, 
			taskTreeConfig = {		-- Table to define the configuration of the task Tree pane
								{ 
									Type = "Boolean",
									Code = "return taskNode.Task.Status == 'Done'",
									Title = " ",
									Width = 0		-- Width =0 means autofit the column
								},
								{
									Type = "String",
									Code = "return taskNode.Task.Estimate or '   '",
									Title = "E",
									Width = 30	-- Width of the column in pixels
								},
								{
									Type = "String",
									Code = [[	local spc = ""
												for i = 1,hierLevel do
													spc = spc.."    "
												end
												return spc..taskNode.Title]],
									--Code = "return taskNode.Title",
									Title = "Tasks",
									Width = -1		-- Width=-1 means whatever width is left after other columns and the space we have
								}	
							}
		}	-- taskTreeINT[taskTree] ends 
		
		-- Nodes contain all the nodes in the task tree table
		-- Roots contain all the root nodes in the task tree
		-- nodeCount = total number of nodes in the tree
		-- update if true would update the GUI for any changes made in the task tree
		-- actionQ is the list of actions pending, this que is created when update is false so that when update is made true all the pending actions are performed to bring the GUI up to date
		-- Planning - Table to indicate that the planning mode is ON for this GUI tree. Table contains type of planning (Normal schedule of Work Done) and also the requireSameClick flag.f
		-- taskList - list of tasks that are in planning in this GUI tree
		-- Selected - List of selected tasks
		-- ShowActual - flag to indicate showing work done instead of normal schedules
		-- Bubble - flag to turn ON/OFF schedule/work done bubbling to parents
		
		-- A task in Nodes or Roots will have the following attributes:
		-- Expanded = if has children then true means it is expanded in the GUI
		-- MakeVisible = Function to make sure the task is visible
		-- Task = Contains the link to the task data structure to the task
		-- Children = Contains the number of children on the tree for this node
		-- FirstChild = Contains the first child node
		-- LastChild = Contains the last child node
		-- Selected = Whether this node is selected. Allows multiple selections
		-- Title = Same as the task title unless there is no associated task
		-- Key = Same as TaskID unless no associated task
		-- ForeColor = Text color of the node
		-- BackColor = Background color of the node
		-- Prev = Previous Sibling
		-- Next = Next Sibling
		-- Parent = Parent
		-- Row = Row of the task in the task Grid (nil if task is not visible)
		-- taskTreeObj = main task tree GUI object to which this node belongs to
		-- Planning = Contains the planning mode schedule for the task if the task schedule planning is going on.
		
		-- Set task Tree internal as the metatable for exposed task tree empty table so we can catch all accesses to the task tree table and take actions appropriately
		setmetatable(taskTree, taskTreeINT)
		-- Metatable to access taskTreeINT for any missing keys
		setmetatable(taskTreeINT[taskTree],{__index=taskTreeINT})

		local oTree = taskTreeINT[taskTree]
		local ID = NewID()
		-- Create the horizontal split window
		oTree.horSplitWin = wx.wxSplitterWindow(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSP_3D, "Task Splitter")
		IDMap[ID] = taskTree
		oTree.horSplitWin:SetMinimumPaneSize(10)

		-- Create the Task Tree Grid control
		ID = NewID()		
		oTree.treeGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
						wx.wxDefaultSize, wx.wxALWAYS_SHOW_SB, "Task Tree Grid")
		IDMap[ID] = taskTree
	    oTree.treeGrid:CreateGrid(1,#oTree.taskTreeConfig)
		-- Setup the tree grid columns
	    for i = 1,#oTree.taskTreeConfig do
	    	if oTree.taskTreeConfig[i].Type == "Boolean" then
	    		oTree.treeGrid:SetColFormatBool(i-1)
	    	end
		    oTree.treeGrid:SetColLabelValue(i-1,oTree.taskTreeConfig[i].Title)
	    end
		
	    oTree.treeGrid:SetRowLabelSize(15)

	    oTree.treeGrid:EnableGridLines(false)
	
		-- Create the ganttGrid control
		ID = NewID()
		oTree.ganttGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxALWAYS_SHOW_SB, "Gantt Chart Grid")
		IDMap[ID] = taskTree
	    oTree.ganttGrid:CreateGrid(1,1)
	    oTree.ganttGrid:EnableGridLines(false)
	
		oTree.horSplitWin:SplitVertically(oTree.treeGrid, oTree.ganttGrid)
		oTree.horSplitWin:SetSashPosition(0.3*parent:GetSize():GetWidth())

		-- **************************EVENTS*******************************************
		-- SYNC THE SCROLLING OF THE TWO GRIDS	
		-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
		local f = onScrollTree(taskTree)
		--local f = onScTree
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_TOP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_BOTTOM, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEDOWN, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
	
		f = onScrollGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_TOP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_BOTTOM, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEUP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEDOWN, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
		
		-- Row Resize event
		f = onRowResizeTree(taskTree)
		oTree.treeGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		f = onRowResizeGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		
		-- The TreeGrid label click event
		--oTree.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,labelClick)
		oTree.treeGrid:Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,labelClick)
		
		-- TreeGrid left click on cell event
		oTree.treeGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,cellClick)

		-- Tree Cell double click event
		oTree.treeGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_DCLICK,cellDblClick)
		
		-- The GanttGrid label click event
		--oTree.ganttGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,ganttLabelClick)
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,ganttLabelClick)

		-- Gantt Grid Cell left click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,ganttCellClick)
		
		-- Gantt Cell double click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_DCLICK,ganttCellDblClick)
		
		-- Sash position changing event
		oTree.horSplitWin:Connect(wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED, horSashAdjust)

		-- Splitter resize event
		oTree.horSplitWin:Connect(wx.wxEVT_SIZE, widgetResize)
	
		return taskTree
	end
	
	function taskTreeINT.hideTasksTree(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.horSplitWin:Unsplit(oTree.treeGrid)
	end
	
	-- Function to return the iterator function to iterate over all taskTree Nodes 
	-- This the function to be used in a Generic for
	function taskTreeINT.tpairs(taskTree)
		return taskTreeINT.nextNode, taskTree, nil
	end
	
	-- Iterator for all nodes will give the effect of iterating over all the tasks in the task tree sequentially as if the whole tree is expanded
	function taskTreeINT.nextNode(taskTree,index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node has children
		if nodeMeta[oTree.Nodes[i]].FirstChild then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		end
		-- No children so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends
	end
	
	-- Function to return the iterator function to iterate over only visible taskTree Nodes
	function taskTreeINT.tvpairs(taskTree)
		-- Note if taskTreeINT.update = false then the results of this iterator may not be in sync with what is seen on the GUI
		return taskTreeINT.nextVisibleNode, taskTree, nil
	end
	
	-- This iterator function totally relies on the presence of Row and Expanded Attributes
	-- From the given index it goes down only if the Expanded attribute is true and only gives a visible node if its Row attribute is present
	function taskTreeINT.nextVisibleNode(taskTree, index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node is has children and is expanded
		if nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded and nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Row then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		elseif nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded then
			return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key)
		end
		-- No children visible so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next and nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Row then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			elseif nodeMeta[oTree.Nodes[i]].Next then
				return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key)
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends					
	end
	
	-- Function to associate events callback functions with the events in the widget
	function taskTreeINT.associateEventFunc(taskTree,funcTable)
		taskTreeINT[taskTree].cellClickCallBack = funcTable.cellClickCallBack or taskTreeINT[taskTree].cellClickCallBack
		taskTreeINT[taskTree].cellDblClickCallBack = funcTable.cellDblClickCallBack or taskTreeINT[taskTree].cellDblClickCallBack
		taskTreeINT[taskTree].ganttCellClickCallBack = funcTable.ganttCellClickCallBack or taskTreeINT[taskTree].ganttCellClickCallBack
		taskTreeINT[taskTree].rowLabelClickCallBack = funcTable.rowLabelClickCallBack or taskTreeINT[taskTree].rowLabelClickCallBack
		taskTreeINT[taskTree].ganttRowLabelClickCallBack = funcTable.ganttRowLabelClickCallBack or taskTreeINT[taskTree].ganttRowLabelClickCallBack
		taskTreeINT[taskTree].ganttCellDblClickCallBack = funcTable.ganttCellDblClickCallBack or taskTreeINT[taskTree].ganttCellDblClickCallBack
	end

	-- Function to change the date range in the ganttGrid portion of the widget
	function taskTreeINT.dateRangeChange(o,startDate,finDate)
		-- Clear the GanttGrid
		taskTreeINT[o].ganttGrid:DeleteRows(0,o.ganttGrid:GetNumberRows())
		taskTreeINT[o].ganttGrid:DeleteCols(0,o.ganttGrid:GetNumberCols())
		local currDate = startDate
		local count = 0
		local corner = taskTreeINT[o].ganttGrid:GetGridCornerLabelWindow()
		-- Add the Month and year in the corner
		local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		textLabel:SetLabel(startDate:Format("%b %Y"))
		--textLabel:SetBackgroundColour(wx.wxColour(0,0,0))
		sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
		--corner:SetBackgroundColour(wx.wxColour(0,0,0))	
		corner:SetSizer(sizer)
		corner:Layout()	
		while not currDate:IsLaterThan(finDate) do
			taskTreeINT[o].ganttGrid:InsertCols(count)
			-- set the column labels
			taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(toXMLDate(currDate:Format("%m/%d/%Y")),-2,-1)..
			    string.sub(getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))),1,1))
			taskTreeINT[o].ganttGrid:AutoSizeColumn(count)
			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
			count = count + 1
		end
		taskTreeINT[o].startDate = startDate:Subtract(wx.wxDateSpan(0,0,0,count))
		taskTreeINT[o].finDate = finDate		
		refreshGantt(o)
	end
	
	function taskTreeINT.layout(taskTree)
		local oTree = taskTreeINT[taskTree]
		local col
		local totWidth = 0
		for i = 1,#oTree.taskTreeConfig do
			if oTree.taskTreeConfig[i].Width==0 then
				-- Autofit the width
				oTree.treeGrid:AutoSizeColumn(i-1)
				totWidth = totWidth + oTree.treeGrid:GetColSize(i-1)
			elseif oTree.taskTreeConfig[i].Width==-1 then
				-- Remaining space to be set for this column
				col = i
			else
				-- Set the given width
				oTree.treeGrid:SetColSize(i-1,oTree.taskTreeConfig[i].Width)
				totWidth = totWidth + oTree.treeGrid:GetColSize(i-1)
		    end
		end	
		-- Set the -1 col width
	    oTree.treeGrid:SetColSize(col-1,oTree.horSplitWin:GetSashPosition()-totWidth-oTree.treeGrid:GetRowLabelSize(0)-wx.wxSystemSettings.GetMetric(wx.wxSYS_VSCROLL_X))
	end
	
	function taskTreeINT.disablePlanningMode(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.Planning = nil
		if oTree.taskList then
			-- Update all the tasks in the planning mode in the UI to remove the planning schedule
			for i = 1,#oTree.taskList do
				if oTree.taskList[i].Row then
					dispGantt(taskTree,oTree.taskList[i].Row,false,oTree.taskList[i])
				end
			end 
			oTree.taskList = nil
		end
	end
	
	-- Function to enable the planning mode
	-- Type = "NORMAL" - Planning for normal schedules
	-- Type = "WORKDONE" - Planning for the actual work done schedule
	-- if requireSameClick is true then to toggle the date in planning mode the cell has to be single clicked twice.
	function taskTreeINT.enablePlanningMode(taskTree, taskList, typ, requireSameClick)
		local oTree = taskTreeINT[taskTree]
		taskList = taskList or {}
		if oTree.ShowActual then
			typ = typ or "WORKDONE"
		else
			typ = typ or "NORMAL"
		end
		if typ ~= "NORMAL" and typ ~= "WORKDONE" then
			return nil,"enablePlanningMode: Planning type should either be 'NORMAL' or 'WORKDONE'."
		end
		oTree.Planning = {Type = typ, requireSameClick = requireSameClick}
		-- Work done planning is stored in PlanWorkDone table while schedule planning is stored in Planning table
		-- Both are separate since both may exist together.
		if not oTree.taskList then
			oTree.taskList = {}
			-- Check if there are tasks with Planning
			for i,v in taskTreeINT.tpairs(taskTree) do
				if oTree.Planning.Type == "NORMAL" then
					if v.Task and v.Task.Planning then
						oTree.taskList[#oTree.taskList + 1] = v
					end
				else
					if v.Task and v.Task.PlanWorkDone then
						oTree.taskList[#oTree.taskList + 1] = v
					end
				end
			end		-- Looping through all the nodes ends
		end
		-- Refresh the existing tasks in the taskList
		for j = 1,#oTree.taskList do
			if oTree.taskList[j].Row then
				dispGantt(taskTree,oTree.taskList[j].Row,false,oTree.taskList[j])
			end
		end
		for i = 1,#taskList do
			-- Check if the task is in the GUI
			if oTree.Nodes[taskList[i].TaskID] then
				-- Check whether the task already exist in the taskList
				local found = false
				for j = 1,#oTree.taskList do
					if oTree.taskList[j].Task == taskList[i] then
						found = true
						break
					end
				end
				if not found then
					oTree.taskList[#oTree.taskList + 1] = oTree.Nodes[taskList[i].TaskID]
					local dateList
					if typ == "NORMAL" then
						-- Copy over the latest schedule to the planning period
						dateList = getLatestScheduleDates(taskList[i])
					else
						-- Copy over the work done dates to the planning period
						dateList = getWorkDoneDates(taskList[i])
					end		-- if typ == "NORMAL" then ends
					if dateList then
						togglePlanningType(taskList[i],oTree.Planning.Type)
						for j=1,#dateList do
							togglePlanningDate(taskList[i],dateList[j],oTree.Planning.Type)
						end
					end
				end		-- if not found then ends
				oTree.Nodes[taskList[i].TaskID]:MakeVisible()
				if oTree.Nodes[taskList[i].TaskID].Row then
					-- Task Node is visible so refresh the gantt row
					dispGantt(taskTree,oTree.Nodes[taskList[i].TaskID].Row,false,oTree.Nodes[taskList[i].TaskID])
				end
			end		-- if oTree.Nodes[taskList[i].TaskID] then ends
		end		-- for i = 1,#taskList do ends
	end		-- local function enablePlanningMode(taskTree, taskList, typ)ends
	
	function taskTreeINT.getPlanningTasks(taskTree)
		local oTree = taskTreeINT[taskTree]
		if not oTree.Planning then
			return nil
		else
			local list = {}
			for i = 1,#oTree.taskList do
				list[#list + 1] = oTree.taskList[i].Task
			end
			return list
		end
	end
	
	function taskTreeINT.getSelectedTask(taskTree)
		local oTree = taskTreeINT[taskTree]
		return oTree.Selected
	end

	function nodeMeta.MakeVisible(node)
		local currNode = node
		if not nodeMeta[currNode] then
			return nil
		end
		while nodeMeta[currNode].Parent and not nodeMeta[currNode].Row do
			currNode = nodeMeta[currNode].Parent
			currNode.Expanded = true
		end
		return true
	end
	
	function nodeMeta.__index(tab,key)
		-- function to catch all accesses to a node object
		if key == "MakeVisible" then
			return nodeMeta.MakeVisible
		elseif key == "ID" then
			return nodeMeta	-- To identify node objects
		else
			return nodeMeta[tab][key]
		end
	end
	
	function nodeMeta.__newindex(tab,key,val)
		-- function to catch all setting commands to taskTree nodes
		
		-- define object references to bypass metamethod calls
		local oTree = taskTreeINT[nodeMeta[tab].taskTreeObj]
		local oNode = nodeMeta[tab]
		
		if key == "Expanded" then
			if oNode.Expanded and not val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row then
						-- Task is visible on the GUI
						-- Collapse this node in the GUI here
						local nextNode = nil
						local rows
						local currNode
						if oNode.Next then
							-- Number of rows to collapse
							rows = oNode.Next.Row - oNode.Row - 1
							-- Decrement the rows of subsequent tasks
							nextNode = oNode.Next
							while nextNode do
								nextNode.Row = nextNode.Row - rows 
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
							end
							nextNode = oNode.Next
						else
							-- Since there is no sibling the row collapsing will affect the ancestor which has siblings
							-- Find that ancestor:
							currNode = oNode.Parent
							while currNode and (not currNode.Next) do
								currNode = currNode.Parent
							end
							if currNode then
								nextNode = currNode.Next
								rows = nextNode.Row - oNode.Row - 1
								-- Decrement the rows of subsequent tasks
								while nextNode do
									nextNode.Row = nextNode.Row - rows 
									nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
								end
								nextNode = currNode.Next
							else
								rows = oTree.treeGrid:GetNumberRows() - oNode.Row
							end
						end
						-- Make nil the Row index of all children in the hierarchy of tab
						currNode = oTree.Nodes[taskTreeINT.nextNode(oNode.taskTreeObj,oNode.Key)]
						while currNode ~= nextNode do
							currNode.Row = nil
							currNode = oTree.Nodes[taskTreeINT.nextNode(currNode.taskTreeObj,currNode.Key)]
						end
						-- Adjust the row labels
						if nextNode then
							for i = nextNode.Row+rows,oTree.treeGrid:GetNumberRows() do
								oTree.treeGrid:SetRowLabelValue(i-rows-1,oTree.treeGrid:GetRowLabelValue(i-1))
								oTree.ganttGrid:SetRowLabelValue(i-rows-1,oTree.ganttGrid:GetRowLabelValue(i-1))
							end		
						end			
						-- Now delete all the rows
						oTree.treeGrid:DeleteRows(oNode.Row,rows)
						oTree.ganttGrid:DeleteRows(oNode.Row,rows)
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"+")
						if #oTree.Selected > 0 then
							local i = 0
							while i < #oTree.Selected do
								i = i + 1
								if not oTree.Selected[i].Row then
									-- The selected node is not visible anymore
									for j = i + 1,#oTree.Selected do
										oTree.Selected[j-1] = oTree.Selected[j]
									end
									oTree.Selected[#oTree.Selected] = nil
								end
							end
							if #oTree.Selected == 0 then
								oTree.Selected[1] = tab
								oTree.Selected.Latest = 1
								tab.Selected = true
								if oTree.cellClickCallBack then
									oTree.cellClickCallBack(oNode.Task)
								end
							end
						end
					end
					-- Expanded was true and now making it false
					oNode.Expanded = nil
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = nil"
				end		-- if oTree.update then ends
			elseif not oNode.Expanded and val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row and oNode.Children > 0 then
						-- Task is visible on the GUI
						-- Expand the node in the GUI here
						-- Number of rows to insert
						local rows = oNode.Children
						-- Increment the rows of subsequent tasks
						local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(oNode.taskTreeObj,oNode.Key)]
						while nextNode do
							nextNode.Row = nextNode.Row + rows 
							nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
						end
						-- Now insert the child rows here
						-- Find the hierarchy level
						local hierLevel = -1
						nextNode = oNode.FirstChild
						while nextNode do
							hierLevel = hierLevel + 1
							nextNode = nextNode.Parent
						end			
						nextNode = oNode.FirstChild
						local currRow = oNode.Row
						while nextNode do
							currRow = currRow + 1
							nextNode.Row = currRow
							dispTask(oNode.taskTreeObj,nextNode.Row,true,nextNode,hierLevel)
							dispGantt(oNode.taskTreeObj,nextNode.Row,true,nextNode)
							nextNode = nextNode.Next
						end
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"-")
						-- Expanded was false and now making it true
						oNode.Expanded = true
						-- Now check if any of the exposed children have expanded true
						nextNode = oNode.FirstChild
						local toExpand = {}
						while nextNode do
							if nextNode.Expanded then
								nodeMeta[nextNode].Expanded = nil
								toExpand[#toExpand + 1] = nextNode
							end
							nextNode = nextNode.Next
						end
						-- Perform expansion of child nodes if any
						for i = 1,#toExpand do
							toExpand[i].Expanded = true
						end
					else
						-- Expanded was false and now making it true
						oNode.Expanded = true
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = true"
				end		-- if oTree.update then ends
			end		-- if oNode.Expanded and not val then ends
		elseif key == "Selected" then
			if not val then
				oNode.Selected = nil
				-- Unselect this node in the GUI
				oTree.Selected = {}
				oTree.treeGrid:SetGridCursor(0,0)
			else
				oNode.Selected = true
				-- Select the node in the GUI here
				oTree.Selected = {tab,Latest = 1}
				oTree.treeGrid:SetGridCursor(oNode.Row-1,0)
			end	
		elseif key == "ForeColor" or key == "BackColor" then
			if type(val) == "table" and val.Red and type(val.Red) == "number" and val.Green and type(val.Green) == "number" and
			  val.Blue and type(val.Blue) == "number" then
				if oTree.update then
					oNode[key] = val
					if oNode.Row then
						-- Calculate the hierLevel
						local hierLevel = 0
						local currNode = tab
						while nodeMeta[currNode].Parent do
							hierLevel = hierLevel + 1
							currNode = nodeMeta[currNode].Parent
						end
	
						dispTask(nodeMeta[tab].taskTreeObj,nodeMeta[tab].Row,false,tab,hierLevel)
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]]."..key.."={Red="..val.Red..",Green="..val.Green..",Blue="..val.Blue.."}"
					oTree.actionQ[#oTree.actionQ + 1] = "if ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Row then local hierLevel = 0 local currNode = ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."] while nodeMeta[currNode].Parent do hierLevel = hierLevel + 1 currNode = nodeMeta[currNode].Parent end dispTask(tab,nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."],hierLevel) end"
				end		-- if oTree.update then ends
			end					
		else
			oNode[key] = val
		end		-- if key == ?? ends here
	end		-- function nodeMeta.__newindex(tab,key,val) ends

	function taskTreeINT.__index(tab,key)
		-- function to catch all accesses to taskTree
		return taskTreeINT[tab][key]
	end
	
	function taskTreeINT.__newindex(tab,key,val)
		-- function to catch all setting commands to taskTree
		-- object reference to bypass metamethod
		local oTree = taskTreeINT[tab]
		if key == "update" then
			if oTree.update and not val then
				-- Update was true and now making it false
				oTree.update = false
			elseif not oTree.update and val then
				oTree.update = true
				-- Now do the actionQ
				local env
				if getfenv then
					env = getfenv(1)
				else
					env = {}
					setmetatable(env,{__index=_ENV})
				end
				-- Write the up Values
				-- These values need to be passed to the environment since they are up values and the loadstring function does not have them
				-- So we just pass the values tot he environment and then remove them after executing the string
				local passToEnv = {["taskTreeINT"]=taskTreeINT,["tab"]=tab,["nodeMeta"]=nodeMeta,["dispTask"]=dispTask,["dispGantt"]=dispGantt}
				for k,v in pairs(passToEnv) do
					if env[k] then
						passToEnv[k] = nil
					else
						env[k] = v
					end
				end
				--print(taskTreeINT)
				for i = 1,#oTree.actionQ do
					local f 
					if loadstring then
						f = loadstring(oTree.actionQ[i])
						setfenv(f,env)
					else
						f = load(oTree.actionQ[i],nil,"bt",env)
					end
					f()
				end
--				-- Remove from env
--				for k,v in pairs(passToEnv) do
--					env[k] = nil
--				end
				-- Clear all pending actions
				oTree.actionQ = {}
			end
		elseif key == "Planning" then
			-- do nothing user cannot modify this
		elseif key == "taskList" then
			-- do nothing user cannot modify this
		elseif key == "Selected" then
			-- do nothing user cannot modify this
		elseif key == "UpdateKeys" then
			-- do nothing user cannot modify this
		elseif key == "SwapUpdateKeys" then
			-- do nothing user cannot modify this
		elseif key == "ShowActual" then
			if oTree.Planning then
				if val then
					oTree.Planning.Type = "WORKDONE"
				else
					oTree.Planning.Type = "NORMAL"
				end
			end
			oTree[key] = val
		elseif key=="taskTreeConfig" then
			-- Validate the passed table
			if not type(val)=="table" then
				return
			elseif #val ==0 then
				return
			end
			local count = 0
			for i = 1,#val do
				if not type(val[i])=="table" or not val[i].Type or not type(val[i].Type)=="string" or not (val[i].Type=="Boolean" or val[i].Type=="String")
				  or not val[i].Width or not type(val[i].Width)=="number" or not val[i].Code or not type(val[i].Code)=="string" or not val[i].Title or not type(val[i].Title)=="string" then
					return
				end
				if val[i].Width == -1 then
					count = count + 1
				end
			end
			if count > 1 then
				return		-- Only 1 Width=-1 allowed
			end
			--The passed table is valid
			if oTree.update then
				oTree[key] = val
				-- Now refresh the tree grid
				local cols = oTree.treeGrid:GetNumberCols()
				oTree.treeGrid:DeleteCols(0,cols)
				-- Generate the new columns
			    oTree.treeGrid:AppendCols(#oTree.taskTreeConfig)
			    for i = 1,#oTree.taskTreeConfig do
			    	if oTree.taskTreeConfig[i].Type == "Boolean" then
			    		oTree.treeGrid:SetColFormatBool(i-1)
			    	end
				    oTree.treeGrid:SetColLabelValue(i-1,oTree.taskTreeConfig[i].Title)
			    end
			    oTree.treeGrid:SetRowLabelSize(15)
			    oTree.treeGrid:EnableGridLines(false)
			    -- Layout the tree grid columns
				taskTreeINT.layout(tab)
				refreshTasks(tab)
			else
				-- Add to the actionQ
				oTree.actionQ[#oTree.actionQ + 1] = "tab.taskTreeConfig = "..tableToString(val)
			end	    
		else
			oTree[key] = val
		end
	end
	
	function taskTreeINT.Clear(tab)
		taskTreeINT[tab].Nodes = {}
		taskTreeINT[tab].nodeCount = 0
		taskTreeINT[tab].Roots = {}
		taskTreeINT[tab].actionQ = {}
		taskTreeINT[tab].treeGrid:DeleteRows(0,taskTreeINT[tab].treeGrid:GetNumberRows())
		taskTreeINT[tab].ganttGrid:DeleteRows(0,taskTreeINT[tab].ganttGrid:GetNumberRows())
	end

	local function postOnScrollTree(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
		end
	end	
	
	local function refreshTasksFunc(taskTree)
		local oTree = taskTreeINT[taskTree]
		-- Erase the previous data
		oTree.treeGrid:DeleteRows(0,oTree.treeGrid:GetNumberRows())
		local rowPtr = 0
		for i,v in taskTreeINT.tvpairs(taskTree) do
			-- Calculate the hierLevel
			local hierLevel = 0
			local currNode = v
			while nodeMeta[currNode].Parent do
				hierLevel = hierLevel + 1
				currNode = nodeMeta[currNode].Parent
			end
			dispTask(taskTree,rowPtr+1,true,v, hierLevel)
			rowPtr = rowPtr + 1
		end		-- Looping through all the nodes ends	
		-- Sync the Scroll bars
		oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))
	end
	
	refreshTasks = refreshTasksFunc

	local function refreshGanttFunc(taskTree)
		-- Erase the previous data
		taskTreeINT[taskTree].ganttGrid:DeleteRows(0,taskTreeINT[taskTree].ganttGrid:GetNumberRows())
		local rowPtr = 0
		for i,v in taskTreeINT.tvpairs(taskTree) do
			dispGantt(taskTree,rowPtr+1,true,v)
			rowPtr = rowPtr + 1
		end		-- Looping through all the nodes ends	
		-- Sync the Scroll bars
		postOnScrollTree(taskTree)()
	end
	
	refreshGantt = refreshGanttFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispTaskFunc(taskTree,row, createRow, taskNode, hierLevel)
		if (createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].treeGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].treeGrid:GetNumberRows()-1,row,-1 do
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(i,taskTreeINT[taskTree].treeGrid:GetRowLabelValue(i-1))
			end
		end
		-- Set the values
		for i = 1,#taskTreeINT[taskTree].taskTreeConfig do
			if taskTreeINT[taskTree].taskTreeConfig[i].Type == "Boolean" then
				local env 
				if getfenv then
					env = getfenv(1)
				else
					env = {}
					setmetatable(env,{__index=_ENV})
				end
				env.taskNode = taskNode
				env.hierLevel = hierLevel
				local f 
				if loadstring then
					f = loadstring(taskTreeINT[taskTree].taskTreeConfig[i].Code)
					setfenv(f,env)
				else
					f = load(taskTreeINT[taskTree].taskTreeConfig[i].Code,nil,"bt",env)
				end
				local err,ret
				err,ret = pcall(f)
				if err then
					if ret then
						taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,i-1,"1")
					else
						taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,i-1,"0")
					end
					-- Set the back ground color
					if taskNode.BackColor then
						taskTreeINT[taskTree].treeGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
					end
					if taskNode.ForeColor then
						taskTreeINT[taskTree].treeGrid:SetCellTextColour(row-1,i-1,wx.wxColour(taskNode.ForeColor.Red,taskNode.ForeColor.Green,taskNode.ForeColor.Blue))
					end
				end
			else
				local env 
				if getfenv then
					env = getfenv(1)
				else
					env = {}
					setmetatable(env,{__index=_ENV})
				end
				env.taskNode = taskNode
				env.hierLevel = hierLevel
				local f 
				if loadstring then
					f = loadstring(taskTreeINT[taskTree].taskTreeConfig[i].Code)
					setfenv(f,env)
				else
					f = load(taskTreeINT[taskTree].taskTreeConfig[i].Code,nil,"bt",env)
				end
				local err,ret
				err,ret = pcall(f)
				if err then
					taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,i-1,ret or " ")
					taskTreeINT[taskTree].treeGrid:SetCellAlignment(row-1,i-1,wx.wxALIGN_LEFT, wx.wxALIGN_CENTRE)
					-- Set the back ground color
					if taskNode.BackColor then
						taskTreeINT[taskTree].treeGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
					end
					if taskNode.ForeColor then
						taskTreeINT[taskTree].treeGrid:SetCellTextColour(row-1,i-1,wx.wxColour(taskNode.ForeColor.Red,taskNode.ForeColor.Green,taskNode.ForeColor.Blue))
					end
				end				
			end
			taskTreeINT[taskTree].treeGrid:SetReadOnly(row-1,i-1)
		end		-- for i = 1,#taskTreeINT[taskTree].taskTreeConfig do ends
		if taskNode.Children > 0 then
			if taskNode.Expanded then
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"-")
			else
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"+")
			end
		else
			taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1," ")
		end
		taskTreeINT[taskTree].treeGrid:ForceRefresh()
	end
	
	dispTask = dispTaskFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispGanttFunc(taskTree,row,createRow,taskNode)
		if (createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].ganttGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].ganttGrid:GetNumberRows(),row,-1 do
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(i,taskTreeINT[taskTree].ganttGrid:GetRowLabelValue(i-1))
			end
		end
		-- Now update the ganttGrid to include the schedule
		local startDay = toXMLDate(taskTreeINT[taskTree].startDate:Format("%m/%d/%Y"))
		local finDay = toXMLDate(taskTreeINT[taskTree].finDate:Format("%m/%d/%Y"))
		local days = taskTreeINT[taskTree].ganttGrid:GetNumberCols()
		if not taskNode.Task then
			-- No task associated with the node so color the cells to show no schedule
			taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
			local currDate = XMLDate2wxDateTime(startDay)
			for i = 1,days do
				--print(currDate:Format("%m/%d/%Y"),getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))))
				if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
					local newColor = {Red=GUI.noScheduleColor.Red - GUI.sunDayOffset.Red,Green=GUI.noScheduleColor.Green - GUI.sunDayOffset.Green,
					Blue=GUI.noScheduleColor.Blue-GUI.sunDayOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
				else
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
						GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
				end
				taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
			end
		else
			-- Task exists so create the schedule
			--Get the datelist
			-- Check if planning mode for this task
			local planning = nil
			if taskTreeINT[taskTree].Planning then
				for i = 1,#taskTreeINT[taskTree].taskList do
					if taskTreeINT[taskTree].taskList[i] == taskNode then
						-- This is a planning mode task
						planning = true
						break
					end
				end
			end
			local dateList
			if taskTreeINT[taskTree].ShowActual then
				dateList = getWorkDates(taskNode.Task,taskTreeINT[taskTree].Bubble, planning)
			else
				dateList = getDates(taskNode.Task,taskTreeINT[taskTree].Bubble, planning)
			end
			if not dateList then
				-- No task associated with the node or no schedule so color the cells to show no schedule
				if planning then
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"(P)X")
				else
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
				end
				local currDate = XMLDate2wxDateTime(startDay)
				for i = 1,days do
					if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=GUI.noScheduleColor.Red - GUI.sunDayOffset.Red,Green=GUI.noScheduleColor.Green - GUI.sunDayOffset.Green,
						Blue=GUI.noScheduleColor.Blue-GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
							GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end
			else
				-- Some dates are scheduled for the task
				local map
				if planning then
					map = {Estimate="(P)E",Commit = "(P)C", Revs = "(P)R", Actual = "(P)A"}
				else
					map = {Estimate="E",Commit = "C", Revs = "R", Actual = "A"}
				end
				-- Erase the previous schedule on the row
				local currDate = XMLDate2wxDateTime(startDay)
				for i=1,days do
					if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=GUI.emptyDayColor.Red - GUI.sunDayOffset.Red,Green=GUI.emptyDayColor.Green - GUI.sunDayOffset.Green,
						Blue=GUI.emptyDayColor.Blue-GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.emptyDayColor.Red,
							GUI.emptyDayColor.Green,GUI.emptyDayColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end		
				local before,after
				for i=1,#dateList do
					currDate = XMLDate2wxDateTime(dateList[i].Date)
					if dateList[i].Date>=startDay and dateList[i].Date<=finDay then
						-- This date is in range find the column which needs to be highlighted
						local col = 0					
						local stepDate = XMLDate2wxDateTime(startDay)
						while not stepDate:IsSameDate(currDate) do
							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
							col = col + 1
						end
						--taskTreeINT[taskTree].startDate:Subtract(wx.wxDateSpan(0,0,0,col))
						if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
							local newColor = {Red=dateList[i].BackColor.Red - GUI.sunDayOffset.Red,
							  Green=dateList[i].BackColor.Green - GUI.sunDayOffset.Green,
							  Blue=dateList[i].BackColor.Blue-GUI.sunDayOffset.Blue}
							if newColor.Red < 0 then newColor.Red = 0 end
							if newColor.Green < 0 then newColor.Green = 0 end
							if newColor.Blue < 0 then newColor.Blue = 0 end
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
						else
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(dateList[i].BackColor.Red,
								dateList[i].BackColor.Green,dateList[i].BackColor.Blue))
						end
						taskTreeINT[taskTree].ganttGrid:SetCellTextColour(row-1,col,wx.wxColour(dateList[i].ForeColor.Red,dateList[i].ForeColor.Green,dateList[i].ForeColor.Blue))
						taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,col,dateList[i].Text)
						taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,col)
					else
						if dateList[i].Date<startDay then
							before = true
						end
						if dateList[i].Date>finDay then
							after = true
						end
					end		-- if dateList[i]>=startDay and dateList[i]<=finDay then ends
				end		-- for i=1,#dateList do ends
				local str = ""
				if before then
					str = "<"
				end
				if after then
					str = str..">"
				end
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,map[dateList.typeSchedule]..tostring(dateList.index)..str)
			end		-- if not dateList then ends
      -- Highlight the due date
      if taskNode.Task.Due then
        -- This date is in range find the column which needs to be highlighted
        local col = 0					
        local dueDate = XMLDate2wxDateTime(taskNode.Task.Due)
        local stepDate = XMLDate2wxDateTime(startDay)
        while not stepDate:IsSameDate(dueDate) do
          stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
          col = col + 1
        end
      taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(GUI.dueColor.Red,
								GUI.dueColor.Green,GUI.dueColor.Blue))
      end
		end	
		taskTreeINT[taskTree].ganttGrid:ForceRefresh()
	end		-- local function dispGanttFunc(taskTree,row,createRow,taskNode) ends
	
	dispGantt = dispGanttFunc
	
	-- Updates the keys of a node from the underlying tasks
	function taskTreeINT.UpdateKeys(taskTree,node,noRecurse)
		if node.ID ~= nodeMeta then
			error("Need valid node objects to UpdateKeys.",2)
		end
		if not nodeMeta[node].Task then
			error("Need a node with an associated task to update the key.",2)
		end
		local currNode = node
		local oTree = taskTreeINT[taskTree]
		oTree.Nodes[nodeMeta[currNode].Key]  = nil
		nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
		oTree.Nodes[nodeMeta[currNode].Key] = currNode
		if noRecurse then
			return
		end
		if nodeMeta[currNode].FirstChild then
			currNode = nodeMeta[currNode].FirstChild
			while currNode ~= node do
				oTree.Nodes[nodeMeta[currNode].Key]  = nil
				nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
				oTree.Nodes[nodeMeta[currNode].Key] = currNode
				if nodeMeta[currNode].FirstChild then
					currNode = nodeMeta[currNode].FirstChild
				elseif nodeMeta[currNode].Next then
					currNode = nodeMeta[currNode].Next
				else
					while currNode ~= node and not nodeMeta[currNode].Next do
						currNode = nodeMeta[currNode].Parent
					end
					if currNode == node then 
						break
					end
					currNode = nodeMeta[currNode].Next
				end		-- if nodeMeta[currNode].FirstChild then ends here
			end		-- while currNode ~= node do ends
		end		-- if nodeMeta[currNode].FirstChild then ends		
	end
	
	-- Function to swap the keys of the given 2 node hierarchies. They keys are still taken from the taskIDs for task swap
	-- The function just assumes that there would eb key swapping happenning so uses a 3rd storage element to make the swap
	-- happen and make data consistent in the Nodes table (Where each node is accessible from its key)
	function taskTreeINT.SwapUpdateKeys(taskTree,node1,node2)
		if getmetatable(node1)~=nodeMeta or getmetatable(node2)~=nodeMeta then
			return nil,"Need valid node objects to SwapKeys."
		end
		if (not nodeMeta[node1].Task and nodeMeta[node2].Task) or (not nodeMeta[node2].Task and nodeMeta[node1].Task) then
			return nil,"Cannot Swap Keys between a Spore and task."
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if these are spore nodes
		if nodeMeta[node1].Key:sub(1,#Globals.ROOTKEY)==Globals.ROOTKEY then
			-- ################################################################################
			-- QUESTIONALBLE SINCE SPORE KEYS ARE BASED ON THEIR FILE NAMES!
			-- ################################################################################
			-- These are spores
			-- Just swap the spore keys
			nodeMeta[node1].Key, nodeMeta[node2].Key = nodeMeta[node2].Key, nodeMeta[node1].Key
			oTree.Nodes[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node2].Key] = node2
		else
			-- Move the node1 hierarchy out of Nodes table
			local node1Hier = {}
			local currNode = node1
			node1Hier[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node1].Key]  = nil
			if nodeMeta[currNode].FirstChild then
				currNode = nodeMeta[currNode].FirstChild
				while currNode ~= node1 do
					node1Hier[nodeMeta[currNode].Key] = currNode
					oTree.Nodes[nodeMeta[currNode].Key]  = nil
					if nodeMeta[currNode].FirstChild then
						currNode = nodeMeta[currNode].FirstChild
					elseif nodeMeta[currNode].Next then
						currNode = nodeMeta[currNode].Next
					else
						while currNode ~= node1 and not nodeMeta[currNode].Next do
							currNode = nodeMeta[currNode].Parent
						end
						if currNode == node1 then 
							break
						end
					end		-- if nodeMeta[currNode].FirstChild then ends here
				end		-- while currNode ~= node1 do ends
			end		-- if nodeMeta[currNode].FirstChild then ends
			-- Now convert node2 hierarchy to the proper Keys
			taskTreeINT.UpdateKeys(taskTree,node2)
			-- Now add the node1 nodes back with the correct keys
			for k,v in pairs(node1Hier) do
				nodeMeta[v].Key = nodeMeta[v].Task.TaskID
				oTree.Nodes[nodeMeta[v].Key] = v
			end
		end		-- if not nodeMeta[node1].Task then ends
	end

	-- Refreshes a node with the key same as the given task's TaskID
	-- This is a total refresh of the task name and also the schedule
	function taskTreeINT.RefreshNode(taskTree,task)
		return taskTreeINT.UpdateNode(taskTree,task)
	end
	
	function taskTreeINT.UpdateNode(taskTree,task)
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[task.TaskID]
		
		if not node then
			return nil
		end
		
		nodeMeta[node].Task = task
		nodeMeta[node].Title = task.Title
		nodeMeta[node].ForeColor, nodeMeta[node].BackColor = GUI.getNodeColor(node)
		
		if nodeMeta[node].Row then
			-- Calculate the hierLevel
			local hierLevel = 0
			local currNode = node
			while nodeMeta[currNode].Parent do
				hierLevel = hierLevel + 1
				currNode = nodeMeta[currNode].Parent
			end
	
			if oTree.update then
				dispTask(taskTree,nodeMeta[node].Row,false,node,hierLevel)
				dispGantt(taskTree,nodeMeta[node].Row,false,node)
				if #oTree.Selected > 0 then
					oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
				end
			else
				-- Add to actionQ
				oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."],"..tostring(hierLevel)..")"
				oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."])"				
				oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
			end
		end		-- if nodeMeta[node].Row then ends
	end
	
	function taskTreeINT.DeleteTree(taskTree,Key)
		if Key == Globals.ROOTKEY then
			return nil, "DeleteTree: Function cannot be used to delete a Root node,"
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		if not node then
			-- Already deleted
			return
		end
		local parent = nodeMeta[node].Parent
		local nodesToDel = {node}
		local rowsToDel = {nodeMeta[node].Row}
		-- Make list of nodes and rows to delete
		local k, nextNode = taskTree:nextNode(Key)
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if not inHier then
				break	-- once a hierarchy is exited there cannot be another following node in the hierarchy
			end
			-- Add to the delete list
			nodesToDel[#nodesToDel + 1] = nextNode
			rowsToDel[#rowsToDel + 1] = nodeMeta[nextNode].Row
			k, nextNode = taskTree:nextNode(k)
		end		-- while nextNode do ends
		-- Update the links
		if nodeMeta[node].Prev then
			nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
		end
		if nodeMeta[node].Next then
			nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
		end
		-- Parent links
		nodeMeta[parent].Children = nodeMeta[parent].Children - 1
		if not nodeMeta[node].Prev then
			-- This was the first child
			nodeMeta[parent].FirstChild = nodeMeta[node].Next
		end
		if not nodeMeta[node].Next then
			-- This was the last child
			nodeMeta[parent].LastChild = nodeMeta[node].Prev
		end
		
		if nextNode then
			-- Adjust the row labels
			if not nodeMeta[nextNode].Row then
				k,nextNode = taskTree:nextVisibleNode(k)
			end
			local nextStartNode = nextNode
			while nextNode do
				oTree.treeGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.treeGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				oTree.ganttGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.ganttGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				-- Update the node Row
				nodeMeta[nextNode].Row = nodeMeta[nextNode].Row-#rowsToDel
				k,nextNode = taskTree:nextVisibleNode(k)
			end
		end	
		-- Update the parent row label
		if nodeMeta[parent].Children == 0 then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[nodeMeta[node].Parent].Row-1,"")
			nodeMeta[parent].Expanded = false
		end
		-- Now delete everything
		-- Delete the nodes
		for i = 1,#nodesToDel do
			oTree.Nodes[nodeMeta[nodesToDel[i]].Key] = nil
			nodeMeta[nodesToDel[i]] = nil
		end
		oTree.nodeCount = oTree.nodeCount - #nodesToDel
		
		-- Delete the rows
		for i = 1,#rowsToDel do
			oTree.treeGrid:DeleteRows(rowsToDel[i]-1)
			oTree.ganttGrid:DeleteRows(rowsToDel[i]-1)
			-- Adjust the row numbers to account for deleted row	
			for j = i + 1,#rowsToDel do	
				if rowsToDel[j] > rowsToDel[i] then
					rowsToDel[j] = rowsToDel[j] - 1
				end
			end
		end
		
		-- Remove the nodes from the Selected list
		if #oTree.Selected > 0 then
			local i = 1
			while i <= #oTree.Selected do
				for j = 1,#nodesToDel do
					if oTree.Selected[i] == nodesToDel[j] then
						for k = i+1,#oTree.Selected-1 do
							oTree.Selected[k-1] = oTree.Selected[k]
						end
						oTree.Selected[#oTree.Selected] = nil
						i = i - 1 		-- Since new node at i now
						break
					end
				end
				i = i + 1
			end
			if #oTree.Selected == 0 then
				oTree.Selected[1] = parent
				oTree.Selected.Latest = 1
				parent.Selected = true
				if oTree.cellClickCallBack then
					oTree.cellClickCallBack(parent.Task)
				end
			else
				if oTree.Selected.Latest > #oTree.Selected then
					oTree.Selected.Lates = #oTree.Selected
				end
			end
		end		-- if #oTree.Selected > 0 then ends
		-- Remove from planning taskList 
		if oTree.taskList then
			local i = 1
			while i <= #oTree.taskList do
				for j = 1,#nodesToDel do
					if oTree.Selected[i] == nodesToDel[j] then
						for k = i + 1, #oTree.taskList - 1 do
							oTree.taskList[k-1] = oTree.taskList[k]
						end
						oTree.taskList[#oTree.taskList] = nil
						i = i - 1		-- Since new node at i now
						break
					end
				end
				i = i + 1
			end
			if oTree.taskList == 0 then
				oTree.taskList = nil
			end
		end
	end		-- function taskTreeINT.DeleteTree(taskTree,Key) ends
	
	-- Function to just delete a node
	-- It also adjusts the children if any to move up in the hierarchy 1 level so that the GUI remains a valid tree
	function taskTreeINT.DeleteSubUpdate(taskTree,Key)
		if Key:sub(1,#Globals.ROOTKEY) == Globals.ROOTKEY then
			error("DeleteSubUpdate: Function cannot be used to delete a spore or Root node.",2)
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		local parent = nodeMeta[node].Parent
		-- Expand the node first
		node.Expanded = true
		-- Update the row numbers of all subsequent tasks first
		local key,nextNode = taskTree:nextVisibleNode(Key)
		local nextV = nextNode
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if inHier then
				-- Update the display of the task
				-- Calculate the hierLevel
				local hierLevel = -1
				local cN = nextNode
				while nodeMeta[cN].Parent do
					hierLevel = hierLevel + 1
					cN = nodeMeta[cN].Parent
				end
		
				if oTree.update then
					dispTask(taskTree,nodeMeta[nextNode].Row,false,nextNode,hierLevel)
					dispGantt(taskTree,nodeMeta[nextNode].Row,false,nextNode)
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'],"..tostring(hierLevel)..")"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
				end
			end
			-- Update the row now since this will be the new row after the node row is deleted
			nodeMeta[nextNode].Row = nodeMeta[nextNode].Row - 1
			key, nextNode = taskTree:nextVisibleNode(key)
		end		-- while nextNode do ends
		
		-- Update the parent of all the immediate children and the hierLevel of all children hierarchy
		local currNode = nodeMeta[node].FirstChild
		while currNode do		
			-- Update the parent
			nodeMeta[currNode].Parent = parent
			currNode = nodeMeta[currNode].Next
		end

		-- Update the Parent links for the node
		nodeMeta[parent].Children = nodeMeta[parent].Children + nodeMeta[node].Children - 1
		if not nodeMeta[node].Prev then
			-- The FirstChild is changing
			if nodeMeta[node].FirstChild then
				nodeMeta[parent].FirstChild = nodeMeta[node].FirstChild
			else
				nodeMeta[parent].FirstChild = nodeMeta[node].Next
			end
		end
		if not nodeMeta[node].Next then
			-- The LastChild is changing
			if nodeMeta[node].LastChild then
				nodeMeta[parent].LastChild = nodeMeta[node].LastChild
			else
				nodeMeta[parent].LastChild = nodeMeta[node].Prev
			end
		end

		-- Update the sibling links of the node
		if nodeMeta[node].Prev then
			if nodeMeta[node].FirstChild then
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].FirstChild
				nodeMeta[nodeMeta[node].FirstChild].Prev = nodeMeta[node].Prev
			else
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				if nodeMeta[node].Next then
					nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				end
			end
		end
		if nodeMeta[node].Next then
			if nodeMeta[node].LastChild then
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].LastChild
				nodeMeta[nodeMeta[node].LastChild].Next = nodeMeta[node].Next
			else
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				if nodeMeta[node].Prev then
					nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				end
			end
		end


		-- Adjust the row labels
		for i = nodeMeta[node].Row+1,oTree.treeGrid:GetNumberRows() do
			oTree.treeGrid:SetRowLabelValue(i-2,oTree.treeGrid:GetRowLabelValue(i-1))
			oTree.ganttGrid:SetRowLabelValue(i-2,oTree.ganttGrid:GetRowLabelValue(i-1))
		end		
		-- Finally delete the node row
		oTree.treeGrid:DeleteRows(nodeMeta[node].Row-1)
		oTree.ganttGrid:DeleteRows(nodeMeta[node].Row-1)
		-- Update the - sign on the parent
		if not nodeMeta[parent].FirstChild then
			-- Nothing left under the parent
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"")
		elseif not nodeMeta[nodeMeta[parent].FirstChild].Row then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
			nodeMeta[parent].Expanded = nil
		end
		-- Remove the node from the Selected list
		if #oTree.Selected > 0 then
			local index
			for i = 1,#oTree.Selected do
				if oTree.Selected[i] == node then
					index = i
					break
				end
			end
			if index then
				for i = index+1,#oTree.Selected-1 do
					oTree.Selected[i-1] = oTree.Selected[i]
				end
				oTree.Selected[#oTree.Selected] = nil
				if #oTree.Selected == 0 then
					if not nextV then
						nextV = parent
					end
					oTree.Selected[1] = nextV
					oTree.Selected.Latest = 1
					nextV.Selected = true
					if oTree.cellClickCallBack then
						oTree.cellClickCallBack(nextV.Task)
					end
				else
					if oTree.Selected.Latest > #oTree.Selected then
						oTree.Selected.Latest = #oTree.Selected
					end
				end
			end
		end
		-- Remove the node from the taskList if present
		if oTree.taskList then
			for i=1,#oTree.taskList do
				if oTree.taskList[i] == node then
					for k = i + 1, #oTree.taskList - 1 do
						oTree.taskList[k-1] = oTree.taskList[k]
					end
					oTree.taskList[#oTree.taskList] = nil
					break
				end
			end
		end		-- if oTree.taskList then ends
		-- Remove references to the node
		oTree.Nodes[nodeMeta[node].Key] = nil
		nodeMeta[node] = nil
		oTree.nodeCount = oTree.nodeCount - 1		
	end		-- function taskTreeINT.DeleteSubUpdate(taskTree,task) ends
	
	function taskTreeINT.AddNode(taskTree,nodeInfo)
		-- Add the node to the GUI task tree
		-- nodeInfo.Relative = relative of this new node (should be a task ID) (Can be nil - together with relation means root node)
		-- nodeInfo.Relation = relation of this new node to the Relative. This can be Globals.CHILD, Globals.NEXT_SIBLING, Globals.PREV_SIBLING (Can be nil)
		-- nodeInfo.Key = key by which this node is uniquely identified in the tree
		-- nodeInfo.Text = text to be visible to represent the node in the GUI
		-- nodeInfo.Task = Task to be associated with this node (Can be nil)
		
		local oTree = taskTreeINT[taskTree]
		-- First make sure the key is unique
		if oTree.Nodes[nodeInfo.Key] then
			-- Key already exists
			wx.wxMessageBox("Trying to add a duplicate Key ("..nodeInfo.Key..") to the task Tree.", "Error!", 
		                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
			return nil
		end
		-- Check if Relative exist
		if nodeInfo.Relative then
			if not oTree.Nodes[nodeInfo.Relative] then
				-- Relative specified but does not exist
				wx.wxMessageBox("Specified relative does not exist ("..nodeInfo.Relative..") in the task Tree.", "Error!", 
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return nil
			end
			-- Since relative is specified relation should be specified
			if not nodeInfo.Relation then
				-- Relative specified but Relation not specified
				wx.wxMessageBox("No relation specified for task (".. nodeInfo.Text..").", "Error!", 
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return nil
			end
		end
		-- Check if Relation if correct
		if nodeInfo.Relation then
			if nodeInfo.Relation ~= Globals.CHILD and nodeInfo.Relation ~= Globals.NEXT_SIBLING and nodeInfo.Relation ~= Globals.PREV_SIBLING then
				-- Relation specified incorrectly 
				wx.wxMessageBox("Specified relation is not correct ("..nodeInfo.Relation.."). Allowed values are 'Child', 'Next Sibling', 'Prev Sibling'.", "Relation Error",
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return nil
			end
		end
		
		-- Now add the node
		if not nodeInfo.Relative then
			-- This is a root node
			oTree.Roots[#oTree.Roots + 1] = {}
			nodeMeta[oTree.Roots[#oTree.Roots]] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children=0, taskTreeObj = taskTree}
			if oTree.Roots[#oTree.Roots - 1] then
				oTree.Roots[#oTree.Roots].Prev = oTree.Roots[#oTree.Roots - 1]
				oTree.Roots[#oTree.Roots - 1].Next = oTree.Roots[#oTree.Roots]
			end 
			-- Set the nodes meta table to control the node's interface
			setmetatable(oTree.Roots[#oTree.Roots],nodeMeta)
			oTree.Nodes[nodeInfo.Key] = oTree.Roots[#oTree.Roots]
			oTree.nodeCount = oTree.nodeCount + 1
			-- Add it to the GUI here
			if oTree.Nodes[nodeInfo.Key].Prev then
				oTree.Nodes[nodeInfo.Key].Row = oTree.Nodes[nodeInfo.Key].Prev.Row+1
				if oTree.update then
					dispTask(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
				end
			else
				oTree.Nodes[nodeInfo.Key].Row = 1		-- Row numbering starts from 1 but grid numbering starts from 0 remember
				if oTree.update then
					dispTask(taskTree,1,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,1,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected>0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."])"
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
				end
			end

			-- return the node
			return oTree.Nodes[nodeInfo.Key]
		else
			-- Add it according to the relation 
			if nodeInfo.Relation == Globals.CHILD then
				-- Add child
				local parent = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = parent, taskTreeObj = taskTree}
				nodeMeta[parent].Children = nodeMeta[parent].Children + 1 -- increment number of children
				if nodeMeta[parent].FirstChild then
					-- Parent already has children
					nodeMeta[parent].LastChild.Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[parent].LastChild
					nodeMeta[parent].LastChild = newNode
				else
					nodeMeta[parent].FirstChild = newNode
					nodeMeta[parent].LastChild = newNode
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if nodeMeta[parent].Expanded then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[parent].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of parent
						local prevNode = parent
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == parent then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end

					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
					end
				elseif nodeMeta[parent].Row and nodeMeta[parent].Children == 1 then
					-- This is the 1st child to this visible parent
					-- Add the row label to '+'
					oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			elseif nodeInfo.Relation == Globals.NEXT_SIBLING then
				-- Add next sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj=taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Next then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Next].Prev = newNode
					nodeMeta[newNode].Next = nodeMeta[sib].Next
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
				else
					-- Node is the last one
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].LastChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[sib].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of sib
						local prevNode = sib
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == sib then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			else 
				-- Add previous sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj = taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Prev then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Prev].Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[sib].Prev
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
				else
					-- Node is the First one
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].FirstChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Next].Row
					-- Update the row values of subsequent tasks	
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Key)]
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,0)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,0) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			end
		end		-- if not nodeInfo.Relative then ends here
	end		-- function taskTreeINT.AddNode ends here
	
	local function labelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		if row>-1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			-- Check if the taskNode has children
			if nodeMeta[taskNode].Children > 0 then
				if nodeMeta[taskNode].Expanded then
					taskNode.Expanded = nil
				else
					taskNode.Expanded = true
				end
			end
		end		
		if taskTreeINT[obj].rowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].rowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end
	
	local function ganttLabelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if taskTreeINT[obj].Planning then
			local oTree = taskTreeINT[obj]
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.taskList[i].Row == row+1 then
						-- This is the task modify/add the planning schedule
						togglePlanningType(oTree.taskList[i].Task,oTree.Planning.Type)
						dispGanttFunc(obj,row+1,false,oTree.taskList[i])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		if taskTreeINT[obj].ganttRowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttRowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end

	local function onScrollTreeFunc(obj)
		return function(event)
			local ID = wx.wxID_ANY
			local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, ID)
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Connect(ID,wx.wxEVT_COMMAND_BUTTON_CLICKED,postOnScrollTree(obj))
			oTree.treeGrid:AddPendingEvent(evt)
			event:Skip()
		end
	end
	onScrollTree = onScrollTreeFunc
	
	local function onRowResizeGanttFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.treeGrid:SetRowSize(row,oTree.ganttGrid:GetRowSize(row))
			oTree.treeGrid:ForceRefresh()
			event:Skip()
		end
	end
	
	onRowResizeGantt = onRowResizeGanttFunc
	
	local function onRowResizeTreeFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.ganttGrid:SetRowSize(row,oTree.treeGrid:GetRowSize(row))
			oTree.ganttGrid:ForceRefresh()
			event:Skip()
		end	
	end
	
	onRowResizeTree = onRowResizeTreeFunc
	
	local function postOnScrollGantt(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))

			local currDate = oTree.startDate
			local finDate = oTree.finDate
			local count = 0
--			local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count))
--			y1 = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count+1),wx.wxGridCellCoords(0,count+1))
--   			GUI.frame:SetStatusText(tostring(y:GetTopLeft():GetX())..","..tostring(y:GetTopLeft():GetY())..","..
--   			  tostring(y1:GetTopLeft():GetX())..","..tostring(y1:GetTopLeft():GetY()), 1)
   			
    		--local x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		--local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		local x = oTree.ganttGrid:IsVisible(0,count, false)
			while not x and not currDate:IsLaterThan(finDate) do
				count = count + 1
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				x = oTree.ganttGrid:IsVisible(0,count, false)
				--x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
			end

			-- Now currDate has the date that is not fully visible
			-- Check if the column is more than 60% visible
    		local p6w = oTree.ganttGrid:GetColSize(count)
    		p6w = 0.6*p6w
    		p6w = p6w - p6w%1
    		x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopRight():GetX()
    		if x < p6w then
    			count = count + 1
    			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
    		end

			local corner = oTree.ganttGrid:GetGridCornerLabelWindow()
			corner:DestroyChildren()
			-- Add the Month and year in the corner
			local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			textLabel:SetLabel(currDate:Format("%b %Y"))
			sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
			corner:SetSizer(sizer)
			corner:Layout()	
			oTree.startDate = oTree.startDate:Subtract(wx.wxDateSpan(0,0,0,count))					
		end
	end
	
	local function onScrollGanttFunc(obj)
		return function(event)
			local ID = wx.wxID_ANY
			local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, ID)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Connect(ID,wx.wxEVT_COMMAND_BUTTON_CLICKED,postOnScrollGantt(obj))
			oTree.ganttGrid:AddPendingEvent(evt)
			event:Skip()
		end
	end
	onScrollGantt = onScrollGanttFunc
	
	
	local function horSashAdjustFunc(event)
		--local info = "Sash: "..tostring(GUI.horSplitWin:GetSashPosition()).."\nCol 0: "..tostring(GUI.treeGrid:GetColSize(0)).."\nCol 1 Before: "..tostring(GUI.treeGrid:GetColSize(1))
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local totWidth = 0
		local col
		for i = 1,#oTree.taskTreeConfig do
			if oTree.taskTreeConfig[i].Width ~= -1 then
				totWidth = totWidth + oTree.treeGrid:GetColSize(i-1)
			else
				col = i
			end
		end
	    oTree.treeGrid:SetColMinimalWidth(col-1,oTree.horSplitWin:GetSashPosition()-totWidth-oTree.treeGrid:GetRowLabelSize(0)-wx.wxSystemSettings.GetMetric(wx.wxSYS_VSCROLL_X))
		oTree.treeGrid:AutoSizeColumn(col-1,false)
		--info = info.."\nCol 1 After: "..tostring(GUI.treeGrid:GetColSize(1))
		--GUI.taskDetails:SetValue(info)	
		event:Skip()
	end
	
	local function widgetResizeFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local winSize = event:GetSize()
		local wid = 0.3*winSize:GetWidth()
		if wid > 400 then
			wid = 400
		end
		oTree.horSplitWin:SetSashPosition(wid)
		local totWidth = 0
		local col
		for i = 1,#oTree.taskTreeConfig do
			if oTree.taskTreeConfig[i].Width ~= -1 then
				totWidth = totWidth + oTree.treeGrid:GetColSize(i-1)
			else
				col = i
			end
		end
	    oTree.treeGrid:SetColMinimalWidth(col-1,oTree.horSplitWin:GetSashPosition()-totWidth-oTree.treeGrid:GetRowLabelSize(0)-wx.wxSystemSettings.GetMetric(wx.wxSYS_VSCROLL_X))
		oTree.treeGrid:AutoSizeColumn(col-1,false)

		event:Skip()
	end
	
	local function cellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if row>-1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tpairs(obj) do
				v.Selected = false	-- Make everything else unselected
				if v.Row == row+1 then
					taskNode = v
				end
			end		-- Looping through all the nodes ends
			-- print("Clicked row "..tostring(row))
			taskNode.Selected = true
			taskTreeINT[obj].treeGrid:SetGridCursor(row,col)
			if taskTreeINT[obj].cellClickCallBack then
				taskTreeINT[obj].cellClickCallBack(taskNode.Task, row, col)
			end
		end		
		--taskTreeINT[obj].treeGrid:SelectBlock(row,col,row,col)
		--event:Skip()
	end
	
	local function cellDblClickFunc(event)
		local obj = IDMap[event:GetId()]
		oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		if row>-1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tpairs(obj) do
				v.Selected = false	-- Make everything else unselected
				if v.Row == row+1 then
					taskNode = v
				end
			end		-- Looping through all the nodes ends
			-- print("Clicked row "..tostring(row))
			taskNode.Selected = true
			oTree.treeGrid:SetGridCursor(row,col)
			if oTree.cellDblClickCallBack then
				oTree.cellDblClickCallBack(taskNode.Task, row, col)
			end
		end		
		--taskTreeINT[obj].treeGrid:SelectBlock(row,col,row,col)
		--event:Skip()
	end
	
	local function ganttCellDblClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		-- Find the date on which clicked
		local colCount = 0					
		local stepDate = XMLDate2wxDateTime(toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		if oTree.ganttCellDblClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			oTree.ganttCellDblClickCallBack(taskNode.Task, row, col, toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
	end
	
	local function ganttCellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		local colCount = 0					
		local stepDate = XMLDate2wxDateTime(toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		local colOrig = oTree.ganttGrid:GetGridCursorCol()
		local rowOrig = oTree.ganttGrid:GetGridCursorRow()
		if (oTree.Planning and oTree.Planning.requireSameClick and colOrig==col and rowOrig==row) or (oTree.Planning and not oTree.Planning.requireSameClick) then
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.taskList[i].Row == row+1 then
						-- This is the task modify/add the planning schedule
						togglePlanningDate(oTree.taskList[i].Task,toXMLDate(stepDate:Format("%m/%d/%Y")),oTree.Planning.Type)
						dispGanttFunc(obj,row+1,false,oTree.taskList[i])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		oTree.ganttGrid:SetGridCursor(event:GetRow(),event:GetCol())
		if taskTreeINT[obj].ganttCellClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttCellClickCallBack(taskNode.Task, row, col, toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
		--cellClickFunc(wx.wxGridEvent(event:GetId(),wx.wxEVT_GRID_CELL_LEFT_CLICK,oTree.treeGrid,event:GetRow(),1))
		cellClickFunc(event)
	end		-- local function ganttCellClickFunc(event) ends
	
	ganttCellClick = ganttCellClickFunc
	ganttCellDblClick = ganttCellDblClickFunc
	ganttLabelClick = ganttLabelClickFunc
	cellClick = cellClickFunc
	cellDblClick = cellDblClickFunc
	widgetResize = widgetResizeFunc
	horSashAdjust = horSashAdjustFunc
	labelClick = labelClickFunc
	
end	-- The custom tree and Gantt widget object ends here

