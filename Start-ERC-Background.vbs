Dim fso, scriptFolder, WshShell
Set fso = CreateObject("Scripting.FileSystemObject")
scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)

Set WshShell = CreateObject("WScript.Shell")
' สั่งรัน PowerShell แบบซ่อนหน้าต่าง
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptFolder & "\Set-Background-ercs-sys.ps1""", 0
