function change_dylib_dep {
	DYLIB_PATH=$1
	DYLIB_DEPS=$2
	current_deps=$(otool -X -L $DYLIB_PATH| awk '!x[$1]++')
	for dylib in $DYLIB_DEPS
	do 
		DEP=$(printf $dylib | sed -E sx\\.x\\\\.xg) #Escape dots in dylib name to include in regex
		original_path=$(echo $current_deps | egrep -o "\S*$DEP")
		echo "Replacing original path $original_path"
		install_name_tool -change $original_path /usr/local/lib/$dylib $DYLIB_PATH		 
	done
}

DIALOGS_BIN_PATH=pteiddialogsQTsrv.app/Contents/MacOS/pteiddialogsQTsrv

change_dylib_dep $DIALOGS_BIN_PATH "libpteiddialogsQT.2.dylib libpteidcommon.2.dylib"
change_dylib_dep fc-cache "libfreetype.6.dylib libfontconfig.1.dylib"

# The Qt frameworks are loaded from the Autenticação.gov app bundle
APP_FRAMEWORKS_DIR=${APP_FRAMEWORKS_DIR:-/Applications/Autenticação.gov.app/Contents/Frameworks}
for dep in $(otool -X -L $DIALOGS_BIN_PATH | awk '{print $1}' | grep '/Qt[A-Za-z0-9]*\.framework/')
do
	install_name_tool -change $dep "@rpath/$(echo $dep | sed -E 's#.*/(Qt[A-Za-z0-9]*\.framework/.*)#\1#')" $DIALOGS_BIN_PATH
done
for rpath in $(otool -l $DIALOGS_BIN_PATH | awk '/LC_RPATH/{getline; getline; print $2}')
do
	install_name_tool -delete_rpath "$rpath" $DIALOGS_BIN_PATH
done
install_name_tool -add_rpath "$APP_FRAMEWORKS_DIR/" $DIALOGS_BIN_PATH

otool -L fc-cache
otool -L $DIALOGS_BIN_PATH
