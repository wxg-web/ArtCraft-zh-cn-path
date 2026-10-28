Option Explicit

Dim shell, fileSystem, scriptDirectory, launcherPath, desktopDirectory, shortcut
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
launcherPath = fileSystem.BuildPath(scriptDirectory, "Launch ArtCraft Chinese.vbs")
desktopDirectory = shell.SpecialFolders("Desktop")

If Not fileSystem.FileExists(launcherPath) Then
  MsgBox "ArtCraft Chinese launcher was not found.", vbCritical, "ArtCraft Chinese"
  WScript.Quit 1
End If

Set shortcut = shell.CreateShortcut(fileSystem.BuildPath(desktopDirectory, "ArtCraft 中文版.lnk"))
shortcut.TargetPath = fileSystem.BuildPath(shell.ExpandEnvironmentStrings("%WINDIR%"), "System32\wscript.exe")
shortcut.Arguments = """" & launcherPath & """"
shortcut.WorkingDirectory = scriptDirectory
shortcut.Description = "Launch ArtCraft with a Simplified Chinese interface"
shortcut.Save

MsgBox "桌面快捷方式已创建。", vbInformation, "ArtCraft 中文版"
