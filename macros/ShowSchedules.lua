-- Macros always run in global environment. 
-- Always be careful not to pollute the global environment

-- Macro to show the date schedules in the Gantt Chart
Karm.GUI.taskTree.ShowActual = nil
-- Refresh the whole task Tree and Gantt Chart
Karm.GUI.fillTaskTree()
