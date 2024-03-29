#! /bin/bash

echo "Installing Windows nodejs environment"

if should_install "nodejs"; then
    choco install nodejs
fi
