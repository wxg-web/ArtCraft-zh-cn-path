Option Explicit

Dim shell, fileSystem, scriptDirectory, launcherPath, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
launcherPath = fileSystem.BuildPath(scriptDirectory, "start-artcraft-zh.ps1")

If Not fileSystem.FileExists(launcherPath) Then
  MsgBox "ArtCraft Chinese launcher was not found.", vbCritical, "ArtCraft Chinese"
  WScript.Quit 1
End If

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & launcherPath & """"
shell.Run command, 0, False
