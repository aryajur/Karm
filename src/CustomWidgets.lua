-----------------------------------------------------------------------------
-- Application: Various
-- Purpose:     Custom widgets using wxwidgets
-- Author:      Milind Gupta
-- Created:     2/09/2012
-- Requirements:WxWidgets should be present already in the lua space
-----------------------------------------------------------------------------
local prin
if Karm.Globals.__DEBUG then
	prin = print
end
local modname = ...
local error = error
local print = prin 
local wx = wx
local bit = bit
local type = type
local string = string
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local setfenv = setfenv
local compareDateRanges = Karm.Utility.compareDateRanges
local combineDateRanges = Karm.Utility.combineDateRanges


local NewID = Karm.NewID    -- This is a function to generate a unique wxID for the application this module is used in

-- Setup the module environment
----------------------------------------------------------
local M = {}
package.loaded[modname] = M
if setfenv then
	setfenv(1,M)
else
	_ENV = M
end
----------------------------------------------------------

-- Object to generate and manage a check list 
do
	local objMap = {}		-- private static variable
	local imageList
	
	local getSelectedItems = function(o)
		local selItems = {}
		local itemNum = -1

		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED) ~= -1 do
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			local str
			local item = wx.wxListItem()
			item:SetId(itemNum)
			item:SetMask(wx.wxLIST_MASK_IMAGE)
			o.List:GetItem(item)
			if item:GetImage() == 0 then
				-- Item checked
				str = o.checkedText
			else
				-- Item Unchecked
				str = o.uncheckedText
			end
			item:SetId(itemNum)
			item:SetColumn(1)
			item:SetMask(wx.wxLIST_MASK_TEXT)
			o.List:GetItem(item)
			-- str = item:GetText()..","..str
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}
		end
		return selItems
	end
		
	local getAllItems = function(o)
		local selItems = {}
		local itemNum = -1

		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL) ~= -1 do
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL)
			local str
			local item = wx.wxListItem()
			item:SetId(itemNum)
			item:SetMask(wx.wxLIST_MASK_IMAGE)
			o.List:GetItem(item)
			if item:GetImage() == 0 then
				-- Item checked
				str = o.checkedText
			else
				-- Item Unchecked
				str = o.uncheckedText
			end
			item:SetId(itemNum)
			item:SetColumn(1)
			item:SetMask(wx.wxLIST_MASK_TEXT)
			o.List:GetItem(item)
			-- str = item:GetText()..","..str
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}
		end
		return selItems
	end

	local InsertItem = function(o,Item,checked)
		local ListBox = o.List
		-- Check if the Item exists in the list control
		local itemNum = -1
		-- print(ListBox:GetNextItem(itemNum))
		while ListBox:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = ListBox:GetNextItem(itemNum)
			local obj = wx.wxListItem()
			obj:SetId(itemNum)
			obj:SetColumn(1)
			obj:SetMask(wx.wxLIST_MASK_TEXT)
			ListBox:GetItem(obj)
			local itemText = obj:GetText()
			if itemText == Item then
				-- Get checked status and update
				if checked then
					ListBox:SetItemImage(itemNum,0)
				else
					ListBox:SetItemImage(itemNum,1)
				end				
				return true
			end
			if itemText > Item then
				itemNum = prevItemNum
				break
			end 
		end
		-- itemNum contains the item after which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		local img
		newItem:SetId(itemNum)
		--newItem:SetText(Item)
		if checked then
			newItem:SetImage(0)
		else
			newItem:SetImage(1)
		end				
		--newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
		ListBox:InsertItem(newItem)
		ListBox:SetItem(itemNum,1,Item)
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)		
		ListBox:SetColumnWidth(1,wx.wxLIST_AUTOSIZE)		
		return true
	end

	local ResetCtrl = function(o)
		o.List:DeleteAllItems()
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)
	end

	local RightClick = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
		--o.List:SetImageList(o.mageList,wx.wxIMAGE_LIST_SMALL)
		local item = wx.wxListItem()
		local itemNum = event:GetIndex()
		item:SetId(itemNum)
		item:SetMask(wx.wxLIST_MASK_IMAGE)
		o.List:GetItem(item)
		if item:GetImage() == 0 then
			--item:SetImage(1)
			o.List:SetItemColumnImage(item:GetId(),0,1)
		else
			--item:SetImage(0)
			o.List:SetItemColumnImage(item:GetId(),0,0)
		end
		event:Skip()
	end

	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText,singleSelection)
		if not parent then
			return nil
		end
		local o = {ResetCtrl = ResetCtrl, InsertItem = InsertItem, getSelectedItems = getSelectedItems, getAllItems = getAllItems}	-- new object
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)
		o.checkedText = checkedText or "YES"
		o.uncheckedText = uncheckedText or "NO"
		local ID
		ID = NewID()	
		if singleSelection then	
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_SINGLE_SEL+wx.wxLC_NO_HEADER)
		else
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
		end
		objMap[ID] = o
		-- Create the imagelist and add check and uncheck icons
		imageList = wx.wxImageList(16,16,true,0)
		local icon = wx.wxIcon()
		icon:LoadFile("images/checked.xpm",wx.wxBITMAP_TYPE_XPM)
		imageList:Add(icon)
		icon:LoadFile("images/unchecked.xpm",wx.wxBITMAP_TYPE_XPM)
		imageList:Add(icon)
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)
		-- Add Items
		o.List:InsertColumn(0,"Check")
		o.List:InsertColumn(1,"Options")
		o.Sizer:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		o.List:Connect(wx.wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK, RightClick)
		return o
	end
	
end	-- CheckListCtrl ends


-- Two List boxes and 2 buttons in between class
do
	local objMap = {}	-- Private Static variable

	-- This is exposed to the module since it is a generic function for a listBox
	InsertItem = function(ListBox,Item)
		-- Check if the Item exists in the list control
		local itemNum = -1
		while ListBox:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = ListBox:GetNextItem(itemNum)
			local itemText = ListBox:GetItemText(itemNum)
			if itemText == Item then
				return true
			end
			if itemText > Item then
				itemNum = prevItemNum
				break
			end 
		end
		-- itemNum contains the item after which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		newItem:SetId(itemNum)
		newItem:SetText(Item)
		newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
		ListBox:InsertItem(newItem)
		ListBox:SetItem(itemNum,0,Item)
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)
		return true
	end
	
	AppendItem = function(ListBox,Item)
		-- Check if the Item exists in the list control
		local itemNum = -1
		while ListBox:GetNextItem(itemNum) ~= -1 do
			itemNum = ListBox:GetNextItem(itemNum)
			local itemText = ListBox:GetItemText(itemNum)
			if itemText == Item then
				return true
			end
		end
		itemNum = ListBox:GetItemCount()
		local newItem = wx.wxListItem()
		newItem:SetId(itemNum)
		newItem:SetText(Item)
		newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
		ListBox:InsertItem(newItem)
		ListBox:SetItem(itemNum,0,Item)
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)
		return true
	end

	local getSelectedItems = function(o)
		-- Function to return all the selected items in an array
		-- if the index 0 of the array is true then the none selection checkbox is checked
		local selItems = {}
		local SelList = o.SelList
		local itemNum = -1
		while SelList:GetNextItem(itemNum) ~= -1 do
			itemNum = SelList:GetNextItem(itemNum)
			local itemText = SelList:GetItemText(itemNum)
			selItems[#selItems + 1] = itemText
		end
		-- Finally Check if none selection box exists
		if o.CheckBox and o.CheckBox:GetValue() then
			selItems[0] = "true"
		end
		return selItems
	end
	
	local AddPress = function(event)
		setfenv(1,package.loaded[modname])
		-- Transfer all selected items from List to SelList
		local item
		local o = objMap[event:GetId()]
		local list = o.List
		local selList = o.SelList
		item = list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			local itemText = list:GetItemText(item)
			if o.orderCtrl then
				AppendItem(selList,itemText)
			else
				InsertItem(selList,itemText)
			end			
			selItems[#selItems + 1] = item	
			item = list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		for i=#selItems,1,-1 do
			list:DeleteItem(selItems[i])
		end
		if o.TextBox and o.TextBox:GetValue() ~= "" then
			InsertItem(selList,o.TextBox:GetValue())
			o.TextBox:SetValue("")
		end
	end
	
	local ResetCtrl = function(o)
		o.SelList:DeleteAllItems()
		o.List:DeleteAllItems()
		if o.CheckBox then
			o.CheckBox:SetValue(false)
		end
	end
	
	local UpPress = function(event)
		setfenv(1,package.loaded[modname])
		-- Get all selected Items
		local item
		local o = objMap[event:GetId()]
		local selList = o.SelList
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		-- The 1st item position
		local itemPos = item
		local selItems = {}
		local selItemNum = {}
		while item ~= -1 do
			local itemText = selList:GetItemText(item)
			selItems[#selItems + 1] = itemText
			selItemNum[#selItemNum + 1] = item	
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		-- Now delete all the selected items
		for i=#selItemNum,1,-1 do
			selList:DeleteItem(selItemNum[i])
		end
		-- Now shift all selected items above the item of the 1st selected item
		itemPos = itemPos - 1
		if itemPos < 0 then
			itemPos = 0
		end
		for i=1,#selItems do
			local newItem = wx.wxListItem()
			newItem:SetId(itemPos)
			newItem:SetText(selItems[i])
			newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
			selList:InsertItem(newItem)
			selList:SetItem(itemPos,0,selItems[i])
			selList:SetItemState(itemPos,wx.wxLIST_STATE_SELECTED,wx.wxLIST_STATE_SELECTED)
			itemPos = itemPos + 1			
		end
	end
	
	local DownPress = function(event)
		setfenv(1,package.loaded[modname])
		-- Get all selected Items
		local item
		local o = objMap[event:GetId()]
		local selList = o.SelList
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		local selItemNum = {}
		while item ~= -1 do
			local itemText = selList:GetItemText(item)
			selItems[#selItems + 1] = itemText
			selItemNum[#selItemNum + 1] = item	
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		-- Last Item position
		local itemPos = selItemNum[#selItemNum]
		-- Now shift all selected items below the item of the last selected item
		itemPos = itemPos + 2
		if itemPos > selList:GetItemCount() + 1 then
			itemPos = selList:GetItemCount() + 1
		end
		for i=1,#selItems do
			local newItem = wx.wxListItem()
			newItem:SetId(itemPos)
			newItem:SetText(selItems[i])
			newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
			newItem:SetStateMask(wx.wxLIST_STATE_SELECTED)
			selList:InsertItem(newItem)
			selList:SetItem(itemPos,0,selItems[i])
			selList:SetItemState(itemPos,wx.wxLIST_STATE_SELECTED,wx.wxLIST_STATE_SELECTED)
			itemPos = itemPos + 1			
		end
		-- Now delete all the selected items
		for i=#selItemNum,1,-1 do
			selList:DeleteItem(selItemNum[i])
		end
	end
	
	local RemovePress = function(event)
		setfenv(1,package.loaded[modname])
		-- Transfer all selected items from SelList to List
		local item
		local o = objMap[event:GetId()]
		local list = o.List
		local selList = o.SelList
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			local itemText = selList:GetItemText(item)
			InsertItem(list,itemText)			
			selItems[#selItems + 1] = item	
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		-- Delete those items in the selected items list
		for i=#selItems,1,-1 do
			selList:DeleteItem(selItems[i])
		end
	end
	
	local AddListData = function(o,items)
		if items then
			for i = 1,#items do
				InsertItem(o.List,items[i])
			end
		end
	end
	
	local AddSelListData = function(o,items)
		for i = 1,#items do
			local item = o.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL)
			while item ~= -1 do
				local itemText = o.List:GetItemText(item)
				if itemText == items[i] then
					o.List:DeleteItem(item)
					break
				end		
				item = o.List:GetNextItem(item,wx.wxLIST_NEXT_ALL)	
			end
			InsertItem(o.SelList,items[i])
		end	
	end
	
	MultiSelectCtrl = function(parent, LItems, RItems, noneSelection, textEntry,orderCtrl)
		if not parent then
			return nil
		end
		LItems = LItems or {}
		RItems = RItems or {} 
		local o = {AddSelListData=AddSelListData, AddListData=AddListData, ResetCtrl=ResetCtrl, getSelectedItems = getSelectedItems, orderCtrl = orderCtrl}	-- new object
		-- Create the GUI elements here
		o.Sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
			o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
			-- Add Items
			--local col = wx.wxListItem()
			--col:SetId(0)
			o.List:InsertColumn(0,"Options")
			o:AddListData(LItems)
			sizer1:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local ID
			if textEntry then
				o.TextBox = wx.wxTextCtrl(parent, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
				sizer1:Add(o.TextBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			end
			if noneSelection then
				ID = NewID()
				local str
				if type(noneSelection) ~= "string" then
					str = "None Also Passes"
				else
					str = noneSelection
				end
				o.CheckBox = wx.wxCheckBox(parent, ID, str, wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				objMap[ID] = o 
				sizer1:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			end
			o.Sizer:Add(sizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				ID = NewID()
				o.AddButton = wx.wxButton(parent, ID, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.AddButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				objMap[ID] = o 
				ID = NewID()
				o.RemoveButton = wx.wxButton(parent, ID, "<", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.RemoveButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				objMap[ID] = o
			o.Sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
			-- Add Items
			--col = wx.wxListItem()
			--col:SetId(0)
			o.SelList:InsertColumn(0,"Selections")
			o:AddListData(RItems)
			o.Sizer:Add(o.SelList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			if orderCtrl then
				-- Add buttons to change order for the selected list items
				ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				ID = NewID()
				o.UpButton = wx.wxButton(parent, ID, "Up", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.UpButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				objMap[ID] = o 
				ID = NewID()
				o.DownButton = wx.wxButton(parent, ID, "Dn", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.DownButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				objMap[ID] = o
				o.Sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			end
		-- Connect the buttons to the event handlers
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)
		if orderCtrl then
			o.UpButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,UpPress)
			o.DownButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DownPress)
		end
		return o
	end
end
--  MultiSelectCtrl ends

-- Boolean Tree and Boolean buttons
do

	local objMap = {}	-- Private Static variable
	
	-- Function to convert a boolean string to a Table
	-- Table elements '#AND#', '#OR#', '#NOT()#', '#NOT(AND)#' and '#NOT(OR)#' are reserved and their children are the ones 
	-- on which this operation is performed.
	-- The table consist of:
	-- 1. Item - contains the item name
	-- 2. Parent - contains the parent table
	-- 3. Children - contains a sequence of tables starting from index = 1 similar to the root table
	local function convertBoolStr2Tab(str)
		local boolTab = {Item="",Parent=nil,Children = {},currChild=nil}
		local strLevel = {}
		local subMap = {}
		
		local getUniqueSubst = function(str,subMap)
			if not subMap.latest then
				subMap.latest = 1
			else 
				subMap.latest = subMap.latest + 1
			end
			-- Generate prospective nique string
			local uStr = "A"..tostring(subMap.latest)
			local done = false
			while not done do
				-- Check if this unique string exists in str
				while string.find(str,"[%(%s]"..uStr.."[%)%s]") or 
				  string.find(string.sub(str,1,string.len(uStr) + 1),uStr.."[%)%s]") or 
				  string.find(string.sub(str,-(string.len(uStr) + 1),-1),"[%(%s]"..uStr) do
					subMap.latest = subMap.latest + 1
					uStr = "A"..tostring(subMap.latest)
				end
				done = true
				-- Check if the str exists in subMap mappings already replaced
				for k,v in pairs(subMap) do
					if k ~= "latest" then
						while string.find(v,"[%(%s]"..uStr.."[%)%s]") or 
						  string.find(string.sub(v,1,string.len(uStr) + 1),uStr.."[%)%s]") or 
						  string.find(string.sub(v,-(string.len(uStr) + 1),-1),"[%(%s]"..uStr) do
							done = false
							subMap.latest = subMap.latest + 1
							uStr = "A"..tostring(subMap.latest)
						end
						if done==false then 
							break 
						end
					end
				end		-- for k,v in pairs(subMap) do ends
			end		-- while not done do ends
			return uStr
		end		-- function getUniqueSubst(str,subMap) ends
		
		local bracketReplace = function(str,subMap)
			-- Function to replace brackets with substitutions and fill up the subMap (substitution map)
			-- Make sure the brackets are consistent
			local _,stBrack = string.gsub(str,"%(","t")
			local _,enBrack = string.gsub(str,"%)","t")
			if stBrack ~= enBrack then
				error("String does not have consistent opening and closing brackets",2)
			end
			local brack = string.find(str,"%(")
			while brack do
				local init = brack + 1
				local fin
				-- find the ending bracket for this one
				local count = 0	-- to track additional bracket openings
				for i = init,str:len() do
					if string.sub(str,i,i) == "(" then
						count = count + 1
					elseif string.sub(str,i,i) == ")" then
						if count == 0 then
							-- this is the matching bracket
							fin = i-1
							break
						else
							count = count - 1
						end
					end
				end		-- for i = init,str:len() do ends
				if count ~= 0 then
					error("String does not have consistent opening and closing brackets",2)
				end
				local uStr = getUniqueSubst(str,subMap)
				local pre = ""
				local post = ""
				if init > 2 then
					pre = string.sub(str,1,init-2)
				end
				if fin < str:len() - 2 then
					post = string.sub(str,fin + 2,str:len())
				end
				subMap[uStr] = string.sub(str,init,fin)
				str = pre.." "..uStr.." "..post
				-- Now find the next
				brack = string.find(str,"%(")
			end		-- while brack do ends
			str = string.gsub(str,"%s+"," ")		-- Remove duplicate spaces
			str = string.match(str,"^%s*(.-)%s*$")
			return str
		end		-- function(str,subMap) ends
		
		local OperSubst = function(str, subMap,op)
			-- Function to make the str a simple OR expression
			op = string.lower(string.match(op,"%s*([%w%W]+)%s*"))
			if not(string.find(str," "..op.." ") or string.find(str," "..string.upper(op).." ")) then
				return str
			end
			str = string.gsub(str," "..string.upper(op).." ", " "..op.." ")
			-- Starting chunk
			local strt,stp,subStr = string.find(str,"(.-) "..op.." ")
			local uStr = getUniqueSubst(str,subMap)
			local newStr = {count = 0} 
			newStr.count = newStr.count + 1
			newStr[newStr.count] = uStr
			subMap[uStr] = subStr
			-- Middle chunks
			strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-op:len()-1)
			while strt do
				uStr = getUniqueSubst(str,subMap)
				newStr.count = newStr.count + 1
				newStr[newStr.count] = uStr
				subMap[uStr] = subStr			
				strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-op:len()-1)	
			end
			-- Last Chunk
			strt,stp,subStr = string.find(str,"^.+ "..op.." (.-)$")
			uStr = getUniqueSubst(str,subMap)
			newStr.count = newStr.count + 1
			newStr[newStr.count] = uStr
			subMap[uStr] = subStr
			return newStr
		end		-- local function ORsubst(str) ends
		
		-- First replace all quoted strings in the string with substitutions
		local strSubMap = {}
		local _,numQuotes = string.gsub(str,"%'","t")
		if numQuotes%2 ~= 0 then
			error("String does not have consistent opening and closing quotes \"'\"",2)
		end
		local init,fin = string.find(str,"'.-'")
		while init do
			local uStr = getUniqueSubst(str,subMap)
			local pre = ""
			local post = ""
			if init > 1 then
				pre = string.sub(str,1,init-1)
			end
			if fin < str:len() then
				post = string.sub(str,fin + 1,str:len())
			end
			strSubMap[uStr] = str:sub(init,fin)
			str = pre.." "..uStr.." "..post
			-- Now find the next
			init,fin = string.find(str,"'.-'")
		end		-- while brack do ends
		strLevel[boolTab] = str
		-- Start recursive loop here
		local currTab = boolTab
		while currTab do
			-- Remove all brackets
			strLevel[currTab] = string.gsub(strLevel[currTab],"%s+"," ")
			strLevel[currTab] = bracketReplace(strLevel[currTab],subMap)
			-- Check what type of element this is
			if not(string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") 
			  or string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") 
			  or string.find(strLevel[currTab]," not ") or string.find(strLevel[currTab]," NOT ")
			  or string.upper(string.sub(strLevel[currTab],1,4)) == "NOT "
			  or subMap[strLevel[currTab]]) then
				-- This is a simple element
				if currTab.Item == "#NOT()#" then
					currTab.Children[1] = {Item = strLevel[currTab],Parent=currTab}
				else
					currTab.Item = strLevel[currTab]
					currTab.Children = nil
				end
				-- Return one level up
				currTab = currTab.Parent
				while currTab do
					if currTab.currChild < #currTab.Children then
						currTab.currChild = currTab.currChild + 1
						currTab = currTab.Children[currTab.currChild]
						break
					else
						currTab.currChild = nil
						currTab = currTab.Parent
					end
				end
			elseif not(string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") 
			  or string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") 
			  or string.find(strLevel[currTab]," not ") or string.find(strLevel[currTab]," NOT ")
			  or string.upper(string.sub(strLevel[currTab],1,4)) == "NOT ")
			  and subMap[strLevel[currTab]] then
				-- This is a substitution as a whole
				local temp = strLevel[currTab] 
				strLevel[currTab] = subMap[temp]
				subMap[temp] = nil
			else
				-- This is a normal expression
				if string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") then
					-- The expression has OR operators
					-- Transform to a simple OR expression
					local simpStr = OperSubst(strLevel[currTab],subMap,"OR")
					if currTab.Item == "#NOT()#" then
						currTab.Item = "#NOT(OR)#"
					else
						currTab.Item = "#OR#"
					end
					-- Now allchildren need to be added and we must evaluate each child
					for i = 1,#simpStr do
						currTab.Children[#currTab.Children + 1] = {Item="", Parent = currTab,Children={},currChild=nil}
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]
					end 
					currTab.currChild = 1
					currTab = currTab.Children[1]
				elseif string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") then
					-- The expression does not have OR operators but has AND operators
					-- Transform to a simple AND expression
					local simpStr = OperSubst(strLevel[currTab],subMap,"AND")
					if currTab.Item == "#NOT()#" then
						currTab.Item = "#NOT(AND)#"
					else
						currTab.Item = "#AND#"
					end
					-- Now allchildren need to be added and we must evaluate each child
					for i = 1,#simpStr do
						currTab.Children[#currTab.Children + 1] = {Item="", Parent = currTab,Children={},currChild=nil}
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]
					end 
					currTab.currChild = 1
					currTab = currTab.Children[1]
				else
					-- This is a NOT element
					strLevel[currTab] = string.gsub(strLevel[currTab],"NOT", "not")
					local elem = string.match(strLevel[currTab],"%s*not%s+([%w%W]+)%s*")
					currTab.Item = "#NOT()#"
					strLevel[currTab] = elem
				end		-- if string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") then ends
			end 
		end		-- while currTab do ends
		-- Now recurse boolTab to substitute all the strings back
		local t = boolTab
		if strSubMap[t.Item] then
			t.Item = string.match(strSubMap[t.Item],"'(.-)'")
		end
		if t.Children then
			-- Traverse the table to fill up the tree
			local tIndex = {}
			tIndex[t] = 1
			while tIndex[t] <= #t.Children or t.Parent do
				if tIndex[t] > #t.Children then
					tIndex[t] = nil
					t = t.Parent
				else
					-- Handle the current element
					if strSubMap[t.Children[tIndex[t]].Item] then
						t.Children[tIndex[t]].Item = strSubMap[t.Children[tIndex[t]].Item]:match("'(.-)'")
					end
					tIndex[t] = tIndex[t] + 1
					-- Check if this has children
					if t.Children[tIndex[t]-1].Children then
						-- go deeper in the hierarchy
						t = t.Children[tIndex[t]-1]
						tIndex[t] = 1
					end
				end		-- if tIndex[t] > #t then ends
			end		-- while tIndex[t] <= #t and t.Parent do ends
		end	-- if t.Children then ends
		return boolTab
	end		-- function convertBoolStr2Tab(str) ends

	-- Function to set the boolean string expression in the tree
	local function setExpression(o,str)
		local t = convertBoolStr2Tab(str)
		local tIndex = {}
		local tNode = {}
		local itemText = function(itemStr)
			-- To return the item text
			if itemStr == "#AND#" then
				return "(AND)"
			elseif itemStr == "#OR#" then
				return "(OR)"
			elseif itemStr == "#NOT()#" then
				return "NOT()"
			elseif itemStr == "#NOT(AND)#" then
				return "NOT(AND)"
			elseif itemStr == "#NOT(OR)#" then
				return "NOT(OR)"
			else
				return itemStr
			end
		end
		-- Clear the control
		o:ResetCtrl()
		tNode[t] = o.SelTree:AppendItem(o.SelTree:GetRootItem(),itemText(t.Item))
		if t.Children then
			-- Traverse the table to fill up the tree
			tIndex[t] = 1
			while tIndex[t] <= #t.Children or t.Parent do
				if tIndex[t] > #t.Children then
					tIndex[t] = nil
					t = t.Parent
				else
					-- Handle the current element
					local parentNode 
					parentNode = tNode[t]
					tNode[t.Children[tIndex[t]]] = o.SelTree:AppendItem(parentNode,itemText(t.Children[tIndex[t]].Item)) 
					tIndex[t] = tIndex[t] + 1
					-- Check if this has children
					if t.Children[tIndex[t]-1].Children then
						-- go deeper in the hierarchy
						t = t.Children[tIndex[t]-1]
						tIndex[t] = 1
					end
				end		-- if tIndex[t] > #t then ends
			end		-- while tIndex[t] <= #t and t.Parent do ends
		end	-- if t.Children then ends
		o.SelTree:Expand(o.SelTree:GetRootItem())
	end		-- local function setExpression(o,str) ends
	
	local treeRecRef
	local treeRecurse = function(tree,node)
		local itemText = tree:GetItemText(node) 
		if itemText == "(AND)" or itemText == "(OR)" or itemText == "NOT(OR)" or itemText == "NOT(AND)" then
			local retText = "(" 
			local logic = string.lower(" "..string.match(itemText,"%((.-)%)").." ")
			if string.sub(itemText,1,3) == "NOT" then
				retText = "not("
			end
			local currNode = tree:GetFirstChild(node)
			retText = retText..treeRecRef(tree,currNode)
			currNode = tree:GetNextSibling(currNode)
			while currNode:IsOk() do
				retText = retText..logic..treeRecRef(tree,currNode)
				currNode = tree:GetNextSibling(currNode)
			end
			return retText..")"
		elseif itemText == "NOT()" then
			return "not("..treeRecRef(tree,tree:GetFirstChild(node))..")"
		else
			return "'"..itemText.."'"
		end
	end
	treeRecRef = treeRecurse

	local BooleanExpression = function(o)
		local tree = o.SelTree
		local currNode = tree:GetFirstChild(tree:GetRootItem())
		if currNode:IsOk() then
			local expr = treeRecurse(tree,currNode)
			return expr
		else
			return nil
		end		
	end
		
	local CopyTree = function(treeObj,srcItem,destItem)
		-- This will copy the srcItem and its child tree to as a child of destItem
		if not srcItem:IsOk() or not destItem:IsOk() then
			error("Expected wxTreeItemIds",2)
		end
		local tree = treeObj.SelTree
		local currSrcNode = srcItem
		local currDestNode = destItem
		-- Copy the currSrcNode under the currDestNode
		currDestNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))
		-- Check if any children
		if tree:ItemHasChildren(currSrcNode) then
			currSrcNode = tree:GetFirstChild(currSrcNode)
			while true do
				-- Copy the currSrcNode under the currDestNode
				local currNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))
				-- Check if any children
				if tree:ItemHasChildren(currSrcNode) then
					currDestNode = currNode
					currSrcNode = tree:GetFirstChild(currSrcNode)
				elseif tree:GetNextSibling(currSrcNode):IsOk() then
					-- There are more items in the same level
					currSrcNode = tree:GetNextSibling(currSrcNode)
				else
					-- No children and no further siblings so go up
					currSrcNode = tree:GetItemParent(currSrcNode)
					currDestNode = tree:GetItemParent(currDestNode)
					while not tree:GetNextSibling(currSrcNode):IsOk() and not(currSrcNode:GetValue() == srcItem:GetValue()) do
						currSrcNode = tree:GetItemParent(currSrcNode)
						currDestNode = tree:GetItemParent(currDestNode)
					end
					if currSrcNode:GetValue() == srcItem:GetValue() then
						break
					end
					currSrcNode = tree:GetNextSibling(currSrcNode)
				end		-- if tree:ItemHasChildren(currSrcNode) then ends
			end		-- while true do ends
		end		-- if tree:ItemHasChildren(currSrcNode) then ends
	end
	
	local DelTree = function(treeObj,item)
		if not item:IsOk() then
			error("Expected proper wxTreeItemId",2)
		end
		local tree = treeObj.SelTree
		local currNode = item
		if tree:ItemHasChildren(currNode) then
			currNode = tree:GetFirstChild(currNode)
			while true do
				-- Check if any children
				if tree:ItemHasChildren(currNode) then
					currNode = tree:GetFirstChild(currNode)
				elseif tree:GetNextSibling(currNode):IsOk() then
					-- delete this node
					-- There are more items in the same level
					local next = tree:GetNextSibling(currNode)
					tree:Delete(currNode)
					currNode = next 
				else
					-- No children and no further siblings so delete and go up
					local parent = tree:GetItemParent(currNode)
					tree:Delete(currNode)
					currNode = parent
					while not tree:GetNextSibling(currNode):IsOk() and not(currNode:GetValue() == item:GetValue()) do
						parent = tree:GetItemParent(currNode)
						tree:Delete(currNode)
						currNode = parent
					end
					if currNode:GetValue() == item:GetValue() then
						break
					end
					currNode = tree:GetNextSibling(currNode)
				end		-- if tree:ItemHasChildren(currSrcNode) then ends
			end		-- while true do ends
		end		-- if tree:ItemHasChildren(currNode) then ends
		tree:Delete(currNode)		
	end
	
	local ResetCtrl = function(o)
		if o.SelTree:GetFirstChild(o.SelTree:GetRootItem()):IsOk() then
			DelTree(o,o.SelTree:GetFirstChild(o.SelTree:GetRootItem()))
		end
	end
	
	local DeletePress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = objMap[event:GetId()]
		local Sel = ob.object.SelTree:GetSelections(Sel)	
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		-- Get list of Parents
		local parents = {}
		-- Delete all selected
		for i=1,#Sel do
			local parent = ob.object.SelTree:GetItemParent(Sel[i])
			local addParent = true
			for j = 1,#parents do
				if parents[j]:GetValue() == parent:GetValue() then
					addParent = nil
					break
				end
			end
			if addParent then
				parents[#parents + 1] = parent
			end
			if Sel[i]:GetValue() ~= ob.object.SelTree:GetRootItem():GetValue() then
				DelTree(ob.object,Sel[i])
			end
		end
		-- Check for any parents that are logic nodes with only 1 child under them
		for i = 1,#parents do
			if ob.object.SelTree:GetChildrenCount(parents[i],false) == 1 then
				local nodeText = ob.object.SelTree:GetItemText(parents[i])
				if nodeText == "(OR)" or nodeText == "(AND)" then
					-- This is a logic node without NOT()
					-- Delete the Parent and move the children up 1 level
					-- Move it up the hierarchy
					local pParent = ob.object.SelTree:GetItemParent(parents[i])
					-- Copy all children to pParent
					local currNode = ob.object.SelTree:GetFirstChild(parents[i])
					while currNode:IsOk() do
						CopyTree(ob.object,currNode,pParent)
						currNode = ob.object.SelTree:GetNextSibling(currNode)
					end
					DelTree(ob.object,parents[i])
				elseif nodeText == "NOT(OR)" or nodeText == "NOT(AND)"  then
					-- Just change the text to NOT()
					ob.object.SelTree:SetItemText(node,"NOT(OR)")
				end
			end
		end
		if ob.object.SelTree:GetChildrenCount(ob.object.SelTree:GetRootItem()) == 1 then
			ob.object.DeleteButton:Disable()
		end
	end
	
	local NegatePress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = objMap[event:GetId()]
		local Sel = ob.object.SelTree:GetSelections(Sel)	
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		local parent = ob.object.SelTree:GetItemParent(Sel[1])
		for i = 2,#Sel do
			if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
				wx.wxMessageBox("For multiple selection negate they must all be under the same node.","Selections not at the same level", wx.wxOK + wx.wxCENTRE, o.parent)
				return
			end
		end
		if parent:IsOk() then
			if #Sel == 1 then
				-- Single Selection
				-- Check if this is a Logic node
				local nodeText = ob.object.SelTree:GetItemText(Sel[1])
				if nodeText == "(OR)" or nodeText == "(AND)" or nodeText == "NOT(OR)" or nodeText == "NOT(AND)" or nodeText == "NOT()" then
					-- Just negation of the node has to be done
					local node = Sel[1]
					if nodeText == "(OR)" then
						ob.object.SelTree:SetItemText(node,"NOT(OR)")
					elseif nodeText == "(AND)" then
						ob.object.SelTree:SetItemText(node,"NOT(AND)")
					elseif nodeText == "NOT(OR)" then
						ob.object.SelTree:SetItemText(node,"(OR)")
					elseif nodeText == "NOT(AND)" then
						ob.object.SelTree:SetItemText(node,"(AND)")
					else
						-- NOT()
						-- Move it up the hierarchy
						local pParent = ob.object.SelTree:GetItemParent(node)
						-- Copy all children to pParent
						local currNode = ob.object.SelTree:GetFirstChild(node)
						while currNode:IsOk() do
							CopyTree(ob.object,currNode,pParent)
							currNode = ob.object.SelTree:GetNextSibling(currNode)
						end
						DelTree(ob.object,node)
					end		-- if parentText == "(OR)" then ends here
				-- Check if the parent just has this child
				elseif ob.object.SelTree:GetChildrenCount(parent,false) == 1 then
					local node = parent
					nodeText = ob.object.SelTree:GetItemText(parent)
					if nodeText == "(OR)" then
						ob.object.SelTree:SetItemText(node,"NOT(OR)")
					elseif nodeText == "(AND)" then
						ob.object.SelTree:SetItemText(node,"NOT(AND)")
					elseif nodeText == "NOT(OR)" then
						ob.object.SelTree:SetItemText(node,"(OR)")
					elseif nodeText == "NOT(AND)" then
						ob.object.SelTree:SetItemText(node,"(AND)")
					elseif nodeText == "NOT()" then
						-- Move it up the hierarchy
						local pParent = ob.object.SelTree:GetItemParent(node)
						CopyTree(ob.object,Sel[1],pParent)
						DelTree(ob.object,node)
					elseif nodeText == "Expressions" then
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						CopyTree(ob.object,Sel[1],currNode)
						DelTree(ob.object,Sel[1])
					else
						error("Code Error: This condition should never occur! Boolean Tree Negate press -- 1.",1)					
					end		-- if parentText == "(OR)" then ends here
				else
					local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
					CopyTree(ob.object,Sel[1],currNode)
					DelTree(ob.object,Sel[1])
				end		-- if type of node - Logic Node, Single Child node of a parent or one of many children
			else
				-- Multiple Selection
				-- Check if the parent just has these children
				local parentText = ob.object.SelTree:GetItemText(parent)
				if ob.object.SelTree:GetChildrenCount(parent,false) == #Sel then
					-- Just modify the parent text
					if parentText == "(OR)" then
						ob.object.SelTree:SetItemText(parent,"NOT(OR)")
					elseif parentText == "(AND)" then
						ob.object.SelTree:SetItemText(parent,"NOT(AND)")
					elseif parentText == "NOT(OR)" then
						ob.object.SelTree:SetItemText(parent,"(OR)")
					elseif parentText == "NOT(AND)" then 
						ob.object.SelTree:SetItemText(parent,"(AND)")
					else
						error("Code Error: This condition should never occur! Boolean Tree Negate press -- 2.",1)					
					end
				else
					-- First move the selections to a correct new node
					if parentText == "(OR)" or parentText == "NOT(OR)" then
						parentText = "NOT(OR)"
					elseif parentText == "(AND)" or parentText == "NOT(AND)" then
						parentText = "NOT(AND)" 
					else
						error("Code Error: This condition should never occur! Boolean Tree Negate press -- 3.",1)					
					end
					parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)
					for i = 1,#Sel do
						CopyTree(ob.object,Sel[i],parent)
						DelTree(ob.object,Sel[i])
					end
				end
			end
		end	-- if parent:IsOk() then
	end
	
	local LogicPress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = objMap[event:GetId()]
		-- Get the Logic Unit
		local unit = ob.object.getInfo()
		if not unit then
			return nil
		end
		
		local root = ob.object.SelTree:GetRootItem()
		if ob.object.SelTree:GetCount() == 1 then
			-- Just add this first object
			local currNode = ob.object.SelTree:AppendItem(root,unit)
			ob.object.SelTree:Expand(root)
			return nil
		end
		-- More than 1 item in the tree so now find the selections and  modify the tree
		local Sel = ob.object.SelTree:GetSelections(Sel)
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		
		-- Check if parent of all selections is the same	
		if #Sel > 1 then
        	local parent = ob.object.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Parent is not common. 
        			wx.wxMessageBox("All selected items not siblings!","Error applying operation", wx.wxICON_ERROR)
        			return nil
        		end
        	end
        end
		
		-- Check if root node selected
		if #Sel == 1 and ob.object.SelTree:GetRootItem():GetValue() == Sel[1]:GetValue() then
			-- Root item selected clear Sel and fill up with all children of root
			Sel = {}
			local node = ob.object.SelTree:GetFirstChild(ob.object.SelTree:GetRootItem())
			Sel[#Sel + 1] = node
			node = ob.object.SelTree:GetNextSibling(node)
			while node:IsOk() do
				Sel[#Sel + 1] = node
				node = ob.object.SelTree:GetNextSibling(node)
			end
		end
		local added = nil
		if #Sel > 1 then
			-- Check if all children selected
			local parent = ob.object.SelTree:GetItemParent(Sel[1])
			if #Sel == ob.object.SelTree:GetChildrenCount(parent,false) then
				-- All children of parent are selected
				-- Check if the unit can be added under the parent itself
				local parentText = ob.object.SelTree:GetItemText(parent)
				if ((ob.button == "AND" or ob.button == "NAND" or ob.button == "ANDN" or ob.button == "NANDN") and 
						(parentText == "(AND)" or parentText == "NOT(AND)")) or
				   ((ob.button == "OR" or ob.button == "NOR" or ob.button == "ORN" or ob.button == "NORN") and 
				   		(parentText == "(OR)" or parentText == "NOT(OR)")) then
					-- Add the unit under parent
					if ob.button == "AND" or ob.button == "OR" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					elseif ob.button == "NAND" or ob.button == "NOR" then
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					elseif ob.button == "ANDN" or ob.button == "ORN" or ob.button == "NANDN" or ob.button == "NORN" then
						if parentText == "(AND)" or parentText == "(OR)"then
							-- Move all selected to a negated subnode
							local newPText 
							if parentText == "(OR)" then
								newPText = "NOT(OR)"
							elseif parentText == "(AND)" then
								newPText = "NOT(AND)" 
							end
							local newParent = ob.object.SelTree:AppendItem(parent,newPText)
							for i = 1,#Sel do
								CopyTree(ob.object,Sel[i],newParent)
								DelTree(ob.object,Sel[i])
							end
						elseif parentText == "NOT(AND)" then
							ob.object.SelTree:SetItemText(parent,"(AND)")
						elseif parentText == "NOT(OR)" then
							ob.object.SelTree:SetItemText(parent,"(OR)")
						end
						-- Now add the unit to the parent
						if ob.button == "NANDN" or ob.button == "NORN" then
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						else
							ob.object.SelTree:AppendItem(parent,unit)
						end
					end
					added = true
				end
			end		-- if #Sel < ob.object.SelTree:GetChildrenCount(parent) then ends
			if not added then
				-- Move all selected to sub node
				local parentText = ob.object.SelTree:GetItemText(parent)
				if parentText == "(OR)" or parentText == "NOT(OR)" then
					parentText = "(OR)"
				elseif parentText == "(AND)" or parentText == "NOT(AND)" then
					parentText = "(AND)" 
				end
				parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)
				for i = 1,#Sel do
					CopyTree(ob.object,Sel[i],parent)
					DelTree(ob.object,Sel[i])
				end
				Sel = {parent}
			end
		end
		if not added then
			-- Single item selection case
			-- Check if this is a logic node and the unit can directly be added to it
			local selText = ob.object.SelTree:GetItemText(Sel[1])
			if selText == "(OR)" and (ob.button == "OR" or ob.button == "NOR") then
				if ob.button == "OR" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			elseif  selText == "(AND)" and (ob.button == "AND" or ob.button == "NAND") then
				if ob.button == "AND" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			elseif selText == "NOT(OR)" and (ob.button == "ORN" or ob.button == "NORN") then
				if ob.button == "ORN" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
				ob.object.SelTree:SetItemText(Sel[1],"(OR)")
			elseif selText == "NOT(AND)" and (ob.button == "ANDN" or ob.button == "NANDN") then
				if ob.button == "ANDN" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
				ob.object.SelTree:SetItemText(Sel[1],"(AND)")
			elseif selText == "NOT()" and (ob.button == "ANDN" or ob.button == "NANDN" or ob.button == "ORN" or ob.button == "NORN")then
				if ob.button == "ANDN" then
					ob.object.SelTree:SetItemText(Sel[1],"(AND)")
					ob.object.SelTree:AppendItem(Sel[1],unit)
				elseif ob.button == "NANDN" then
					ob.object.SelTree:SetItemText(Sel[1],"(AND)")
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				elseif ob.button == "ORN" then
					ob.object.SelTree:SetItemText(Sel[1],"(OR)")
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					ob.object.SelTree:SetItemText(Sel[1],"(OR)")
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			else
				-- Unit cannot be added to the selected node since that is also a unit
				local parent = ob.object.SelTree:GetItemParent(Sel[1])
				local parentText = ob.object.SelTree:GetItemText(parent)
				-- Handle the directly adding unit to parent cases
				if (parentText == "(OR)" or parentText == "NOT(OR)") and  (ob.button == "OR" or ob.button == "NOR") then
					if ob.button == "OR" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					else
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					end
				elseif (parentText == "(AND)" or parentText == "NOT(AND)") and (ob.button == "AND" or ob.button == "NAND") then
					if ob.button == "AND" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					else
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					end
				elseif parentText == "NOT()" and (ob.button == "AND" or ob.button == "NAND" or ob.button == "OR" or ob.button == "NOR" or ob.button == "ANDN" or ob.button == "ORN") then
					-- parentText = "NOT()"
					-- Change Parent text
					if ob.button == "NAND" or ob.button == "AND" then
						ob.object.SelTree:SetItemText(parent,"NOT(AND)")
						if ob.button == "AND" then
							-- Add to parent directly
							ob.object.SelTree:AppendItem(parent,unit)
						else
							-- Add to parent by negating first
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						end
					elseif ob.button=="NOR" or ob.button == "OR" then
						ob.object.SelTree:SetItemText(parent,"NOT(OR)")
						if ob.button == "OR" then
							-- Add to parent directly
							ob.object.SelTree:AppendItem(parent,unit)
						else
							-- Add to parent by negating first
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						end
					elseif ob.button=="ORN" then
						ob.object.SelTree:SetItemText(parent,"(OR)")
						ob.object.SelTree:AppendItem(parent,unit)
					elseif ob.button=="ANDN" then
						ob.object.SelTree:SetItemText(parent,"(AND)")
						ob.object.SelTree:AppendItem(parent,unit)						
					end
				else
					-- Now we need to move this single selected node to a new fresh node in its place and add unit also to that node
					if ob.button == "AND" or ob.button == "NAND" or ob.button == "ANDN" or ob.button == "NANDN" then
						parentText = "(AND)"
					elseif ob.button == "OR" or ob.button == "NOR" or ob.button == "ORN" or ob.button == "NORN" then
						parentText = "(OR)"
					end
					local currNode = ob.object.SelTree:AppendItem(parent,parentText)
					if ob.button == "ANDN" or ob.button =="NANDN" or ob.button == "ORN" or ob.button == "NORN" then
						local negNode = ob.object.SelTree:AppendItem(currNode,"NOT()")
						CopyTree(ob.object,Sel[1],negNode)
					else 
						CopyTree(ob.object,Sel[1],currNode)
					end		
					DelTree(ob.object,Sel[1])
					-- Add the unit
					if ob.button == "AND" or ob.button == "OR" or ob.button == "ANDN" or ob.button == "ORN" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(currNode,unit)
					else
						-- Add to parent by negating first
						local negNode = ob.object.SelTree:AppendItem(currNode,"NOT()")
						ob.object.SelTree:AppendItem(negNode,unit)
					end
				end		-- if (parentText == "(OR)" or parentText == "NOT(OR)") and  (ob.button == "OR" or ob.button == "NOR") then ends
			end		-- if selText == "(OR)" and (ob.button == "OR" or ob.button == "NOR") then ends
		end	-- if not added then ends
		--print(ob.object,ob.button)
		--print(BooleanTreeCtrl.BooleanExpression(ob.object.SelTree))	
	end
	
--[[	local TreeSelChanged = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
        
        -- Update the Delete Button status
        local Sel = o.SelTree:GetSelections(Sel)
        if #Sel == 0 then
        	o.prevSel = {}
        	o.DeleteButton:Disable()
        	return nil
        end
        o.DeleteButton:Enable(true)
    	-- Check here if there are more than 1 difference between Sel and prevSel
    	local diff = 0
    	for i = 1,#Sel do
    		local found = nil
    		for j = 1,#o.prevSel do
    			if Sel[i]:GetValue() == o.prevSel[j]:GetValue() then
    				found = true
    				break
    			end
    		end
    		if not found then
    			diff = diff + 1
    		end
    	end
    	-- diff has number of elements in Sel but nout found in o.prevSel
    	for i = 1,#o.prevSel do
    		local found = nil
    		for j = 1,#Sel do
    			if Sel[j]:GetValue() == o.prevSel[i]:GetValue() then
    				found = true
    				break
    			end
    		end
    		if not found then
    			diff = diff + 1
    		end
    	end
        if #Sel > 1 and diff == 1 then
        	-- Check here if the selection needs to be modified to keep at the same level
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Need to modify the selection here
        			-- Find which element was selected last here
        			local newElem = nil
        			for j = 1,#Sel do
        				local found = nil
        				for k = 1,#o.prevSel do
        					if Sel[j]:GetValue() == o.prevSel[k]:GetValue() then
        						found = true
        						break
        					end
        				end
        				if not found then
        					newElem = Sel[j]
        					break
        				end
        			end		-- for j = 1,#Sel do ends
        			-- Now newElem has the newest element so deselect everything and select that
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			o.SelTree:SelectItem(newElem,true)
	        		Sel = o.SelTree:GetSelections(Sel)
					o.prevSel = {}
					for i = 1,#Sel do
						o.prevSel[i] = Sel[i]
					end
        			break
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends
        	end		-- for i = 2,#Sel do ends
        end		-- if #Sel > 1 then
--        if #Sel > 1 or o.SelTree:ItemHasChildren(Sel[1]) then
--        	o.DeleteButton:Disable()
--        else
--        	o.DeleteButton:Enable(true)
--        end
		-- Populate prevSel table
    	if diff == 1 and math.abs(#Sel-#o.prevSel) == 1 then
			o.prevSel = {}
			for i = 1,#Sel do
				o.prevSel[i] = Sel[i]
			end
		elseif diff > 1 and math.abs(#Sel-#o.prevSel) == diff then
			-- Selection made by Shift Key check if at same hierarchy then update prevSel otherwise rever to prevSel
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	local updatePrev = true
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Now newElem has the newest element so deselect everything and select that
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			for j = 1,#o.prevSel do
        				o.SelTree:SelectItem(o.prevSel[j],true)
        			end
        			updatePrev = false
        			break
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends
        	end		-- for i = 2,#Sel do ends	
        	if updatePrev then		
				o.prevSel = {}
				for i = 1,#Sel do
					o.prevSel[i] = Sel[i]
				end
			end
		end
		
		--event:Skip()
		--print(o.SelTree:GetItemText(item))
	end,]]
	
	local TreeSelChanged = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
        
        -- Update the Delete Button status
        local Sel = o.SelTree:GetSelections(Sel)
        if #Sel == 0 then
        	o.prevSel = {}
        	o.DeleteButton:Disable()
        	o.NegateButton:Disable()
        	return nil
        end
        o.DeleteButton:Enable(true)
       	o.NegateButton:Enable(true)
		-- Check if parent of all selections is the same	
		if #Sel > 1 then
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Deselect everything
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			-- Select the items with the largest parent
        			local parents = {}	-- To store parents and their numbers
        			for j =1,#Sel do
        				local found = nil
        				for k = 1,#parents do
        					if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[k].ID:GetValue() then
        						parents[k].count = parents[k].count + 1
        						found = true
        						break
        					end
        				end
        				if not found then
        					parents[#parents + 1] = {ID = o.SelTree:GetItemParent(Sel[j]), count = 1}
        				end
        			end
        			-- Find parent with largest number of children
        			local index = 1
        			for j = 2,#parents do
        				if parents[j].count > parents[index].count then
        					index = j
        				end
        			end
        			-- Select all items with parents[index].ID as parent
        			for j = 1,#Sel do
        				if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[index].ID:GetValue() then
        					o.SelTree:SelectItem(Sel[j],true)
        				end
        			end		-- for j = 1,#Sel do ends
        		end		-- if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then ends
        	end		-- for i = 2,#Sel do ends
        end		-- if #Sel > 1 then ends
        if o.clickEventFunc and type(o.clickEventFunc) == "function" then
	        local Sel = o.SelTree:GetSelections(Sel)
	        local selText = {}
	        for i = 1,#Sel do
	        	selText[i] = o.SelTree:GetItemText(Sel[i])
	        end
        	o.clickEventFunc(selText)
        end
        event:Skip()
	end
	
	local associateEventFunc = function(o,funcTable)
		o.clickEventFunc = funcTable.clickEventFunc or o.clickEventFunc 
	end
	
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc)
		if not parent or not sizer or not getInfoFunc or type(getInfoFunc)~="function" then
			return nil
		end
		local o = {ResetCtrl=ResetCtrl,BooleanExpression=BooleanExpression, setExpression = setExpression, associateEventFunc = associateEventFunc}
		o.getInfo = getInfoFunc
		o.prevSel = {}
		o.parent = parent
		local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local ID = NewID()
			o.ANDButton = wx.wxButton(parent, ID, "AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="AND"}
			ButtonSizer:Add(o.ANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ORButton = wx.wxButton(parent, ID, "OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="OR"}
			ButtonSizer:Add(o.ORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NANDButton = wx.wxButton(parent, ID, "NOT() AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="NAND"}
			ButtonSizer:Add(o.NANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NORButton = wx.wxButton(parent, ID, "NOT() OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="NOR"}
			ButtonSizer:Add(o.NORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ANDNButton = wx.wxButton(parent, ID, "AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="ANDN"}
			ButtonSizer:Add(o.ANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ORNButton = wx.wxButton(parent, ID, "OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="ORN"}
			ButtonSizer:Add(o.ORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NANDNButton = wx.wxButton(parent, ID, "NOT() AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="NANDN"}
			ButtonSizer:Add(o.NANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NORNButton = wx.wxButton(parent, ID, "NOT() OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = {object=o,button="NORN"}
			ButtonSizer:Add(o.NORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local treeSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				ID = NewID()
				o.SelTree = wx.wxTreeCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxTR_HAS_BUTTONS,wx.wxTR_MULTIPLE))
				objMap[ID] = o
				-- Add the root
				local root = o.SelTree:AddRoot("Expressions")
				o.SelTree:SelectItem(root)
			treeSizer:Add(o.SelTree, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Add the Delete and Negate Buttons
				ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					ID = NewID()
					o.DeleteButton = wx.wxButton(parent, ID, "Delete", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					objMap[ID] = {object=o,button="Delete"}
				ButtonSizer:Add(o.DeleteButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				o.DeleteButton:Disable()
					ID = NewID()
					o.NegateButton = wx.wxButton(parent, ID, "Negate", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					objMap[ID] = {object=o,button="Negate"}
				ButtonSizer:Add(o.NegateButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				o.NegateButton:Disable()
			treeSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)		
		sizer:Add(treeSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
		-- Connect the buttons to the event handlers
		o.ANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.ORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.NANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.NORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.ANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.ORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.NANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.NORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)
		o.DeleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DeletePress)
		o.NegateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,NegatePress)
		
		-- Connect the tree to the left click event
		o.SelTree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, TreeSelChanged)
		return o
	end
end		-- BooleanTreeCtrl ends

-- Control to select date Range
do
	local objMap = {}
	SelectDateRangeCtrl = function(parent,numInstances,returnFunc)
		if not objMap[parent] then
			objMap[parent] = 1
		elseif objMap[parent] >= numInstances then
			return false
		else
			objMap[parent] = objMap[parent] + 1
		end
		local drFrame = wx.wxFrame(parent, wx.wxID_ANY, "Date Range Selection", wx.wxDefaultPosition,
			wx.wxDefaultSize, wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION
			+ wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN)
		local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		local calSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local fromSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		local label = wx.wxStaticText(drFrame, wx.wxID_ANY, "From:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		fromSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		local fromDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)
		fromSizer:Add(fromDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

		local toSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		label = wx.wxStaticText(drFrame, wx.wxID_ANY, "To:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		toSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		local toDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)
		toSizer:Add(toDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		calSizer:Add(fromSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		calSizer:Add(toSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- Add Buttons
		local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local selButton = wx.wxButton(drFrame, wx.wxID_ANY, "Select", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		buttonSizer:Add(selButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		local CancelButton = wx.wxButton(drFrame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		buttonSizer:Add(CancelButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		
		
		MainSizer:Add(calSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		drFrame:SetSizer(MainSizer)
		MainSizer:SetSizeHints(drFrame)
	    drFrame:Layout() -- help sizing the windows before being shown
	    drFrame:Show(true)
	    
		selButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)
			setfenv(1,package.loaded[modname])
			returnFunc(fromDate:GetDate():Format("%m/%d/%Y").."-"..toDate:GetDate():Format("%m/%d/%Y"))
			drFrame:Close()
			objMap[parent] = objMap[parent] - 1
		end	
		)
		CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)
			setfenv(1,package.loaded[modname])
			drFrame:Close() 
			objMap[parent] = objMap[parent] - 1
		end
		)	    	
	end		-- display = function(parent,numInstances,returnFunc) ends
end		-- SelectDateRangeCtrl ends

-- Date Range Selection Control
do
	local objMap = {}		-- Private Static Variable
	
	local getSelectedItems = function(o)
		local selItems = {}
		local SelList = o.list
		local itemNum = -1
		while SelList:GetNextItem(itemNum) ~= -1 do
			itemNum = SelList:GetNextItem(itemNum)
			local itemText = SelList:GetItemText(itemNum)
			selItems[#selItems + 1] = itemText
		end
		-- Finally Check if none selection box exists
		if o.CheckBox and o.CheckBox:GetValue() then
			selItems[0] = "true"
		end
		return selItems
	end

    local addRange = function(o,range)
		-- Check if the Item exists in the list control
		local itemNum = -1
		local conditionList = false
		while o.list:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = o.list:GetNextItem(itemNum)
			local itemText = o.list:GetItemText(itemNum)
			-- Now compare the dateRanges
			local comp = compareDateRanges(range,itemText)
			if comp == 1 then
				-- Ranges are same, do nothing
				drFrame:Close()
				return true
			elseif comp==2 then
				-- range1 lies entirely before range2
				itemNum = prevItemNum
				break
			elseif comp==3 then
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2
				range = combineDateRanges(range,itemText)
				-- Delete the current item
				o.list:DeleteItem(itemNum)
				itemNum = prevItemNum
				break
			elseif comp==4 then
				-- comp=4 range1 lies entirely inside range2
				-- range given is subset, do nothing
				return true
			elseif comp==5 or comp==7 then
				-- comp=5 range1 post overlaps range2
				-- comp=7 range2 lies entirely inside range1
				range = combineDateRanges(range,itemText)
				-- Delete the current item
				o.list:DeleteItem(itemNum)
				itemNum = prevItemNum
				conditionList = true	-- To condition the list to merge any overlapping ranges
				break
			elseif comp==6 then
				-- range1 lies entirely after range2
				-- Do nothing look at next item
			else
				return nil
			end
			--print(range..">"..tostring(comp))
		end
		-- itemNum contains the item after which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		newItem:SetId(itemNum)
		newItem:SetText(range)
		o.list:InsertItem(newItem)
		o.list:SetItem(itemNum,0,range)
		
		-- Condition the list here if required
		while conditionList and o.list:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = o.list:GetNextItem(itemNum)
			local itemText = o.list:GetItemText(itemNum)
			-- Now compare the dateRanges
			local comp = compareDateRanges(range,itemText)
			if comp == 1 then
				-- Ranges are same, delete this itemText range
				o.list:DeleteItem(itemNum)
				itemNum = prevItemNum
			elseif comp==2 then
				 -- range1 lies entirely before range2
				 conditionList = nil
			elseif comp==3 then
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2
				range = combineDateRanges(range,itemText)
				-- Delete the current item
				o.list:DeleteItem(itemNum)
				itemNum = prevItemNum
				o.list:SetItemText(itemNum,range)
				conditionList = nil
			elseif comp==4 then
				-- comp=4 range1 lies entirely inside range2
				error("Code Error: This condition should never occur!",1)
			elseif comp==5 or comp==7 then
				-- comp=5 range1 post overlaps range2
				-- comp=7 range2 lies entirely inside range1
				range = combineDateRanges(range,itemText)
				-- Delete the current item
				o.list:DeleteItem(itemNum)
				itemNum = prevItemNum
				o.list:SetItemText(itemNum,range)
			elseif comp==6 then
				-- range1 lies entirely after range2
				error("Code Error: This condition should never occur!",1)
			else
				error("Code Error: This condition should never occur!",1)
			end				
		end		-- while conditionList and o.list:GetNextItem(itemNum) ~= -1 ends
		o.list:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)
    end		-- local addRange = function(range) ends
	
	local validateRange = function(range)
		-- Check if the given date range is valid
		-- Expected format is MM/DD/YYYY-MM/DD/YYYY here M and D can be single digits as well
		local _, _, im, id, iy, fm, fd, fy = string.find(range, "(%d+)/(%d+)/(%d%d%d%d+)%s*-%s*(%d+)/(%d+)/(%d%d%d%d+)")
		id = tonumber(id)
		im = tonumber(im)
		iy = tonumber(iy)
		fd = tonumber(fd)
		fm = tonumber(fm)
		fy = tonumber(fy)
		local ileap, fleap
		if not(id or im or iy or fd or fm or fy) then
			return false
		elseif not(id > 0 and id < 32 and fd > 0 and fd < 32 and im > 0 and im < 13 and fm > 0 and fm < 13 and iy > 0 and fy > 0) then
			return false
		end
		if fy < iy then
			return false
		end
		if iy == fy then
			if fm < im then
				return false
			end
			if im == fm then
				if fd < id then
					return false
				end
			end
		end 
		if iy%100 == 0 and iy%400==0 then
			-- iy is leap year century
			ileap = true
		elseif iy%4 == 0 then
			-- iy is leap year
			ileap = true
		end
		if fy%100 == 0 and fy%400==0 then
			-- fy is leap year century
			fleap = true
		elseif fy%4 == 0 then
			-- fy is leap year
			fleap = true
		end 
		--print(id,im,iy,fd,fm,fy,ileap,fleap)
		local validDate = function(leap,date,month)
			local limits = {31,28,31,30,31,30,31,31,30,31,30,31}
			if leap then
				limits[2] = limits[2] + 1
			end
			if limits[month] < date then
				return false
			else
				return true
			end
		end
		if not validDate(ileap,id,im) then
			return false
		end
		if not validDate(fleap,fd,fm) then
			return false
		end
		return true
	end
	
	local setRanges = function(o,ranges)
		for i = 1,#ranges do
			if validateRange(ranges[i]) then
				addRange(o,ranges[i])
			else
				error("Invalid Date Range given", 2)
			end
		end
	end
	
	local setCheckBoxState = function(o,state)
		o.CheckBox:SetValue(state)
	end
	
	local AddPress = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
		
		local addNewRange = function(range)
			addRange(o,range)
		end
		
		-- Create the frame to accept date range
		SelectDateRangeCtrl(o.parent,1,addNewRange)
	end
	
	local RemovePress = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
		local item = o.list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			selItems[#selItems + 1] = item	
			item = o.list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		for i=#selItems,1,-1 do
			o.list:DeleteItem(selItems[i])
		end
	end
	
	local ClearPress = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
		o.list:DeleteAllItems()	
	end
	
	local ResetCtrl = function(o)
		o.list:DeleteAllItems()
		if o.CheckBox then
			o.CheckBox:SetValue(false)
		end
	end
	
	local ListSel = function(event)
		setfenv(1,package.loaded[modname])
		local o = objMap[event:GetId()]
        if o.list:GetSelectedItemCount() == 0 then
			o.RemoveButton:Disable()
        	return nil
        end
		o.RemoveButton:Enable(true)
	end
	
	DateRangeCtrl = function(parent, noneSelection, heading)
		-- parent is a wxPanel
		if not parent then
			return nil
		end
		local o = {ResetCtrl = ResetCtrl, getSelectedItems = getSelectedItems, setRanges = setRanges}	-- new object
		o.parent = parent
		-- Create the GUI elements here
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)
		
		-- Heading
		local label = wx.wxStaticText(parent, wx.wxID_ANY, heading, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		o.Sizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- List Control
		local ID
		ID = NewID()
		o.list = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
		o.list:InsertColumn(0,"Ranges")
		objMap[ID] = o 
		o.list:InsertColumn(0,heading)
		o.Sizer:Add(o.list, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- none Selection check box
		if noneSelection then
			o.setCheckBoxState = setCheckBoxState
			ID = NewID()
			o.CheckBox = wx.wxCheckBox(parent, ID, "None Also passes", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			objMap[ID] = o 
			o.Sizer:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		end
		
		-- Add Date Range Button
		ID = NewID()
		o.AddButton = wx.wxButton(parent, ID, "Add Range", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.AddButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		objMap[ID] = o 

		-- Remove Date Range Button
		ID = NewID()
		o.RemoveButton = wx.wxButton(parent, ID, "Remove Range", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.RemoveButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		objMap[ID] = o 
		o.RemoveButton:Disable()
		
		-- Clear Date Ranges Button
		ID = NewID()
		o.ClearButton = wx.wxButton(parent, ID, "Clear Ranges", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.ClearButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		objMap[ID] = o 
		
		-- Associate Events
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)
		o.ClearButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,ClearPress)

		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,ListSel)
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,ListSel)
		
		return o
	end
	
end		-- DateRangeCtrl ends