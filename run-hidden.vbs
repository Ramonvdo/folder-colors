' Runs one of this folder's PowerShell scripts with no console window. The context menu calls
' this instead of powershell.exe directly, because a console app always flashes a window before
' hiding it. First argument: the script file name; every other argument is passed through.
Option Explicit
Dim sh, fso, script, args, i
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), WScript.Arguments(0))
args = ""
For i = 1 To WScript.Arguments.Count - 1
    args = args & " """ & WScript.Arguments(i) & """"
Next
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & script & """" & args, 0, False
