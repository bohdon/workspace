#! /bin/bash

# must be run in the project directory
. ue_env.sh

# run test map and listen
"$ENGINE_ROOT/Engine/Binaries/Win64/UE4Editor.exe" "$PROJECT_DIR/$PROJECT_NAME.uproject" -game -log &
