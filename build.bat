@echo off

echo Running prebuild...
odin run builder -out=builder.exe
if exist builder.exe del builder.exe

if exist *.dll del *.dll
if exist *.exe del *.exe

echo Copying dlls...
xcopy /s/q/y includes\windows . > NUL

echo Building src...
odin build src -out=odinscape.exe

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
	copy "odinscape.exe" "release/odinscape.exe" > NUL
	xcopy /s/q "resources" "release/resources" > NUL
	xcopy "*.dll" "release" /c/y/q > NUL
)

del *.dll
del *.exe