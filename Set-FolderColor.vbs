' Runs Set-FolderColor.ps1 with no console window. The context menu calls this instead of
' powershell.exe directly, because a console app always flashes a window before hiding it.
' Every argument is passed through unchanged.
Option Explicit
Dim sh, fso, script, args, a
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "Set-FolderColor.ps1")
args = ""
For Each a In WScript.Arguments
    args = args & " """ & a & """"
Next
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & script & """" & args, 0, False
