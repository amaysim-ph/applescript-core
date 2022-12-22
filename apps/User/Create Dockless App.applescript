global std, seLib, pots, retry, sessionPlist, switch, finder
global SCRIPT_NAME, IS_SPOT

(*
	This app picks up the current loaded file in Script Editor and creates a stay open app, the updates the plist file so that the app doesn't show in the dock while running.
	This app is created for menu-type stay open apps because doing it via 
	osacompile breaks the app.
	
	@Testing Notes
		Open the Menu Case.applescript and that will be used to test this script.
*)

use script "Core Text Utilities"
use scripting additions

property logger : missing value

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)

set std to script "std"
set logger to std's import("logger")'s new(SCRIPT_NAME)

if name of current application is "Script Editor" then set IS_SPOT to true

logger's start()

set seLib to std's import("script-editor")

set pots to std's import("pots")
set retry to std's import("retry")'s new()
set plutil to std's import("plutil")'s new()
set sessionPlist to plutil's new("session")

set switch to std's import("switch")
set finder to std's import("finder")

try
	main()
on error the errorMessage number the errorNumber
	std's catch(SCRIPT_NAME, errorNumber, errorMessage)
end try

logger's finish()


-- HANDLERS ==================================================================
on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to deploy the currently opened document in Script Editor")
		return
	end if
	
	if IS_SPOT then
		set seTab to seLib's findTabWithName("Menu Case.applescript")
		seTab's focus()
	else
		set seTab to seLib's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	sessionPlist's setValue("Last deployed script", baseScriptName)
	try
		logger's debugf("baseScriptName: {}", baseScriptName)
		do shell script "osascript -e 'tell application \"" & baseScriptName & "\" to quit'"
		logger's infof("App {} has been closed", baseScriptName)
	end try
	
	tell application "Finder"
		set targetFolderMon to folder "Stay Open" of folder "AppleScript" of finder's getApplicationsFolder() as text
	end tell
	
	logger's debugf("targetFolderMon: {}", targetFolderMon)
	
	set newScriptName to seTab's getBaseScriptName() & ".app"
	sessionPlist's setValue("New Script Name", newScriptName)
	
	set savedScript to seTab's saveAsStayOpenApp(targetFolderMon)
	logger's debugf("savedScript: {}", savedScript)
	
	-- Tab reference gets lost, so lets get the front tab.
	set frontTab to seLib's getFrontTab()
	set posixPath to frontTab's getPosixPath()
	logger's debugf("posixPath: {}", posixPath)
	logger's info("Updating Info.plist to hide menu app from dock...")
	do shell script (format {"defaults write '{}/Contents/Info.plist' LSUIElement -bool yes", posixPath})
	
	tell pots to speakSynchronously("Dockless stay open app deployed")
end main

