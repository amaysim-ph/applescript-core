global std, retryLib

(*
	For the Assign to Desktop menu item to appear, there has to be more than one 
	Desktop "Spaces" available.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()
on spotCheck()
	init()
	set thisCaseId to "dock-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Assign to Desktop 1
		Assign to Desktop 2
		Assign to All
		Assign to None
		New Safari Window
		
		Position
		Vertical?
		Horizontal?
		Occupied Dock Width
		Occupied Dock Height
		
		Coordinates
		AutoHide
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set lib to new()
	set appName to "Script Editor"
	if running of application appName is false then
		activate application appName
		delay 1
	end if
	
	if caseIndex is 1 then
		set assignResult to lib's assignToDesktop(appName, 1)
		
	else if caseIndex is 2 then
		set assignResult to lib's assignToDesktop(appName, 2)
		
	else if caseIndex is 3 then
		set assignResult to lib's assignToDesktop(appName, "all")
		
	else if caseIndex is 4 then
		set assignResult to lib's assignToDesktop(appName, "none")
		
	else if caseIndex is 5 then
		activate application "Safari"
		log lib's newSafariWindow()
		
	else if caseIndex is 6 then
		logger's infof("Dock Position: {}", lib's getPosition())
		
	else if caseIndex is 7 then
		logger's infof("Is Vertical: {}", lib's isVertical())
		
	else if caseIndex is 8 then
		logger's infof("Is Horizontal: {}", lib's isHorizontal())
		
	else if caseIndex is 9 then
		logger's infof("Dock Width: {}", lib's getWidth())
		
	else if caseIndex is 11 then
		logger's infof("Coordinates: {}, {}", lib's getCoordinates())
		
	else if caseIndex is 12 then
		logger's infof("Is Autohide?: {}", lib's isAutoHide())
		
	else if caseIndex is 10 then
		logger's infof("Dock Height: {}", lib's getHeight())
		
	end if
	
	if caseIndex is less than 5 then
		logger's debugf("assignResult: {}", assignResult)
	end if
	
	if caseIndex is less than 5 and running of application appName and assignResult is true then
		delay 1.5
		-- Visually verify
		-- tell application "System Events" to key code 53
		tell application "System Events" to tell process "Dock"
			perform action "AXShowMenu" of UI element appName of list 1
			click menu item "Options" of first menu of UI element appName of list 1
		end tell
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	script DockInstance
		(*
			@returns bottom, left, or right
		*)
		on getPosition()
			tell application "System Events" to tell dock preferences
				screen edge
			end tell
		end getPosition
		
		on isVertical()
			not isHorizontal()
		end isVertical
		
		on isHorizontal()
			tell application "System Events" to tell dock preferences
				my getPosition() is bottom
			end tell
		end isHorizontal
		
		on getWidth()
			if isHorizontal() or isAutoHide() then return 0
			
			tell application "System Events" to tell application process "Dock"
				set theSize to size of first list
			end tell
			first item of theSize
		end getWidth
		
		on getHeight()
			tell application "System Events" to tell application process "Dock"
				set theSize to size of first list
			end tell
			second item of theSize
		end getHeight
		
		on getCoordinates()
			tell application "System Events" to tell application process "Dock"
				position of first list
			end tell
		end getCoordinates
		
		
		on isAutoHide()
			tell application "System Events" to tell dock preferences
				autohide
			end tell
		end isAutoHide
		
		
		on newSafariWindow()
			tell application "System Events" to tell process "Dock"
				if not (exists UI element "Safari" of list 1) then return false
				
				perform action "AXShowMenu" of UI element "Safari" of list 1
			end tell
			
			set retry to retryLib's new()
			script MenuWaiter
				tell application "System Events" to tell process "Dock"
					click menu item "New Window" of first menu of UI element "Safari" of list 1
					true
				end tell
			end script
			exec of retry on result for 3
			
			script BlankDocumentWaiter
				tell application "Safari"
					if (source of front document) is "" then return true
				end tell
			end script
			exec of retry on result for 3
		end newSafariWindow
		
		
		(* @deprecated. No longer available as of December 10, 2022
		@returns false if app is not found in the dock or the menu item is unavailable due to absence of external monitor. *)
		on assignToDesktop(appName, desktopIndex)
			if class of desktopIndex is integer then
				set subMenuName to "Desktop on Display " & desktopIndex
				
			else if desktopIndex is "all" then
				set subMenuName to "All Desktops"
				
			else if desktopIndex is "none" then
				set subMenuName to "None"
				
			end if
			
			tell application "System Events" to tell process "Dock"
				if not (exists UI element appName of list 1) then return false
				
				perform action "AXShowMenu" of UI element appName of list 1
				delay 0.2 -- Intermittently fails without this.
				click menu item "Options" of first menu of UI element appName of list 1
				delay 0.1
				try
					click menu item subMenuName of menu 1 of menu item "Options" of first menu of UI element appName of list 1
				on error
					key code 53
					return false
				end try
			end tell
			true
		end assignToDesktop
	end script
end new


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dock")
	set retryLib to std's import("retry")
end init
