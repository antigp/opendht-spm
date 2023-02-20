#!/bin/zsh
set -x #echo on
set -e

PLATFORMS=("iPhoneSimulator" "iPhoneOS" "MacOSX")
declare -A ARCHS
ARCHS=(
  ["iPhoneSimulator"]="x86_64 arm64"
  ["iPhoneOS"]="arm64"
  ["MacOSX"]="x86_64 arm64"
)

declare -A SDKFLAGS
SDKFLAGS=(
  ["iPhoneSimulator"]="-mios-simulator-version-min=14.0"
  ["iPhoneOS"]="-mios-version-min=14.0"
  ["MacOSX"]="-mmacosx-version-min=12.0"
)


#=================================================================================
#
# You can change values here
#=================================================================================
# Architectures array
# ARCHS=("x86_64" "arm64" "i386" "armv7" "armv7s")


# SDK versions array
SDKVERSION="" #latest

#=================================================================================
#
# You shouldn't need to change values here
#=================================================================================
OGINCLUDE="$ORIGINALPATH/include/"

mkdir -p $OGINCLUDE
mkdir -p $OGLIB
mkdir -p $CURRENTPATH

#mkdir -p "${CURRENTPATH}/build"
mkdir -p "${CURRENTPATH}/include"
mkdir -p "${CURRENTPATH}/lib"
mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/tar"
mkdir -p "${CURRENTPATH}/usr"
mkdir -p "${CURRENTPATH}/lipo"
cd "${CURRENTPATH}/tar"


if [ "$COMPRESSIONTYPE" = "github" ]; then
	if [ ! -e "master.zip" ]; then
	        echo "  📞  Downloading ${REMOTEURLROOT} from Github."
	        curl -O -L $REMOTEURLROOT
	else
	        echo "  📦  Using existing master.zip"
	fi

	echo "    📦 Extracting files..."
	unzip -o master.zip -d ${CURRENTPATH}/src/
else 
	FILENAME="${FILENAMEBASE}-${LIBVERSION}.tar.${COMPRESSIONTYPE}"
	if [ ! -e $FILENAME ]; then
	        echo "  📞  Downloading ${FILENAME}"
	        REMOTEFILE="${REMOTEURLROOT}${FILENAME}"
	        curl -O -L $REMOTEFILE
	else
	        echo "  📦  Using ${FILENAME}"
	fi

	echo "    📦 Extracting files..."
	tar zxf $FILENAME -C ${CURRENTPATH}/src/
fi
# xcodebuild -create-xcframework -library libcombined.dylib -headers path/to/headers/directory -output output.xcframework
XCFRAMEWORK_CREATE="xcodebuild -create-xcframework"
# XCFRAMEWORK_CREATE2="xcodebuild -create-xcframework"
echo "  🚨  Beginning to build all for ${LIBNAME}"
echo "  🏛  PLATFORMS: ${PLATFORMS[@]}"

for PLATFORM in "${PLATFORMS[@]}"
do
	LIPO="lipo -create"
	LIPO2="lipo -create"
	HEADERS_XCFRAMEWORK=""
	unset PLATFORM_ARCHS
    PLATFORM_ARCHS=($(echo "${ARCHS[$PLATFORM]}"))
	echo "  🏛  BUILD PLATFORM: ${PLATFORM} - ${PLATFORM_ARCHS[*]}"
	for ARCH in "${PLATFORM_ARCHS[@]}"
	do
		echo "    🚀  COMPILING FOR ${PLATFORM}${SKDVERSION}-${ARCH}.sdk"
		OUTPUTPATH=${CURRENTPATH}/usr/${PLATFORM}${SDKVERSION}-${ARCH}.sdk
		mkdir -p "${OUTPUTPATH}"
		export PREFIX=${OUTPUTPATH}

		export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk
		#common toolchains for all platforms
		export DEVROOT=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr

		export CC=$DEVROOT/bin/cc
		export LD=$DEVROOT/bin/ld
		export CXX=$DEVROOT/bin/c++
		# alias
		export AS=$DEVROOT/bin/as
		# alt
		# export AS=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/libexec/as/x86_64/as

		export AR=$DEVROOT/bin/ar
		# alias
		export NM=$DEVROOT/bin/nm
		export ac_cv_func_malloc_0_nonnull=yes
		export ac_cv_func_realloc_0_nonnull=yes
		# alt
		# export NM="$DEVROOT/bin/nm -arch ${ARCH}"

	#	export CPP=$DEVROOT/bin/cpp
		export CPP="$DEVROOT/bin/clang -E"
	#	export CXXCPP=$DEVROOT/bin/cpp
		export CXXCPP="$DEVROOT/bin/clang -E"
		# alias as libtool
		export RANLIB=$DEVROOT/bin/ranlib

		# export TASN1_CFLAGS="-Ilibtasn1/include"
		# export TASN1_LIBS="-Llibtasn1 -ltasn1"

		export CC_FOR_BUILD="/usr/bin/clang -isysroot / -I/usr/include  -L${SDKROOT}/usr/lib -L${OUTPUTPATH}/lib  -I${OUTPUTPATH}/include -I${OUTPUTPATH}/include_global -I${SDKROOT}/usr/include -I${SDKROOT}/usr/include/c++ -I${SDKROOT}/usr/include/c++/v1 -I${SDKROOT}/usr/include/c++/v1/ext"
		export CBUILD="${CC_FOR_BUILD}"
		COMMONFLAGS="-arch ${ARCH} \
	${SDKFLAGS[$PLATFORM]} \
	-I${SDKROOT}/usr/include \
	-I${SDKROOT}/usr/include/c++ \
	-I${SDKROOT}/usr/include/c++/v1 \
	-I${SDKROOT}/usr/include/c++/v1/ext \
	-Wnonportable-include-path \
	-pipe \
	-O2 \
	-isysroot ${SDKROOT} "

		export LDFLAGS="$COMMONFLAGS -L${OUTPUTPATH}/lib -L${SDKROOT}/usr/lib"

		export CCASFLAGS="$COMMONFLAGS -I${OUTPUTPATH}/include -I${OUTPUTPATH}/include_global -I${SDKROOT}/usr/include"
		export CFLAGS="$COMMONFLAGS $C_STD -I${OUTPUTPATH}/include -I${OUTPUTPATH}/include_global -I${SDKROOT}/usr/include"
		export CXXFLAGS="$COMMONFLAGS $CPP_STD -I${OUTPUTPATH}/include -I${OUTPUTPATH}/include_global -I${SDKROOT}/usr/include"
		export M4FLAGS="-I${PREFIX}/include -I${SDKROOT}/usr/include"

		export CPPFLAGS="$COMMONFLAGS $CPP_STD -I${OUTPUTPATH}/include -I${OUTPUTPATH}/include_global -I${SDKROOT}/usr/include"

		cd ${CURRENTPATH}/src/$FILENAMEBASE*
		! make clean > /dev/null
		! make distclean > /dev/null

		echo "    ⚙  Configure..."
		echo "      📥  OUTPUTPATH: ${OUTPUTPATH}"

		if [ "$LIBNAME" = "libmsgpack" ]; then
			./bootstrap > /dev/null
		fi
		if [ "$LIBNAME" = "libasio" ]; then
			./autogen.sh > /dev/null
		fi
		HOST=""
		if [ "$ARCH" = "arm64" ]; then
			if [ "$PLATFORM_ARCHS" = "arm64" ]; then
				#Only arm64 has
				HOST="arm-apple-darwin"
			else	
				HOST="aarch64-apple-darwin"
			fi
		else
			HOST="x86_64-apple-darwin"
		fi
		CONFIGURE_ARGS="--prefix=${PREFIX} --host=${HOST} --disable-static --with-included-libtasn1  ${LIBFLAGS}"
		eval "./configure $CONFIGURE_ARGS"  # > /dev/null 2> /dev/null

		echo "    🛠  Build..."
		LIPO="$LIPO ${OUTPUTPATH}/lib/${LIBNAME}.dylib"
		HEADERS_XCFRAMEWORK="${OUTPUTPATH}/include_${LIBNAME}"

		if [ $SECONDARYLIB != "" ]; then
			LIPO2="${LIPO2} ${OUTPUTPATH}/lib/${SECONDARYLIB}.dylib"	
		fi
		make -j16 #> /dev/null 2> /dev/null
		! mv ${OUTPUTPATH}/include ${OUTPUTPATH}/include_global  > /dev/null 2> /dev/null
		! mkdir ${OUTPUTPATH}/include		 > /dev/null 2> /dev/null
		make install #> /dev/null 2> /dev/null
		# if [ "$LIBNAME" = "libasio" ]; then
		# 	./install-sh #> /dev/null 2> /dev/null
		# fi
		! rm -r ${OUTPUTPATH}/include_${LIBNAME}  > /dev/null 2> /dev/null
		! mv ${OUTPUTPATH}/include ${OUTPUTPATH}/include_${LIBNAME}  > /dev/null 2> /dev/null
		! mv ${OUTPUTPATH}/include_global ${OUTPUTPATH}/include  > /dev/null 2> /dev/null
		! mkdir ${OUTPUTPATH}/include  > /dev/null 2> /dev/null
		cp -r ${OUTPUTPATH}/include_${LIBNAME}/* ${OUTPUTPATH}/include		
		make clean > /dev/null 2> /dev/null
		cd ${CURRENTPATH}
	done


	# set the name of the framework
	FRAMEWORK_NAME="${FILENAMEBASE}"

	rm -rf "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework"
	# create the framework directory structure
	mkdir -p "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Headers"
	# mkdir -p "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Versions/A/Resources"
	touch "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Info.plist"

	PLATFORM_LOWER=$(echo $PLATFORM | tr '[:upper:]' '[:lower:]')
	PLATFORM_LOWER="$PLATFORM_LOWER"
	# write basic information to the Info.plist file
	cat > "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
				<key>CFBundleInfoDictionaryVersion</key>
				<string>6.0</string>
				<key>CFBundleName</key>
				<string>${FILENAMEBASE}</string>
        <key>CFBundleExecutable</key>
        <string>${LIBNAME}.dylib</string>
        <key>CFBundleIdentifier</key>
        <string>com.example.${FILENAMEBASE}</string>
        <key>CFBundleVersion</key>
        <string>1.0</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleName</key>
        <string>${FILENAMEBASE}</string>
        <key>CFBundlePackageType</key>
        <string>FMWK</string>
        <key>DTPlatformName</key>
				<string>${PLATFORM_LOWER}</string>
				<key>CFBundleShortVersionString</key>
				<string>1.0</string>
				<key>CFBundleSupportedPlatforms</key>
				<array>
					<string>${PLATFORM}</string>
				</array>
</dict>
</plist>
EOF

	# create the two dynamic libraries
	LIPO="$LIPO -output ${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib"
	if [ $SECONDARYLIB != "" ]; then
		LIPO2="$LIPO2 -output ${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib"
		eval "$LIPO2"
	fi
	eval "$LIPO"

	# create a symlink to the framework's current version
	# ln -s A "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Versions/Current"

	# create symlinks to the framework's headers and resources
	# ln -s Versions/Current/Headers "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Headers"
	# ln -s Versions/Current/Resources "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Resources"
	# ln -s Versions/Current/Resources/Info.plist "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Info.plist"

	# create a symlink to the framework's main dynamic library
	ln -s ${LIBNAME}.dylib "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
	# ln -s Versions/Current/${LIBNAME}.dylib "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib"
	# if [ $SECONDARYLIB != "" ]; then
	# 	ln -s Versions/Current/${SECONDARYLIB}.dylib "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib"
	# fi

	# set the install name of the dynamic libraries to the framework path
	install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib" "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib"
	install_name_tool -add_rpath @executable_path/../Frameworks/. "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib"
	if [ $SECONDARYLIB != "" ]; then
		install_name_tool -add_rpath @executable_path/../Frameworks/. "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib"
		install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib" "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib"
	fi

	# set the install names of the framework's main dynamic library and its dependencies to be relative to @rpath
	install_name_tool -change "${LIBNAME}.dylib" "@rpath/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib" "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${LIBNAME}.dylib"
	if [ $SECONDARYLIB != "" ]; then
		install_name_tool -change "${SECONDARYLIB}.dylib" "@rpath/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib" "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/${SECONDARYLIB}.dylib"
	fi
	cp -r $HEADERS_XCFRAMEWORK/* "${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework/Headers"

	XCFRAMEWORK_CREATE="${XCFRAMEWORK_CREATE} -framework ${CURRENTPATH}/frameworks/$PLATFORM/${FRAMEWORK_NAME}.framework"	
done

cd ${CURRENTPATH}
echo "  🍔  📚   Creating fat library..."
XCFRAMEWORKNAME="${CURRENTPATH}/lib/${FILENAMEBASE}.xcframework"
rm -rf $XCFRAMEWORKNAME
XCFRAMEWORK_CREATE="${XCFRAMEWORK_CREATE} -output $XCFRAMEWORKNAME"
echo "  👾  XCFRAMEWORK_CREATE command:  $XCFRAMEWORK_CREATE"
eval "$XCFRAMEWORK_CREATE"

# if [ $SECONDARYLIB != "" ]; then
# 	FATNAME2="${CURRENTPATH}/lib/${SECONDARYLIB}.xcframework"
# 	XCFRAMEWORK_CREATE2="${XCFRAMEWORK_CREATE2} -output $FATNAME2"
# 	echo "  👾  ${SECONDARYLIB} XCFRAMEWORK_CREATE command:  $XCFRAMEWORK_CREATE2"
# 	eval "$XCFRAMEWORK_CREATE2"
# 	cp $FATNAME2 $OGLIB
# fi

cp -r $XCFRAMEWORKNAME $OGLIB


cd $ORIGINALPATH

echo "🏁  🎁   Done with ${LIBNAME}.  🏁"
echo "🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹"
