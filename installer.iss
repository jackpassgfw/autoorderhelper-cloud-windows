[Setup]
AppName=Auto Order Helper
AppVersion=1.0.2
DefaultDirName={commonpf}\AutoOrderHelper
DefaultGroupName=Auto Order Helper
OutputDir=.
OutputBaseFilename=AutoOrderHelperSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Auto Order Helper"; Filename: "{app}\app.exe"
Name: "{commondesktop}\Auto Order Helper"; Filename: "{app}\app.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; Flags: unchecked
