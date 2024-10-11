#!/bin/bash

### Root Check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

### lsb_release 설치 함수
function install_lsb_release {
    if ! command -v lsb_release >/dev/null; then
        if command -v apt >/dev/null; then
            # Debian 계열
            apt-get update -qq >/dev/null 2>&1
            apt-get install -qq -y lsb-release >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            # RedHat 계열
            yum install -q -y redhat-lsb-core >/dev/null 2>&1
        else
            echo "Unsupported distribution for lsb_release installation"
            exit 1
        fi
    fi
}

#### 운영체제 판단 및 업데이트
function detect_os {
    if command -v apt >/dev/null; then
        # Debian 계열
        distro_name=$(lsb_release -is)
    elif command -v yum >/dev/null; then
        # RedHat 계열
        distro_name=$(lsb_release -is)
    else
        echo "Unsupported OS"
        exit 1
    fi

    os_major_version=$(lsb_release -rs | cut -d'.' -f1)
}

### Docker 설치 함수
function install_docker {
    if ! command -v docker >/dev/null; then
        case "$distro_name" in
            "CentOS")
                if [[ "$os_major_version" -eq 7 || "$os_major_version" -eq 8 ]]; then
                    echo "Installing Docker on CentOS $os_major_version"
                    curl -fsSL https://get.docker.com -o get-docker.sh || { echo "Failed to download Docker installation script"; exit 1; }
                    sudo chmod +x get-docker.sh
                    bash get-docker.sh
                    usermod -aG docker $(whoami)
                    systemctl --now enable docker.service
                else
                    echo "Unsupported CentOS version: $os_major_version"
                    exit 1
                fi
                ;;
            "Amazon")
                echo "Installing Docker on Amazon Linux $os_major_version"
                amazon-linux-extras install -y epel
                amazon-linux-extras install -y docker
                usermod -aG docker ec2-user
                systemctl --now enable docker.service
                ;;
            "Ubuntu")
                echo "Installing Docker on Ubuntu $os_major_version"
                apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt-get update
                apt-get install -y docker-ce
                ;;
            *)
                echo "Unsupported distribution: $distro_name"
                exit 1
                ;;
        esac
    else
        echo "Docker is already installed."
        if ! systemctl is-active --quiet docker; then
            echo "Starting Docker service..."
            systemctl start docker
        fi
        systemctl enable docker
    fi
}

### CTOP 설치 함수
function install_ctop {
    local ctop_version=${CTOP_VERSION:-0.7.7}
    local arch=$(dpkg --print-architecture)
    local ctop_url="https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-${arch}"
    # https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64
    
    if ! command -v ctop >/dev/null; then
        echo "Installing CTOP version $ctop_version"
        curl -fsSL "$ctop_url" -o /usr/local/bin/ctop || { echo "Failed to download CTOP"; exit 1; }
        chmod +x /usr/local/bin/ctop
    else
        echo "CTOP is already installed."
    fi
}

### 메인 스크립트 실행
install_lsb_release
detect_os
install_docker
install_ctop

### Clean up
echo "Cleaning up installation files"
rm -f get-docker.sh

echo "Installation completed successfully"

### 스크립트 종료
exit 0



### Shell Execute Command
# sed -i 's/\r$//' install_docker.sh
# curl -fsSL https://raw.githubusercontent.com/anti1346/zz/main/common/install_docker.sh | bash
# curl -fsSL https://raw.githubusercontent.com/anti1346/zz/main/common/install_docker.sh | dos2unix | bash
