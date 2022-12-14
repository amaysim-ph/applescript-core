global std

(* 
	This library is a wrapper to a running process. Error is raised if the app don't exist upon instantiation of this component.
	
	Notes:
		Process is synonymous to app in this context.
		
	Testing Notes:
		Debug in logging must be on to see spot check object introspection.
		Have 3 Script Editor windows, this window plus 2 Untitled windows.
		
*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	logger's start()
	set caseId to "process-spotCheck"
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Inexistent App
		Manual: Terminate (Launch Automator). (Running/Not Running)
		Manual: Is Front Most (Running,Not Running)
		Manual: Move Window
		Manual: Resize Window
		
		Manual: First App Window(Running, Not Running, No Windows, With Window)
		Manual: App Windows(Running, Not Running, No Windows, With Window)
		Manual: Windows Matching Name(Running, Not Running)
		Manual: Windows Not Matching Name(Running, Not Running)
		Manual: Windows Equal Name(Running, Not Running)

		Manual: Windows Not Equal Name(Running, Not Running)
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	(* Common SUTs *)
	set scriptEditorApp to new("Script Editor")
	set notRunning to new("App Store")
	
	if caseIndex is 1 then
		try
			set sut to new("Pasadena")
		on error
			logger's info("Passed.")
		end try
		
	else if caseIndex is 2 then
		set sut to new("Automator")
		sut's terminate()
		
	else if caseIndex is 3 then
		logger's infof("isFrontMost-Script Editor: {}", scriptEditorApp's isFrontMost())
		logger's infof("isFrontMost-Terminal: {}", new("Terminal")'s isFrontMost())
		logger's infof("isFrontMost (Not Running): {}", notRunning's isFrontMost())
		
	else if caseIndex is 4 then
		scriptEditorApp's moveWindow(100, 100)
		
	else if caseIndex is 5 then
		scriptEditorApp's setFirstWindowDimension(500, 500)
		
	else if caseIndex is 6 then
		logger's logObj("First App Window", scriptEditorApp's getFirstWindow())
		
	else if caseIndex is 7 then
		set sutWindows to scriptEditorApp's getWindows()
		logger's logObj("Process Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)
		
	else if caseIndex is 8 then
		set sutWindows to scriptEditorApp's getWindowsMatchingName("Untitled")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Matched Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)
		
	else if caseIndex is 9 then
		set sutWindows to scriptEditorApp's getWindowsNotMatchingName("Untitled")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Unmatched Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)
		
	else if caseIndex is 10 then
		set sutWindows to scriptEditorApp's getWindowsEqualName("process.applescript")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Equalled Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)
		
	else if caseIndex is 11 then
		set sutWindows to scriptEditorApp's getWindowsNotEqualName("process.applescript")
		logger's logObj("Not Running: ", notRunning's getWindowsMatchingName("App"))
		logger's logObj("Not Equalled Windows: ", sutWindows)
		logger's infof("Window Count: {}", the number of sutWindows)
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck



on new(pProcessName)
	if std's appExists(pProcessName) is false then tell me to error "App: " & pProcessName & " could not be found."
	
	script ProcessInstance
		property processName : pProcessName
		
		
		(* @windowName is case-insensitive. *)
		on getWindowsMatchingName(windowName)
			if running of application processName is false then return missing value
			
			tell application "System Events" to tell process processName
				try
					return windows whose name contains windowName
				end try
			end tell
			
			missing value
		end getWindowsMatchingName
		
		
		on getWindowsNotMatchingName(windowName)
			if running of application processName is false then return missing value
			
			tell application "System Events" to tell process processName
				try
					return first window whose name does not contain windowName
				end try
			end tell
			
			missing value
		end getWindowsNotMatchingName
		
		
		on getWindowsEqualName(windowName)
			if running of application processName is false then return missing value
			
			tell application "System Events" to tell process processName
				try
					return windows whose name is equal to windowName
				end try
			end tell
			missing value
		end getWindowsEqualName
		
		
		on getWindowsNotEqualName(windowName)
			if running of application processName is false then return missing value
			
			tell application "System Events" to tell process processName
				try
					return windows whose name is not equal to windowName
				end try
			end tell
			missing value
		end getWindowsNotEqualName
		
		
		on getFirstWindow()
			if running of application processName is false then return missing value
			
			set appWindows to getWindows()
			if the number of appWindows is 0 then return missing value
			
			first item of appWindows
		end getFirstWindow
		
		
		on getWindows()
			if running of application processName is false then return missing value
			
			tell application "System Events" to tell process processName
				windows
			end tell
		end getWindows
		
		on hasWindows()
			if running of application processName is false then return false
			
			return the number of items in getWindows() is greater than 0
		end hasWindows
		
		
		on hasWindowsWithTitle(targetTitle)
			if running of application processName is false then return false
			
			return the number of items in getWindowsEqualName(targetTitle) is greater than 0
		end hasWindowsWithTitle
		
		
		on setFirstWindowDimension(w, h)
			if running of application processName is false then return
			
			tell application "System Events" to tell process processName
				try
					set size of first window to {w, h}
				end try
			end tell
		end setFirstWindowDimension
		
		
		on moveWindow(x, y)
			if running of application processName is false then return
			
			tell application "System Events" to tell process processName
				try
					set position of first window to {x, y}
				end try
			end tell
		end moveWindow
		
		(*  *)
		on terminate()
			if std's appExists(processName) is false then return
			if not running of application processName then return
			
			try
				tell application processName to quit
			on error
				try
					do shell script (format {"killall '{}'", processName})
				end try
			end try
			
			repeat while running of application processName is true
				delay 0.01
			end repeat
		end terminate
		
		on isFrontMost()
			if not running of application processName then return false
			
			tell application "System Events" to tell process processName
				frontmost
			end tell
		end isFrontMost
		
	end script
end new



-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("process")
end init

