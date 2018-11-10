cd prebuild
./odinscape_prebuild
cd ..

rm -rf tmp
mkdir tmp

rm -rf out
mkdir out

cp -rf includes/$1/libs/ tmp/
cp -rf src/ tmp/

cd tmp
odin run .