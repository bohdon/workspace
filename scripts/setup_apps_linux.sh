
echo "Installing Linux applications"

if should_install "All"; then
    INSTALL_ALL=true
fi

pkgs=""

if should_install "Docker Apt Sources"; then
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
fi

if should_install "Docker"; then
    pkgs="${pkgs} docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose"
fi

if should_install "Guake"; then
    pkgs="${pkgs} guake"
fi

if should_install "tree"; then
    pkgs="${pkgs} tree"
fi

if [[ $pkgs ]]; then
    set -x
    sudo apt-get update
    { set +x; } 2>/dev/null
fi

install_pkgs $pkgs
