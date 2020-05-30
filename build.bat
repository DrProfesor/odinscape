@echo off

rem USAGE: `build [run/release] [server]`

echo Copying dlls...
xcopy /s/q/y src\includes\windows . > NUL

echo Building src...
if "%2" == "server" (
	if "%1" == "debug" (
		odin build src -debug -out=odinscape.exe -define:HEADLESS=true
	) else (
		odin build src -out=odinscape.exe -define:HEADLESS=true
	)
) else (
	if "%1" == "debug" (
		odin build src -debug -out=odinscape.exe -define:HEADLESS=false
	) else (
		odin build src -out=odinscape.exe -define:HEADLESS=false
	)
)

if "%1" == "debug" (
	devenv odinscape.exe
)
if "%1" == "run" (
	echo Running odinscape.exe...
	odinscape.exe

	del *.dll
	del *.exe
)
if "%1" == "release" (
	echo Making release folder...
	
	if "%2" == "server" (
		if exist release-server rmdir /S/Q release-server
		mkdir release-server
		mkdir "release-server/resources"
	) else (
		if exist release rmdir /S/Q release
		mkdir release
		mkdir "release/resources"
	)

	echo Copying exe and resources...

	if "%2" == "server" (
		xcopy "*.dll" "release-server" /c/y/q > NUL
		copy "odinscape.exe" "release-server/odinscape.exe" > NUL
		xcopy /s/q "resources" "release-server/resources" > NUL
	) else (
		xcopy "*.dll" "release" /c/y/q > NUL
		copy "odinscape.exe" "release/odinscape.exe" > NUL
		xcopy /s/q "resources" "release/resources" > NUL
	)

	del *.dll
	del *.exe
)