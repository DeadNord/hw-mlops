#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="install.log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_docker() {
    if ! command_exists docker; then
        echo "Installing Docker..."
        apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        echo "Docker already installed: $(docker --version)"
    fi
}

install_docker_compose() {
    if ! command_exists docker-compose; then
        echo "Installing Docker Compose plugin..."
        apt-get update && apt-get install -y docker-compose-plugin
    else
        echo "Docker Compose already installed: $(docker-compose --version)"
    fi
}

install_python() {
    if command_exists python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)'; then
        echo "Python >=3.9 already installed: $(python3 --version)"
        if ! command_exists pip; then
            echo "Installing pip..."
            apt-get update && apt-get install -y python3-pip
        fi
    else
        echo "Installing Python 3.10 and pip..."
        apt-get update && apt-get install -y python3.10 python3-pip
        ln -sf /usr/bin/python3.10 /usr/local/bin/python3
    fi
}

install_pip_packages() {
    packages=(torch torchvision pillow django)
    for pkg in "${packages[@]}"; do
        if python3 -c "import ${pkg}" >/dev/null 2>&1; then
            echo "Python package ${pkg} already installed"
        else
            echo "Installing Python package ${pkg}"
            pip install --no-cache-dir ${pkg}
        fi
    done
}

main() {
    install_docker
    install_docker_compose
    install_python
    if command_exists pip; then
        install_pip_packages
    else
        echo "pip command not found, skipping Python package installation"
    fi

    echo "\nVersions:"
    docker --version || true
    docker-compose --version || true
    python3 --version || true
    pip --version || true
    python3 -c 'import torch, torchvision, PIL, django; print("torch", torch.__version__); print("torchvision", torchvision.__version__); print("Pillow", PIL.__version__); print("Django", django.get_version())'
}

main "$@"