-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to change the user ID operating Karm
-- Get the new user ID from the usr
local user = wx.wxGetTextFromUser("Enter the user ID (Blank to cancel)", "User ID", "")
-- Set the User ID variable if user provided input
if user ~= "" then
	Karm.Globals.User = user
	-- Set the UI title to include the user ID
	Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end											
