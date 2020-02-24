#! /bin/bash

# must be run in the project directory
. ue_env.sh

# run test map and listen
"$ENGINE_ROOT/Engine/Binaries/Win64/UE4Editor-Cmd.exe" "$PROJECT_DIR/$PROJECT_NAME.uproject" -run=Cook -iterate -TargetPlatform=WindowsNoEditor -stdout -unattended -NoLogTimes -UTF8Output
