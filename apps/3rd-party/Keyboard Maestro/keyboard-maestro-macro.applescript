global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "keyboard-maestro-macro-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: New Instance (Missing, Present)
		Manual: Enable Macro, get state
		Manual: Disable Macro, get state
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new("POC")
	if caseIndex is 1 then
		set sut to new("POC")
		try
			set sut to new("POCx")
		on error
			logger's info("Passed")
		end try
		
	else if caseIndex is 2 then
		sut's enable()
		logger's infof("Enabled: {}", sut's isEnabled())
		assertThat of std given condition:sut's isEnabled() is true, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 3 then
		sut's disable()
		logger's infof("Enabled: {}", sut's isEnabled())
		assertThat of std given condition:sut's isEnabled() is false, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	end if
	
	spot's finish()
	
	logger's finish()
end spotCheck


(*  *)
on new(pMacroName)
	set matchedMacro to missing value
	tell application "Keyboard Maestro"
		try
			set matchedMacro to first macro whose name is equal to pMacroName
		end try
	end tell
	
	if matchedMacro is missing value then error "The macro with the name: " & pMacroName & " was not found"
	
	script KeyboardMaestroMacroInstance
		property macroName : pMacroName
		property _macro : matchedMacro
		
		on disable()
			tell application "Keyboard Maestro"
				set enabled of _macro to false
			end tell
			
		end disable
		
		on enable()
			tell application "Keyboard Maestro"
				set enabled of _macro to true
			end tell
		end enable
		
		on isEnabled()
			tell application "Keyboard Maestro"
				enabled of _macro
			end tell
		end isEnabled
		
	end script
end new


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("keyboard-maestro-macro")
end init
