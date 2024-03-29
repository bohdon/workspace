#! /bin/bash

echo "Installing Windows python environment"

# install python
if should_install "Python 3.10"; then
    choco install python310 -y
fi

# install black and pre-commit
if should_install "black[d] and pre-commit"; then
    pip install black[d] pre-commit
fi

# install pycharm
if should_install "PyCharm"; then
    choco install pycharm-community -y
fi
