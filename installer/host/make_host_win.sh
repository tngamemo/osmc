# (c) 2014 Sam Nazarko
# email@samnazarko.co.uk

# Pass Qt bin path in $1 - C:/MinGW/qt/qt-everywhere-opensource-src-4.8.6/bin
# Pass MinGW bin path in $2 - C:/MinGW/bin
# Run make win from MSYS

#!/bin/bash
echo Building host installer for Windows via MSYS
umount /qtbin >/dev/null 2>&1
umount /mgwbin >/dev/null 2>&1
echo -e "Mounting Qt binary directory..."
mount $1 /qtbin
if [ ! -f "/qtbin/qmake.exe" ]; then echo "Can't find Qt binaries!" && exit 1; fi
echo -e "Mounting MinGW32 binary directory..."
mount $2 /mgwbin
if [ ! -f "/mgwbin/mingw32-make.exe" ]; then echo "Can't find MinGW32 binaries" && exit 1; fi
if [ ! -f /c/Program\ Files/WinRAR/Rar.exe ]; then echo "Can't find WinRAR -- maybe it is in x64 program files" && exit 1; fi
echo -e "Updating PATH"
PATH="/qtbin:/mgwbin:/c/Program\ Files/Microsoft\ SDKs/Windows/v7.1/Bin:${PATH}"
TARGET="qt_host_installer"
ZLIB_VER="1.2.8"
pushd ${TARGET}
if [ -f Makefile ]; then echo "Cleaning Qt project" && mingw32-make clean; fi
pushd w32-lib/zlib-${ZLIB_VER}
make -f win32/Makefile.gcc clean
popd
echo Building zlib version ${ZLIB_VER}
pushd w32-lib/zlib-${ZLIB_VER}
make -f win32/Makefile.gcc
if [ $? != 0 ]; then echo "Building zlib failed" && exit 1; fi
popd
echo Building installer
qmake
mingw32-make
if [ $? != 0 ]; then echo "Building project failed" && exit 1; fi
strip release/${TARGET}.exe
echo Packaging installer
popd
INSTALL="install"
if [ -d ${INSTALL} ]; then echo "Cleaning old install directory " && rm -rf ${INSTALL}; fi
mkdir -p ${INSTALL}
cp ${TARGET}/release/${TARGET}.exe ${INSTALL}/
cp ${TARGET}/*.qm ${INSTALL}/ > /dev/null 2>&1
cp ${TARGET}/winrar.sfx ${INSTALL}
echo Building manifest
mt.exe –manifest ${TARGET}/${TARGET}.exe.manifest -outputresource:${INSTALL}/${TARGET}.exe;1
pushd ${INSTALL}
/c/Program\ Files/WinRAR/Rar.exe a -r -sfx -z"winrar.sfx" osmc-installer qt_host_installer.exe *.qm >/dev/null 2>&1
popd
mv ${INSTALL}/osmc-installer.exe .
rm -rf ${INSTALL}
umount /qtbin >/dev/null 2>&1
umount /mgwbin >/dev/null 2>&1
echo Build complete
