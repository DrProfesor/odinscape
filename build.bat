@echo off

rem echo Running prebuild...
odin run builder -out=builder.exe
if exist builder.exe del builder.exe

if exist out rmdir /S/Q out
mkdir out

rem echo Copying libs and dlls...
xcopy /s/e/q includes\windows\runtime out > NUL

rem echo Copying resources...
cd out
mkdir fonts
mkdir Resources
cd ..

xcopy /s/e/q fonts out\fonts > NUL
xcopy /s/e/q Resources out\Resources > NUL

cd src
odin build . -out=odinscape.exe

xcopy /q odinscape.exe ..\out > NUL

cd ..\out
.\odinscape.exe
cd ..