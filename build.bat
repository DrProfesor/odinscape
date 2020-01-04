@echo off

rem USAGE: `build <run/release> [gameonly]`

echo Copying dlls...
xcopy /s/q/y src\includes\windows . > NUL

echo Building src...
if "%2" == "server" (
	odin build src -out=odinscape.exe -define:SERVER=true
) else (
	odin build src -out=odinscape.exe -define:SERVER=false
)


if "%1" == "run" (
	echo Running odinscape.exe...
	odinscape.exe
)
if "%1" == "release" (
	echo Making release folder...
	if exist release rmdir /S/Q release
	mkdir release
	mkdir "release/resources"

	echo Copying exe and resources...
	xcopy "*.dll" "release" /c/y/q > NUL
	copy "odinscape.exe" "release/odinscape.exe" > NUL
	xcopy /s/q "resources" "release/resources" > NUL
)

#del *.dll
#del *.exe