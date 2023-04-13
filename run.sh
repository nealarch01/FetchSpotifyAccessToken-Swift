#/bin/zsh
# check if "app" exists
if [ ! -f "app" ]; then
	echo "app not found. building.."
	./build.sh
fi
# run app
./app

