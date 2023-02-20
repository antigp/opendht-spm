#!/bin/zsh

# Library name, version and location
LIBNAMES=("libgmp" "libnettle" "libtasn1" "libgnutls" "libmsgpackc")
FILENAMEBASES=("gmp" "nettle" "libtasn1" "gnutls" "msgpack" )
REMOTEURLROOTS=("https://ftp.gnu.org/gnu/gmp/" "http://www.lysator.liu.se/~nisse/archive/" "http://ftp.gnu.org/gnu/libtasn1/" "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/" "https://github.com/msgpack/msgpack-c/releases/download/cpp-1.3.0/" )
COMPRESSIONTYPES=("bz2" "gz" "gz" "xz" "gz")
LIBVERSIONS=("6.2.1" "3.8"  "4.7" "3.7.8" ".3.0" )
LIBFLAGSLIST=("--disable-assembly" "--disable-assembler --disable-arm-neon" "" "--without-p11-kit --with-included-unistring --without-brotli --without-idn --without-zstd --with-gnu-ld --disable-doc --disable-guile" ""  )
SECONDARYLIBS=("" "libhogweed" "" "libgnutlsxx" "" )
C_STD=""
CPP_STD=""

ORIGINALPATH=${PWD}
CURRENTPATH="${PWD}/staging"
OGLIB="$ORIGINALPATH/lib/"
mkdir -p $OGLIB
mkdir -p $CURRENTPATH


for (( i = 1 ; i <= ${#LIBNAMES[@]} ; i++ ))
do
	echo "🚧  🚧  🚧  🚧  🚧  🚧  🚧  🚧  🚧  🚧  🚧  🚧  "
	[ -e "${OGLIB}/${FILENAMEBASES[i]}.xcframework" ] && continue
	echo "🎯  Building target ${LIBNAMES[i]}"
	SECONDARYLIB=${SECONDARYLIBS[i]}
	LIBNAME=${LIBNAMES[i]}
	FILENAMEBASE=${FILENAMEBASES[i]}
	REMOTEURLROOT=${REMOTEURLROOTS[i]}
	COMPRESSIONTYPE=${COMPRESSIONTYPES[i]}
	LIBVERSION=${LIBVERSIONS[i]}
	LIBFLAGS=${LIBFLAGSLIST[i]}
	. ./build-generic.sh
done
