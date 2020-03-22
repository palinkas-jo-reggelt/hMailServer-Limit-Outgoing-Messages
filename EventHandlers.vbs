Function Lookup(strRegEx, strMatch) : Lookup = False
   With CreateObject("VBScript.RegExp")
      .Pattern = strRegEx
      .Global = False
      .MultiLine = True
      .IgnoreCase = True
      If .Test(strMatch) Then Lookup = True
   End With
End Function

Function oLookup(strRegEx, strMatch, bGlobal)
   If strRegEx = "" Then strRegEx = StrReverse(strMatch)
   With CreateObject("VBScript.RegExp")
      .Pattern = strRegEx
      .Global = bGlobal
      .MultiLine = True
      .IgnoreCase = True
      Set oLookup = .Execute(strMatch)
   End With
End Function

Function RemoveHTML(strText)
	Dim strRegEx, Match, Matches

	strRegEx = "<[^>]+>|&nbsp;|&lt;|&gt;|&quot;|&amp;|\s{2,}|v\\\:\*|o\\\:\*|w\\\:\*|\.shape|\{behavior:url\(\#default\#VML\)\;\}"
	Set Matches = oLookup(strRegEx, strText, False)
	For Each Match In Matches
	   strText = Replace(strText, Match.Value, " ")
	Next

	strRegEx = "[\s]{2,}"
	Set Matches = oLookup(strRegEx, strText, False)
	For Each Match In Matches
	   strText = Replace(strText, Match.Value, " ")
	Next

    RemoveHTML = strText
End Function

Function SendSMS(SMSNumber, sMSG)
	Dim rc, WshShell, strRegEx, Match, Matches, sMSGLen

	REM - put default mobile number here (administrator's number)
	If SMSNumber = Empty Then SMSNumber = "1234567890"

	sMSG = RemoveHTML(sMSG)

    REM - replace line breaks
	strRegEx = "(\r\n|\r|\n)"
	Set Matches = oLookup(strRegEx, sMSG, False)
	For Each Match In Matches
	   sMSG = Replace(sMSG, Match.Value, " ")
	Next
	
	REM - replace double/multiple spaces
	strRegEx = "([\s]{2,})"
	Set Matches = oLookup(strRegEx, sMSG, False)
	For Each Match In Matches
	   sMSG = Replace(sMSG, Match.Value, " ")
	Next

	sMSGLen = len(sMSG)

	Set WshShell = CreateObject("WScript.Shell")
	rc = WshShell.run( "cmd.exe /c gammu-smsd-inject -c C:\gammu\bin\smsdrc TEXT " & SMSNumber & " -len " & sMSGLen & " -text " & Chr(34) & sMSG & Chr(34), 0, True )
	Set WshShell = Nothing

	EventLog.Write( ":::::::::::::::: hMailServer automated SMS Forwarding Service ::::::::::::::::" )
	EventLog.Write( ":Error         : None" )
	EventLog.Write( ":Sent To       : " & SMSNumber )
	EventLog.Write( ":Message Length: " & sMSGLen )
	EventLog.Write( ":Message       : " & sMSG )
	EventLog.Write( ":                                                                            :" )
End Function

Sub GetTwoFactorInfo(ByVal s_Account, ByRef m_MobileNumber, ByRef m_LastLogon, ByRef m_LastLockTime)
	Dim oRecord, oConn : Set oConn = CreateObject("ADODB.Connection")
	oConn.Open "Driver={MariaDB ODBC 3.0 Driver}; Server=localhost; Database=hmailserver; User=hmailserver; Password=SSnGLBs8XswL2r0h;"

	If oConn.State <> 1 Then
		EventLog.Write( "Sub GetTwoFactorInfo - ERROR: Could not connect to database" )
		m_MobileNumber = "0"
		m_LastLogon = "1969-12-31 23:59:59"
		m_LastLockTime = "1969-12-31 23:59:59"
		Exit Sub
	End If

	m_MobileNumber = "0"
	m_LastLogon = "1969-12-31 23:59:59"
	m_LastLockTime = "1969-12-31 23:59:59"

	Set oRecord = oConn.Execute("SELECT mobilenumber, lastlogontime, lastlocktime FROM hm_accounts_mobile WHERE account = '" & s_Account & "';")
	Do Until oRecord.EOF
		m_MobileNumber = oRecord("mobilenumber")
		m_LastLogon = oRecord("lastlogontime")
		m_LastLockTime = oRecord("lastlocktime")
		oRecord.MoveNext
	Loop
	oConn.Close
	Set oRecord = Nothing
End Sub

Function SetSwitchOn(sAccount)
    Dim strSQL, oDB : Set oDB = GetDatabaseObject
    strSQL = "UPDATE hm_accounts_mobile SET accountlock=1, lastlocktime=NOW() WHERE account = '" & sAccount & "';"
    Call oDB.ExecuteSQL(strSQL)
    Set oDB = Nothing
End Function

Function UpdateLastLogon(sAccount)
    Dim strSQL, oDB : Set oDB = GetDatabaseObject
    strSQL = "UPDATE hm_accounts_mobile SET lastlogontime = NOW() WHERE account = '" & sAccount & "';"
    Call oDB.ExecuteSQL(strSQL)
    Set oDB = Nothing
End Function

Sub OnClientLogon(oClient)

	Dim strRegEx, sMSG, SMSNumber
	If oClient.Authenticated Then

		REM - Include domains you want to apply inactivity based two factor auth
		strRegEx = "@domain1\.com|@domain\.com|@domain3\.com"
		If Lookup(strRegEx, oClient.Username) Then

			REM - Two Factor Authentication - get variables
			Dim m_MobileNumber, m_LastLogon, m_LastLockTime
			Call GetTwoFactorInfo(oClient.Username, m_MobileNumber, m_LastLogon, m_LastLockTime)

			REM - If account is a real person, then begin two factor check
			If m_MobileNumber <> "0" Then
				Dim a : a = Split( oClient.Username, "@" )
				Dim AcctDomain : AcctDomain = Trim( CStr( a(1) ) )
				Dim A_Domain : A_Domain = UCase(Left(AcctDomain, 1)) &  Mid(AcctDomain, 2)
				Dim A_AcctCaps : A_AcctCaps = UCase(oClient.Username)

				REM - If last logon outside of interval, trip 2 factor
				REM - DateAdd can be one of the following: "yyyy" Year, "m" Month, "d" Day, "h" Hour, "n" Minute, "s" Second
				If (DateAdd("d", 7, m_LastLogon)) < Now() Then
					Call Disconnect(oClient.IPAddress)
					Call SetSwitchOn(oClient.Username)

					REM - Prevent redundant notifications
					If (DateAdd("n", 5, m_LastLockTime)) < Now() Then
						sMSG = "Message from " & A_Domain & " Mail Server: For security reasons and your safety, your account (" & oClient.Username & ") has been temporarily disabled. Reply UNLOCK to enable your account."
						Call SendSMS(m_MobileNumber, sMSG)
					End If
				Else
					REM - If last logon within interval, update logon time
					Call UpdateLastLogon(oClient.Username)
				End If
			End If
		End If

	Else
		'
		'	Whatever you want to do on UNsuccessful logon
		'
	End if
End Sub