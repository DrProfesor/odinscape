@echo off

rem echo Running prebuild...
odin run builder -out=builder.exe
if exist builder.exe del builder.exe

if exist tmp rmdir /S/Q tmp
mkdir tmp

if exist out rmdir /S/Q out
mkdir out

rem echo Copying libs and dlls...
xcopy /s/e/q includes\windows\libs tmp > NUL
xcopy /s/e/q includes\windows\runtime out > NUL
xcopy /s/e/q src tmp > NUL

rem echo Copying resources...
cd out
mkdir fonts
mkdir Resources
cd ..

xcopy /s/e/q fonts out\fonts > NUL
xcopy /s/e/q Resources out\Resources > NUL

cd tmp
odin build .

ren tmp.exe odinscape.exe
xcopy /q odinscape.exe ..\out > NUL

cd ..\out
.\odinscape.exe
cd ..
rmdir /s/q tmp