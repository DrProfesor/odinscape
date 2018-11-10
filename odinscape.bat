@odin run prebuild/
mkdir tmp
mkdir out
xcopy /s includes/%2/libs/ tmp/
xcopy /s/e src/ tmp/
cd tmp
@odin run %1 .