# หา Path ของโฟลเดอร์ปัจจุบันที่สคริปต์อยู่
$currentPath = $PSScriptRoot
# ระบุชื่อไฟล์รูปภาพให้ถูกต้อง (สมมติว่าไฟล์คือ Background.Access.sys)
$wallpaperPath = Join-Path -Path $currentPath -ChildPath "Background.Access.sys"

$code = @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type -TypeDefinition $code

while($true) {
    [Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)
    Start-Sleep -Seconds 1
}
