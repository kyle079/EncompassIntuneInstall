On Error Resume Next
Err.Clear

sSystemFolder = "C:\Windows\SysWow64"
sExecuteDir = "C:\Windows\SysWow64"
If Wscript.Arguments.Count > 0 Then
	sSystemFolder = Wscript.Arguments(0)
End If

If Wscript.Arguments.Count > 1 Then
	sExecuteDir = Wscript.Arguments(1)
End If

'WScript.Echo sSystemFolder
'WScript.Echo sExecuteDir

'******** Register prnadmin.dll file on client computer *******

Set WshShell = Wscript.CreateObject("Wscript.Shell")
WshShell.Run sSystemFolder & "\regsvr32 /s """ & sExecuteDir & "\Prnadmin.dll""",1,TRUE

'************** Create the port *******************************

dim oPort
dim oMaster

set oPort = CreateObject("Port.Port.1")
set oMaster = CreateObject("PrintMaster.PrintMaster.1")

oPort.PortName = "PDF"
oPort.PortType = 3
oMaster.PortAdd oPort

if Err.Number <> 0 then
	WScript.Echo Err.Description
end if
Err.Clear

'************** Change Encompass printer port *****************

strComputer = "."
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set colEncompassPrinters = objWMIService.ExecQuery("Select * from Win32_Printer where DeviceID = 'Encompass'")

For Each objPrinter in colEncompassPrinters
	objPrinter.PortName = "PDF"
	objPrinter.Put_
Next

if Err.Number <> 0 then
	WScript.Echo Err.Description
end if
Err.Clear