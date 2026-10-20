; Run `flutter build windows --release --dart-define=APP_ENV=prod` first: the
; installer version is read from the built app.exe (which comes from pubspec.yaml).
#define AppExe "build\windows\x64\runner\Release\app.exe"
#define FullVersion GetVersionNumbersString(AppExe)
; drop the 4th (build) number: 1.0.2.2 -> 1.0.2
#define AppVersion Copy(FullVersion, 1, RPos(".", FullVersion) - 1)

[Setup]
AppName=Auto Order Helper
AppVersion={#AppVersion}
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
