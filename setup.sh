
cd $(dirname $0)

if [ "$(uname)" == "Darwin" ]; then
	echo "Installing Mac workspace"
	. install_mac.sh

elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
	echo "Installing Windows workspace"
	. install_win.sh

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	echo "Installing Linux workspace"
	. install_linux.sh
fi