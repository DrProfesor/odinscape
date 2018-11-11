@echo off

odin run prebuild/

rmdir /S/Q tmp
mkdir tmp

rmdir /S/Q out
mkdir out

xcopy /s/e/q includes\windows\libs tmp
xcopy /s/e/q includes\windows\runtime out
xcopy /s/e/q src tmp

cd out
mkdir fonts
mkdir Resources
cd ..

xcopy /s/e fonts out\fonts
xcopy /s/e Resources out\Resources

cd tmp
odin build .

ren tmp.exe odinscape.exe
xcopy odinscape.exe ..\out

cd ..\out 
.\odinscape.exe
cd ..
rmdir /s/q tmp