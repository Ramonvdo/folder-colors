' Runs one of this folder's PowerShell scripts with no console window. The context menu and
' the optional scheduled task call this instead of powershell.exe directly, because a console
' app always flashes a window before hiding it. First argument: the script, which must be one
' of the three below; every other argument is passed through unchanged.
Option Explicit
Dim sh, fso, here, script, args, i, allowed, ok
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
allowed = Array("Set-FolderColor.ps1", "Pick-FolderColor.ps1", "skills\organize-pc\scripts\Update-PcMap.ps1")
ok = False
If WScript.Arguments.Count > 0 Then
    For i = 0 To UBound(allowed)
        If LCase(WScript.Arguments(0)) = LCase(allowed(i)) Then ok = True
    Next
End If
If Not ok Then WScript.Quit 2
script = fso.BuildPath(here, WScript.Arguments(0))
args = ""
For i = 1 To WScript.Arguments.Count - 1
    args = args & " """ & WScript.Arguments(i) & """"
Next
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & script & """" & args, 0, False
