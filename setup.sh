
if [ "$(uname)" == "Darwin" ]; then
	# Do something under Mac OS X platform
	echo "Setting up Mac workspace"
	. setup_mac.sh
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
	# Do something under Windows NT platform
	echo "Setting up Windows workspace"
	. setup_win.sh
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	# Do something under GNU/Linux platform
	echo "Setting up Linux workspace"
	. setup_linux.sh
fi