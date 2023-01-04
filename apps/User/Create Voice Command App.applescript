global std, usr, fileUtil, textUtil, syseve, emoji, sessionPlist, seLib, automator, configUser
global SCRIPT_NAME, IS_SPOT
global CURRENT_AS_PROJECT

(*
	@Requires:
		automator.applescript
		script-editor.applescript
		
	@Session:
		Sets the new app name into "New Script Name", for easy fetching when you set the permission after creation.
		Sets the most recent project key (Current AppleScript Project) for easier subsequent deployment.

	@Testing:
		Open the hello.applescript or your preferred script file for example.
		
	@Configurations
		Reads config-user.plist - AppleScript Projects		
*)

property logger : missing value

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)

set std to script "std"
set logger to std's import("logger")'s new(SCRIPT_NAME)


logger's start()

-- = Start of Code below =====================================================
set usr to std's import("user")'s new()
set fileUtil to std's import("file")
set textUtil to std's import("string")
set syseve to std's import("syseve")'s new()
set emoji to std's import("emoji")
set plutil to std's import("plutil")'s new()
set sessionPlist to plutil's new("session")
set seLib to std's import("script-editor")'s new()
set automator to std's import("automator")'s new()
set configUser to std's import("config")'s new("user")

set CURRENT_AS_PROJECT to "Current AppleScript Project"

set IS_SPOT to name of current application is "Script Editor"

try
	main()
on error the errorMessage number the errorNumber
	std's catch(me, errorNumber, errorMessage)
end try

logger's finish()
usr's done()


-- HANDLERS ==================================================================
on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to create an app for the currently opened document in Script Editor")
		return
	end if
	
	set thisAppName to text 1 thru ((offset of "." in SCRIPT_NAME) - 1) of SCRIPT_NAME
	if IS_SPOT then
		logger's info("Switching to a test file for to create voice command for")
		set seTab to seLib's findTabWithName("hello.applescript")
		if seTab is missing value then
			error "You must open the hello.applescript in Script Editor"
		end if
		seTab's focus()
	else
		set seTab to seLib's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	logger's infof("Base Script Name:  {}", baseScriptName)
	sessionPlist's setValue("New Script Name", baseScriptName & ".app")
	
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	set projectKeys to configUser's getValue("AppleScript Projects")
	if projectKeys is missing value then
		error "Project keys was not found in config-user.plist"
		return
	end if
	
	set currentAsProjectKey to sessionPlist's getString(CURRENT_AS_PROJECT)
	if currentAsProjectKey is missing value then
		set selectedProjectKey to choose from list projectKeys
	else
		set selectedProjectKey to choose from list projectKeys with title "Recent Project Key: " & currentAsProjectKey default items {currentAsProjectKey}
	end if
	
	if selectedProjectKey is false then
		logger's info("User canceled")
		return
	end if
	set selectedProjectKey to first item of selectedProjectKey
	
	logger's debugf("selectedProjectKey: {}", selectedProjectKey)
	sessionPlist's setValue(CURRENT_AS_PROJECT, selectedProjectKey)
	
	set projectPath to configUser's getValue(selectedProjectKey)
	set resourcePath to textUtil's replace(seTab's getPosixPath(), projectPath & "/", "")
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectDictationCommand()
		addAppleScriptAction()
		writeRunScript(selectedProjectKey, resourcePath)
		clickCommandEnabled()
		setCommandPhrase(baseScriptName)
		compileScript()
		
		set the clipboard to baseScriptName & " " & emoji's HORN
		if name of automator is "AutomatorInstance" then -- vanilla implementation has problem with programmatically setting the dictation command getting recognized by the Automator app.
			display dialog "User needs to continue the steps manually
			1. Set the Dictation Command by re-typing it.
			2. Save the app by pressing Cmd + S
			3. Paste the generated filename"
		else
			triggerSave()
			
			waitForSaveReady()
			enterScriptName(baseScriptName & " " & emoji's HORN)
			
			clickSave()
		end if
		
	end tell
end main
