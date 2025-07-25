#!/bin/sh

set -ex

export ARCH=$(uname -m)
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
export URUNTIME_PRELOAD=1 # really needed here

tarball_url=https://icecatbrowser.org$(wget https://icecatbrowser.org/all_downloads.html -O - \
	| tr '"><' '\n' | grep -i "linux-x86_64.tar.bz2$" | head -1)

export VERSION=$(echo "$tarball_url" | awk -F'/' '{print $(NF-1); exit}')
echo "$VERSION" > ~/version

wget "$tarball_url" -O ./package.tar.bz2
tar xvf ./package.tar.bz2
rm -f ./package.tar.bz2

mv -v ./icecat ./AppDir && (
	cd ./AppDir
	cp -v ./browser/chrome/icons/default/default128.png ./icecat.png
	cp -v ./browser/chrome/icons/default/default128.png ./.DirIcon

	cat > ./AppRun <<- 'KEK'
	#!/bin/sh
	CURRENTDIR="$(cd "${0%/*}" && echo "$PWD")"
	export PATH="${CURRENTDIR}:${PATH}"
	export MOZ_LEGACY_PROFILES=1          # Prevent per installation profiles
	export MOZ_APP_LAUNCHER="${APPIMAGE}" # Allows setting as default browser
	exec "${CURRENTDIR}/icecat" "$@"
	KEK
	chmod +x ./AppRun

	# disable automatic updates
	mkdir -p ./distribution
	cat >> ./distribution/policies.json <<- 'KEK'
	{
	  "policies": {
	    "DisableAppUpdate": true,
	    "AppAutoUpdate": false,
	    "BackgroundAppUpdate": false
	  }
	}
	KEK

	cat > ./icecat.desktop <<- 'KEK'
	# add desktop[ file
	[Desktop Entry]
	Name=IceCat
	GenericName=Web Browser
	Comment=Browse the World Wide Web
	Keywords=Internet;WWW;Browser;Web;Explorer
	Exec=icecat %u
	Icon=icecat
	Terminal=false
	X-MultipleArgs=false
	Type=Application
	MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;
	StartupNotify=true
	StartupWMClass=icecat
	Categories=Network;WebBrowser;
	Actions=new-window;new-private-window;safe-mode;

	[Desktop Action new-window]
	Name=New Window
	Exec=icecat --new-window %u

	[Desktop Action new-private-window]
	Name=New Private Window
	Exec=icecat --private-window %u

	[Desktop Action safe-mode]
	Name=Safe Mode
	Exec=icecat -safe-mode %u
	KEK
)

wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" ./AppDir
