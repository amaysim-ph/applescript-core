global std, config, retry, syseve, listUtil, kb
global TEST_CONNECTION_NAME

(*
	@Testing:
		Have a valid connection created with name: Docker MySQL 5
		A database called "crm" must exist
		A table called customers must exist.
*)
property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "sequel-ace-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: New Tab
		Manual: Get Front Tab
		Manual: Find Tab - Not Found, Found and Focus
		Manual: Find Table (DB not selected, selected)		
		Manual: Switch to Query
		
		Manual: Is Connected? (Connection Tab/Connected tab)
		Manual: Get Selected Text (Connection Tab, Non-Query Tab, None, Selected)			
		Manual: Get Editor Text (Connection Tab, Non-Query Tab, None, With Text)	
		Manual: Is Table Selected (Connection Tab, DB Not Selected, Table Not Selected, Happy)	
		Manual: Run Query
		
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		set sutTab to sut's newTab(TEST_CONNECTION_NAME)
		
	else if caseIndex is 2 then
		set sutTab to sut's getFrontTab()
		logger's infof("Tab Name: {}", name of appWindow of sutTab as text)
		
	else if caseIndex is 3 then
		set sut to sut's findTab(TEST_CONNECTION_NAME, "")
		if sut is missing value then
			logger's info("Tab was not found")
		else
			logger's info("Tab was found")
			sut's focus()
		end if
		
	else if caseIndex is 4 then
		logger's debugf("TEST_CONNECTION_NAME: {}", TEST_CONNECTION_NAME)
		set sut to sut's findTab(TEST_CONNECTION_NAME, "crm")
		assertThat of std given condition:sut is not missing value, messageOnFail:"Test Connection was not found"
		assertThat of std given condition:sut's findTable("phones") is false, messageOnFail:"Expected non existing phones table was found instead."
		assertThat of std given condition:sut's findTable("customers") is true, messageOnFail:"Expected existing customers table was not found."
		
	else if caseIndex is 5 then
		set sutTab to sut's getFrontTab()
		sutTab's switchTab("Query")
		sutTab's switchTab("Content")
		
		
	else if caseIndex is 6 then
		set frontTab to sut's getFrontTab()
		logger's infof("Is Connected: {}", frontTab's isConnected())
		
	else if caseIndex is 7 then
		set frontTab to sut's getFrontTab()
		logger's infof("Selected Text: {}", frontTab's getSelectedText())
		
	else if caseIndex is 8 then
		set frontTab to sut's getFrontTab()
		logger's infof("Editor Text: {}", frontTab's getEditorText())
		
	else if caseIndex is 9 then
		set frontTab to sut's getFrontTab()
		logger's infof("Is Table Selected: {}", frontTab's isTableSelected())
		
	else if caseIndex is 10 then
		set frontTab to sut's getFrontTab()
		frontTab's runQuery("SELECT '" & current date & "'")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	script SequelAceInstance
		(*  *)
		on findTab(connectionName, databaseAndOrTable)
			if running of application "Sequel Ace" is false then return missing value
			
			set titleKey to connectionName
			if databaseAndOrTable is not missing value and length of databaseAndOrTable is greater than 0 then set titleKey to titleKey & "/" & databaseAndOrTable
			logger's debugf("titleKey: {}", titleKey)
			
			tell application "System Events" to tell process "Sequel Ace"
				if (count of windows) is 0 then return missing value
				
				set frontWindowTitle to get title of front window
				logger's debugf("frontWindowTitle: {}", frontWindowTitle)
				if frontWindowTitle ends with titleKey then return my getFrontTab()
				
				if not (exists tab group "tab bar" of front window) then return missing value
				
				repeat with nextTab in radio buttons of tab group "tab bar" of front window
					set nextTabTitle to get title of nextTab
					logger's debugf("nextTabTitle: {}", nextTabTitle)
					if nextTabTitle ends with titleKey then
						click nextTab
						return my getFrontTab()
					end if
				end repeat
			end tell
			missing value
		end findTab
		
		
		on getFrontTab()
			if running of application "Sequel Ace" is false then return missing value
			
			tell application "Sequel Ace" to set frontWindow to front window
			new(frontWindow)
		end getFrontTab
		
		
		on newTab(connectionName)
			if running of application "Sequel Ace" is false then activate application "Sequel Ace"
			
			set frontTab to getFrontTab()
			if frontTab's isConnected() then
				tell application "System Events" to tell process "Sequel Ace"
					try
						click menu item "New Connection Tab" of menu 1 of menu bar item "File" of menu bar 1
					end try
					delay 1
				end tell
			end if
			
			tell application "System Events" to tell process "Sequel Ace"
				repeat with nextConnection in rows of outline 1 of scroll area 1 of splitter group 1 of front window
					try
						if get value of text field 1 of nextConnection is connectionName then
							set selected of nextConnection to true
							exit repeat
						end if
					end try -- text field don't exist
				end repeat
				click button "Connect" of scroll area 2 of splitter group 1 of front window
				delay 0.1
			end tell
			
			set frontTab to getFrontTab()
			repeat until frontTab's isConnected()
				delay 0.5
			end repeat
			delay 2 -- UI takes some time to refresh
			
			frontTab
		end newTab
		
		on new(pAppWindow)
			script SequelAceTabInstance
				property appWindow : pAppWindow -- non-sysEveWindow
				
				on isTableSelected()
					set windowName to name of appWindow
					set nameTokens to listUtil's split(windowName, "/")
					(the number of nameTokens) is greater than 2
				end isTableSelected
				
				on getEditorText()
					if running of application "Sequel Ace" is false then return missing value
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							set editorText to value of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow)
							if editorText is "" then return missing value
							return editorText
						end try -- Wrong tab
					end tell
					
					missing value
				end getEditorText
				
				
				on getSelectedText()
					if running of application "Sequel Ace" is false then return
					switchTab("Query")
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							set selectedStatement to value of attribute "AXSelectedText" of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of front window
							if selectedStatement is "" then return missing value
						on error -- when connection tab is focused
							return missing value
						end try
						
						return selectedStatement
					end tell
				end getSelectedText
				
				
				(* Warning: Uses key press to run the query, so maintain focus as needed. *)
				on runQuery(sqlStatement)
					if running of application "Sequel Ace" is false then return
					if isConnected() is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						set value of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow) to sqlStatement
						delay 0.1
						perform action "AXShowMenu" of (first menu button of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow) whose title starts with "Run")
					end tell
					
					
					kb's pressKey("down")
					kb's pressKey("enter")
				end runQuery
				
				
				on connectByName(targetConnectionName)
					if running of application "Sequel Ace" is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						set desiredConnection to missing value
						repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of window "Sequel Ace"
							try
								set nextConnectionName to value of text field 1 of nextRow
								if nextConnectionName contains targetConnectionName then
									set desiredConnection to nextRow
									exit repeat
								end if
							end try -- Fail on folder row
						end repeat
						if nextRow is not missing value then
							set selected of nextRow to true
							click button "Connect" of scroll area 2 of splitter group 1 of window "Sequel Ace"
							delay 1
						end if
					end tell
				end connectByName
				
				
				on focus()
					if running of application "Sequel Ace" is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							click (first menu item of first menu of menu bar item "Window" of first menu bar whose title is equal to name of my appWindow)
						on error
							return false
						end try
					end tell
				end focus
				
				
				on isConnected()
					if running of application "Sequel Ace" is false then return false
					
					focus()
					
					tell application "System Events" to tell process "Sequel Ace"
						if (count of windows) is 0 then return false
						
						not (exists button "Connect" of scroll area 2 of splitter group 1 of window "Sequel Ace")
					end tell
				end isConnected
				
				
				(* @returns true if the table is found. *)
				on findTable(targetTableName)
					script WaitTableSearch
						tell application "System Events" to tell process "Sequel Ace"
							if exists text field 1 of splitter group 1 of splitter group 1 of front window then return true
						end tell
					end script
					exec of retry on result for 5 by 1
					
					tell application "System Events" to tell process "Sequel Ace"
						-- Filter by Table Name. Broken because UI was updated, and the update was automatic!
						-- click button 2 of text field 1 of splitter group 1 of splitter group 1 of front window
						set value of text field 1 of splitter group 1 of splitter group 1 of front window to targetTableName
						-- click button 1 of text field 1 of splitter group 1 of splitter group 1 of front window
						
						-- Select the Table based on name
						repeat with nextTable in rows of table 1 of scroll area 1 of splitter group 1 of splitter group 1 of front window
							if get value of text field 1 of nextTable is equal to targetTableName then
								set selected of nextTable to true
								return true
								exit repeat
							end if
						end repeat
					end tell
					false
				end findTable
				
				
				(* @tabName - Structure, Content, Query, etc. *)
				on switchTab(tabName)
					if tabName is not equal to "Query" and isTableSelected() is false then
						logger's warn("Table must be selected")
						beep 1
						return
					end if
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							click button tabName of toolbar 1 of front window
						end try -- when button is not visible on small windows, for example the query.
					end tell
				end switchTab
			end script
		end new
	end script
end new


-- Private Codes below =======================================================



(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("sequel-ace")
	set retry to std's import("retry")'s new()
	set syseve to std's import("syseve")'s new()
	set listUtil to std's import("list")
	set kb to std's import("keyboard")'s new()
	
	set TEST_CONNECTION_NAME to "Docker MySQL 5"
end init