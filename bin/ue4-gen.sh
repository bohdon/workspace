#! /bin/bash

# must be run in the project directory
. ue_env.sh

# generate Visual Studio project
"$ENGINE_ROOT/Engine/Binaries/DotNET/UnrealBuildTool.exe" -projectfiles -project="$PROJECT_DIR/$PROJECT_NAME.uproject"
