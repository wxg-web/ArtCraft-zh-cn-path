param(
    [switch]$PrepareOnly,
    [string]$ArtCraftPath
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDirectory = Join-Path $scriptRoot 'bin'
$patchedExe = Join-Path $binDirectory 'ArtCraft-zh.exe'
$translatorScript = Join-Path $scriptRoot 'translator.mjs'
$settingsDirectory = Join-Path $scriptRoot 'settings'
$sourcePathFile = Join-Path $settingsDirectory 'artcraft-path.txt'
$port = 9333
$originalArguments = '--disable-features=msWebOOUI,msPdfOOUI,msSmartScreenProtection --autoplay-policy=no-user-gesture-required'
$debugArguments = '--remote-debugging-port=9333 --remote-allow-origins=* --autoplay-policy=no-user-gesture-required'

function Show-ErrorAndExit([string]$message) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($message, 'ArtCraft 中文版启动器', 'OK', 'Error') | Out-Null
    exit 1
}

function Save-ArtCraftPath([string]$path) {
    if (-not (Test-Path -LiteralPath $settingsDirectory)) {
        New-Item -ItemType Directory -Path $settingsDirectory | Out-Null
    }
    [System.IO.File]::WriteAllText($sourcePathFile, $path, [System.Text.UTF8Encoding]::new($false))
}

function Find-NodeExecutable {
    $candidates = @(
        (Join-Path $scriptRoot 'runtime\node.exe'),
        (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\nodejs\node.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    $command = Get-Command 'node.exe' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    return $null
}

function Find-ArtCraftExecutable {
    if ($ArtCraftPath -and (Test-Path -LiteralPath $ArtCraftPath)) {
        Save-ArtCraftPath $ArtCraftPath
        return $ArtCraftPath
    }

    if (Test-Path -LiteralPath $sourcePathFile) {
        $savedPath = [System.IO.File]::ReadAllText($sourcePathFile).Trim()
        if ($savedPath -and (Test-Path -LiteralPath $savedPath)) {
            return $savedPath
        }
    }

    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add((Join-Path (Split-Path -Parent $scriptRoot) 'ArtCraft\artcraft.exe'))
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\ArtCraft\artcraft.exe'))
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'ArtCraft\artcraft.exe'))
    $candidates.Add((Join-Path $env:ProgramFiles 'ArtCraft\artcraft.exe'))
    $candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'ArtCraft\artcraft.exe'))

    $registryRoots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($registryRoot in $registryRoots) {
        Get-ItemProperty -Path $registryRoot -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match '^ArtCraft' } |
            ForEach-Object {
                if ($_.InstallLocation) {
                    $candidates.Add((Join-Path $_.InstallLocation 'artcraft.exe'))
                }
                if ($_.DisplayIcon) {
                    $displayIcon = $_.DisplayIcon -replace '^"', '' -replace '",.*$', '' -replace ',\d+$', ''
                    if ($displayIcon -match '\.exe$') {
                        $candidates.Add($displayIcon)
                    }
                }
            }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            Save-ArtCraftPath $candidate
            return $candidate
        }
    }

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = '请选择已安装的 ArtCraft 程序'
    $dialog.Filter = 'ArtCraft (artcraft.exe)|artcraft.exe|可执行文件 (*.exe)|*.exe'
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        Show-ErrorAndExit "没有找到 ArtCraft。请先安装官方 ArtCraft 0.41.0，然后重新运行中文补丁。"
    }
    Save-ArtCraftPath $dialog.FileName
    return $dialog.FileName
}

$sourceExe = Find-ArtCraftExecutable
$nodeExe = Find-NodeExecutable

function Find-ByteSequence([byte[]]$haystack, [byte[]]$needle) {
    $start = 0
    $matches = [System.Collections.Generic.List[int]]::new()
    while ($start -le ($haystack.Length - $needle.Length)) {
        $index = [Array]::IndexOf($haystack, $needle[0], $start)
        if ($index -lt 0 -or $index -gt ($haystack.Length - $needle.Length)) {
            break
        }

        $matched = $true
        for ($offset = 1; $offset -lt $needle.Length; $offset++) {
            if ($haystack[$index + $offset] -ne $needle[$offset]) {
                $matched = $false
                break
            }
        }

        if ($matched) {
            $matches.Add($index)
        }
        $start = $index + 1
    }
    return $matches
}

if (-not $sourceExe -or -not (Test-Path -LiteralPath $sourceExe)) {
    Show-ErrorAndExit "未找到 ArtCraft 程序。"
}
if (-not $nodeExe) {
    Show-ErrorAndExit "未找到 Node.js 运行时。请重新解压完整补丁包，或安装 Node.js 22 以上版本。"
}
if (-not (Test-Path -LiteralPath $translatorScript)) {
    Show-ErrorAndExit "翻译脚本缺失：`n$translatorScript"
}
if (-not (Test-Path -LiteralPath $binDirectory)) {
    New-Item -ItemType Directory -Path $binDirectory | Out-Null
}

if (-not $PrepareOnly) {
    $running = Get-Process -Name 'artcraft', 'ArtCraft-zh' -ErrorAction SilentlyContinue
    if ($running) {
        Show-ErrorAndExit "请先完全退出正在运行的 ArtCraft，然后重新启动中文版。"
    }
}

$encoding = [System.Text.Encoding]::ASCII
$sourceBytes = [System.IO.File]::ReadAllBytes($sourceExe)
$needle = $encoding.GetBytes($originalArguments)
$positions = Find-ByteSequence $sourceBytes $needle
if ($positions.Count -ne 1) {
    Show-ErrorAndExit "当前 ArtCraft 版本的启动参数不兼容。预期找到 1 个 WebView2 参数块，实际找到 $($positions.Count) 个。"
}

$replacementText = $debugArguments.PadRight($originalArguments.Length, ' ')
if ($replacementText.Length -ne $originalArguments.Length) {
    Show-ErrorAndExit "中文启动参数与原程序不匹配。"
}
$replacement = $encoding.GetBytes($replacementText)
[Array]::Copy($replacement, 0, $sourceBytes, $positions[0], $replacement.Length)
[System.IO.File]::WriteAllBytes($patchedExe, $sourceBytes)

if ($PrepareOnly) {
    Write-Output $patchedExe
    exit 0
}

$logDirectory = Join-Path $scriptRoot 'logs'
if (-not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory | Out-Null
}
$translatorLog = Join-Path $logDirectory 'translator.log'
$translatorErrorLog = Join-Path $logDirectory 'translator-error.log'
$app = Start-Process -FilePath $patchedExe -WorkingDirectory (Split-Path -Parent $sourceExe) -PassThru
$translator = Start-Process -FilePath $nodeExe -ArgumentList @($translatorScript, '--port', $port) -WindowStyle Hidden -RedirectStandardOutput $translatorLog -RedirectStandardError $translatorErrorLog -PassThru

try {
    Wait-Process -Id $app.Id
} finally {
    if ($translator -and -not $translator.HasExited) {
        Stop-Process -Id $translator.Id -Force -ErrorAction SilentlyContinue
    }
}
