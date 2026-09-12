; 思谛 STDeel — Windows 安装器（Inno Setup）
; 用法：iscc /DMyAppVersion=0.7.0 /DReleaseDir="<绝对路径>" scripts/windows_installer.iss
; 源码目录：build/windows/x64/runner/Release/（flutter build windows --release 产物）
; 输出：build/windows/installer/stdeel-setup-<版本号>.exe

#ifndef MyAppVersion
  #define MyAppVersion "0.7.0"
#endif

#ifndef ReleaseDir
  #define ReleaseDir "..\..\build\windows\x64\runner\Release"
#endif

#ifndef ChineseMessages
  #define ChineseMessages "languages\ChineseSimplified.isl"
#endif

#ifndef SetupIcon
  #define SetupIcon "..\windows\runner\resources\app_icon.ico"
#endif

#define MyAppName "思谛 STDeel"
#define MyAppPublisher "STDeel"
#define MyAppExeName "stdeel.exe"
#define MyAppId "A1B2C3D4-5E6F-4A5B-8C9D-0E1F2A3B4C5D"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\STDeel
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\windows\installer
OutputBaseFilename=stdeel-setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 安装器图标（与 App 图标一致）
SetupIconFile={#SetupIcon}
; 桌面快捷方式与开始菜单
PrivilegesRequired=admin

[Languages]
; 中文简体（messages 文件随仓库 scripts/languages 维护，workflow 以绝对路径传入）
Name: "chinesesimplified"; MessagesFile: "{#ChineseMessages}"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; 全部 Release 产物（exe + dll + flutter_assets + data）
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
