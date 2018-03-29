#!/bin/bash

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Message]${Font_color_suffix}"
Error="${Red_font_prefix}[ERROR]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"
Separator="-----------------------------------------"
Path="/etc/ffmpeg"
SOURCES="${Path}/sources"
Build_Path="${Path}/build"
PKG_CONFIG_PATH="${Build_Path}/lib/pkgconfig"
CC=clang
Ver="0.1"

[[ -e "${PWD}" ]] && mkdir -p ${PWD}
[[ -e "${SOURCES}" ]] && mkdir -p ${SOURCES}
[[ -e "${Build_Path}" ]] && mkdir -p ${Build_Path}

if [[ -n "$NUMJOBS" ]] ; then
	Core=$NUMJOBS
elif [[ -f /proc/cpuinfo ]] ; then
	Core=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]  ; then
	Core=$(sysctl -n machdep.cpu.thread_count)
else
	Core=2
fi

run(){
	echo "$ $*"
	if [[ ! $VERBOSE == "yes" ]]; then
		OUTPUT="$($@ 2>&1)"
	else
		$@
	fi
	
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo -e " ${Error} Faild to executed $*" >&2
        exit 1
    fi
}

Build(){
	echo ""
	echo -e " ${Tip} Building $1"
	echo -e " ${Separator}"
	if [ -f " ${SOURCES}/$1.lock" ] ; then
		echo " $1 already built. Remove ${SOURCES}/$1.lock lockfile to rebuild it."
		return 1
	fi
	return 0
}

Build_Done(){
	echo "done" >> ${SOURCES}/$1.lock
	echo -e " ${Tip} $1 has builded."
}

Welcome(){
	echo -e " This is ffmpeg build script.Ver ${Ver}."
	echo -e " Welcome to https://teduis.com/."
	echo -e " ${Separator}"
	echo ""
	echo " Using ${Core} make jobs simultaneously."
}

Check_Sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}

Sysinstall_Command(){
	if [[ ${release} == "centos" ]] ; then
		installcommand="yum -y install"
	elif [[ ${release} == "ubuntu" ]] ; then
		installcommand="apt-get -y install"
	elif [[ ${release} == "debian" ]] ; then
		installcommand="apt-get -y install"
	else
		echo "Can't install. Exiting..." && exit 1
	fi
}

Check_Command(){
	Makecheck=$( whereis make | awk '{print $2}' )
	[[ ! -n "${Makecheck}" ]] && echo -e " ${Tip} Make is not installed. \n Installing..." && Install=$(${installcommand} make)
	Gcccheck=$( whereis g++ | awk '{print $2}' )
	[[ ! -n "${Gcccheck}" ]] && echo -e " ${Tip} G++ is not installed. \n Installing..." && Install=$(${installcommand} gcc-c++) && Install=$(${installcommand} g++)
	Wgetcheck=$( whereis wget | awk '{print $2}' )
	[[ ! -n "${Wgetcheck}" ]] && echo -e "${Tip} Wget is not installed. \n Installing..." && Install=$(${installcommand} wget)
}

Build_Yasm(){
	[[ ! -e "${SOURCES}/Yasm" ]] && mkdir -p ${SOURCES}/Yasm
	Build "Yasm"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Yasm/yasm-1.3.0.tar.gz http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
	cd ${SOURCES}/Yasm
	tar -zxf yasm-1.3.0.tar.gz -C .
	cd ${SOURCES}/Yasm/yasm-1.3.0
	run ./configure --prefix=${Build_Path}
	run make -j ${Core}
	run make install
	ln -s /etc/ffmpeg/build/bin/yasm /usr/local/bin/yasm
	ln -s /etc/ffmpeg/build/bin/yasm /usr/bin/yasm
	Build_Done "Yasm"
}

Build_Opencore(){
	[[ ! -e "${SOURCES}/Opencore" ]] && mkdir -p ${SOURCES}/Opencore
	Build "Opencore"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Opencore/opencore-amr-0.1.5.tar.gz "http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.5.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fopencore-amr%2Ffiles%2Fopencore-amr%2F&ts=1442256558&use_mirror=netassist"
	cd ${SOURCES}/Opencore
	tar -zxf opencore-amr-0.1.5.tar.gz -C .
	cd ${SOURCES}/Opencore/opencore-amr-0.1.5
	run ./configure --prefix=${Build_Path} --disable-shared --enable-static
	run make -j ${Core}
	run make install
	Build_Done "Opencore"
}

Build_Libvpx(){
	[[ ! -e "${SOURCES}/Libvpx" ]] && mkdir -p ${SOURCES}/Libvpx
	Build "Libvpx"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Libvpx/libvpx-1.5.0.tar.gz https://github.com/webmproject/libvpx/archive/v1.5.0.tar.gz
	cd ${SOURCES}/Libvpx
	tar -zxf libvpx-1.5.0.tar.gz -C .
	cd ${SOURCES}/Libvpx/libvpx-1.5.0
	sed -e 's/cp -p/cp/' -i build/make/Makefile
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	Build_Done "Libvpx"
}

Build_Lame(){
	[[ ! -e "${SOURCES}/Lame" ]] && mkdir -p ${SOURCES}/Lame
	Build "Lame"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Lame/lame-3.99.5.tar.gz http://kent.dl.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
	cd ${SOURCES}/Lame
	tar -zxf lame-3.99.5.tar.gz -C .
	cd ${SOURCES}/Lame/lame-3.99.5
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	Build_Done "Lame"
}

Build_Xvidcore(){
	[[ ! -e "${SOURCES}/Xvidcore" ]] && mkdir -p ${SOURCES}/Xvidcore
	Build "Xvidcore"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Xvidcore/xvidcore-1.3.5.tar.gz http://downloads.xvid.org/downloads/xvidcore-1.3.5.tar.gz
	cd ${SOURCES}/Xvidcore
	tar -zxf xvidcore-1.3.5.tar.gz -C .
	cd ${SOURCES}/Xvidcore/xvidcore/build/generic
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	if [[ -f ${Build_Path}/lib/libxvidcore.4.dylib ]]; then
		run rm "${Build_Path}/lib/libxvidcore.4.dylib"
	fi
	Build_Done "Xvidcore"
}

Build_X264(){
	[[ ! -e "${SOURCES}/X264" ]] && mkdir -p ${SOURCES}/X264
	Build "X264"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/X264/last_x264.tar.bz2 ftp://ftp.videolan.org/pub/x264/snapshots/x264-snapshot-20170328-2245.tar.bz2
	cd ${SOURCES}/X264
	tar -jxf last_x264.tar.bz2 -C .
	cd ${SOURCES}/X264/x264-snapshot-*
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	run make install-lib-static
	Build_Done "X264"
}

Build_Libogg(){
	[[ ! -e "${SOURCES}/Libogg" ]] && mkdir -p ${SOURCES}/Libogg
	Build "Libogg"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Libogg/libogg-1.3.3.tar.gz https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.3.tar.gz
	cd ${SOURCES}/Libogg
	tar -zxf libogg-1.3.3.tar.gz -C .
	cd ${SOURCES}/Libogg/libogg-1.3.3
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	Build_Done "Libogg"
}

Build_Libvorbis(){
	[[ ! -e "${SOURCES}/Libvorbis" ]] && mkdir -p ${SOURCES}/Libvorbis
	Build "Libvorbis"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Libvorbis/libvorbis-1.3.6.tar.gz https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz
	cd ${SOURCES}/Libvorbis
	tar -zxf libvorbis-1.3.6.tar.gz -C .
	cd ${SOURCES}/Libvorbis/libvorbis-1.3.6
	run ./configure --prefix=${Build_Path} --disable-unit-tests --disable-shared
	run make -j ${Core}
	run make install
	Build_Done "Libvorbis"
}

Build_Libtheora(){
	[[ ! -e "${SOURCES}/Libtheora" ]] && mkdir -p ${SOURCES}/Libtheora
	Build "Libtheora"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Libtheora/libtheora-1.1.1.tar.gz https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-1.1.1.tar.gz
	cd ${SOURCES}/Libtheora
	tar -zxf libtheora-1.1.1.tar.gz -C .
	cd ${SOURCES}/Libtheora/libtheora-1.1.1
	sed "s/-fforce-addr//g" configure > configure.patched
	chmod +x configure.patched
	mv configure.patched configure
	run ./configure --prefix=${Build_Path} --with-ogg-libraries=${Build_Path}/lib --with-ogg-includes=${Build_Path}/include/ --with-vorbis-libraries=${Build_Path}/lib --with-vorbis-includes=${Build_Path}/include/ --enable-static --disable-shared --disable-oggtest --disable-vorbistest --disable-examples --disable-asm
	run make -j ${Core}
	run make install
	Build_Done "Libtheora"
}

Build_pkg_config(){
	[[ ! -e "${SOURCES}/pkg-config" ]] && mkdir -p ${SOURCES}/pkg-config
	Build "pkg-config"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/pkg-config/pkg-config-0.29.2.tar.gz http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
	cd ${SOURCES}/pkg-config
	tar -zxf pkg-config-0.29.2.tar.gz -C .
	cd ${SOURCES}/pkg-config/pkg-config-0.29.2
	run ./configure --silent --prefix=${Build_Path} --with-pc-path=${Build_Path}/lib/pkgconfig --with-internal-glib
	run make -j ${Core}
	run make install
	ln -s /etc/ffmpeg/build/bin/pkg-config /usr/local/bin/pkg-config
	ln -s /etc/ffmpeg/build/bin/pkg-config /usr/bin/pkg-config
	Build_Done "pkg-config"
}

Build_Cmake(){
	[[ ! -e "${SOURCES}/Cmake" ]] && mkdir -p ${SOURCES}/Cmake
	Build "Cmake"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Cmake/cmake-3.11.0-rc4.tar.gz https://cmake.org/files/v3.11/cmake-3.11.0-rc4.tar.gz
	cd ${SOURCES}/Cmake
	tar -zxf cmake-3.11.0-rc4.tar.gz -C .
	cd ${SOURCES}/Cmake/cmake-3.11.0-rc4
	rm Modules/FindJava.cmake
	perl -p -i -e "s/get_filename_component.JNIPATH/#get_filename_component(JNIPATH/g" Tests/CMakeLists.txt 
	perl -p -i -e "s/get_filename_component.JNIPATH/#get_filename_component(JNIPATH/g" Tests/CMakeLists.txt 
	run ./configure --prefix=${Build_Path}
	run make -j ${Core}
	run make install
	ln -s ${Path}/build/bin/cmake /usr/local/bin/cmake
	ln -s ${Path}/build/bin/cmake /usr/bin/cmake
	Build_Done "Cmake"
}

Build_Vid_stab(){
	[[ ! -e "${SOURCES}/Vid_stab" ]] && mkdir -p ${SOURCES}/Vid_stab
	Build "Vid_stab"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Vid_stab/vid.stab-0.98b-transcode-1.1-binary-x86_64.tgz https://codeload.github.com/georgmartius/vid.stab/legacy.tar.gz/release-0.98b
	cd ${SOURCES}/Vid_stab
	tar -zxf vid.stab-0.98b-transcode-1.1-binary-x86_64.tgz -C .
	cd ${SOURCES}/Vid_stab/georgmartius-vid*
	run cmake -DCMAKE_INSTALL_PREFIX:PATH=${Build_Path} . 
	run make install
	Build_Done "Vid_stab"
}

Build_X265(){
	[[ ! -e "${SOURCES}/X265" ]] && mkdir -p ${SOURCES}/X265
	Build "X265"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/X265/x265_2.7.tar.gz https://bitbucket.org/multicoreware/x265/downloads/x265_2.7.tar.gz
	cd ${SOURCES}/X265
	tar -zxf x265_2.7.tar.gz -C .
	cd ${SOURCES}/X265/x265_*
	cd source
	run cmake -DCMAKE_INSTALL_PREFIX:PATH=${Build_Path} -DENABLE_SHARED:bool=off . 
	run make install
	sed "s/-lx265/-lx265 -lstdc++/g" "${Build_Path}/lib/pkgconfig/x265.pc" > "${Build_Path}/lib/pkgconfig/x265.pc.tmp"
	mv "${Build_Path}/lib/pkgconfig/x265.pc.tmp" "${Build_Path}/lib/pkgconfig/x265.pc"
	Build_Done "X265"
}

Build_Fdk_aac(){
	[[ ! -e "${SOURCES}/Fdk_aac" ]] && mkdir -p ${SOURCES}/Fdk_aac
	Build "Fdk_aac"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Fdk_aac/fdk-aac-0.1.6.tar.gz https://jaist.dl.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-0.1.6.tar.gz
	cd ${SOURCES}/Fdk_aac
	tar -zxf fdk-aac-0.1.6.tar.gz -C .
	cd ${SOURCES}/Fdk_aac/fdk-aac*
	run ./configure --prefix=${Build_Path} --disable-shared --enable-static
	run make -j ${Core}
	run make install
	Build_Done "Fdk_aac"
}

Build_Ffmpeg(){
	[[ ! -e "${SOURCES}/Ffmpeg" ]] && mkdir -p ${SOURCES}/Ffmpeg
	Build "Ffmpeg"
	echo "Downloading Socure......"
	wget -qO ${SOURCES}/Ffmpeg/ffmpeg-3.4.2.tar.gz http://ffmpeg.org/releases/ffmpeg-3.4.2.tar.gz
	cd ${SOURCES}/Ffmpeg
	tar -zxf ffmpeg-3.4.2.tar.gz -C .
	cd ${SOURCES}/Ffmpeg/ffmpeg-3.4.2
	CFLAGS="-I${Build_Path}/include" LDFLAGS="-L${Build_Path}/lib"
	run ./configure --prefix=${Build_Path} --extra-cflags="-I${Build_Path}/include" --extra-ldflags="-L${Build_Path}/lib" \
		--extra-version=static \
		--extra-cflags=--static \
		--enable-static \
		--disable-debug \
		--disable-shared \
		--disable-ffplay \
		--disable-ffserver \
		--disable-doc \
		--enable-gpl \
		--enable-version3 \
		--enable-nonfree \
		--enable-pthreads \
		--enable-libvpx \
		--enable-libmp3lame \
		--enable-libtheora \
		--enable-libvorbis \
		--enable-libx264 \
		--enable-libx265 \
		--enable-runtime-cpudetect \
		--enable-libfdk-aac \
		--enable-avfilter \
		--enable-libopencore_amrwb \
		--enable-libopencore_amrnb \
		--enable-filters \
		--enable-libvidstab 
	run make -j ${Core}
	run make install
	INSTALL_FOLDER="/usr/bin"
	if [[ "$OSTYPE" == "darwin"* ]]; then
	INSTALL_FOLDER="/usr/local/bin"
	fi
	cp "${Build_Path}/bin/ffmpeg" "${INSTALL_FOLDER}/ffmpeg"
	cp "${Build_Path}/bin/ffprobe" "${INSTALL_FOLDER}/ffprobe"
	Build_Done "Ffmpeg"
}

Done(){
	[[ ! -s "${INSTALL_FOLDER}/ffmpeg" ]] && echo -e "${Error} Ffmpeg Build Failed. Exit." && exit 1
	echo -e " ${Info} Ffmpeg Install Success!"
	echo -e " ${Tip} Welcome to https://teduis.com to know more about scripts."
}

Progress(){
	Welcome
	Check_Sys
	Sysinstall_Command
	Check_Command
	Build_Yasm
	Build_Opencore
	Build_Libvpx
	Build_Lame
	Build_Xvidcore
	Build_X264
	Build_Libogg
	Build_Libvorbis
	Build_Libtheora
	Build_pkg_config
	Build_Cmake
	Build_Vid_stab
	Build_X265
	Build_Fdk_aac
	Build_Ffmpeg
	Done
}

Progress
