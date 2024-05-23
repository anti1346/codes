#!/bin/bash
# Chapter 4 Installing the MySQL Binary Package
# https://dev.mysql.com/doc/mysql-secure-deployment-guide/8.0/en/secure-deployment-install.html

MYSQL_VERSION=8.0.37
GLIBC_VERSION=2.28
MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/MySQL-8.0
MYSQL_PACKAGE=mysql-${MYSQL_VERSION}-linux-glibc${GLIBC_VERSION}-$(arch).tar.xz
WORK_DIR=/tmp
MYSQL_INSTALL_DIR=/usr/local/mysql

# MySQL 사용자 생성
if ! id "mysql" &>/dev/null; then
    if ! getent group mysql > /dev/null; then
        sudo groupadd -r mysql
    fi
    sudo useradd -M -N -g mysql -o -r -d ${MYSQL_INSTALL_DIR} -s /bin/false -c "MySQL Server" -u 27 mysql
fi

# 필수 라이브러리 설치
if [[ "$(command -v apt-get)" ]]; then
    sudo apt-get update
    sudo apt-get install -y libncurses5 libaio1 libnuma1
elif [[ "$(command -v yum)" ]]; then
    sudo yum install -y ncurses-compat-libs libaio numactl
else
    echo "Unsupported package manager."
    exit 1
fi

# MySQL 패키지 다운로드 및 설치
if [ ! -f ${WORK_DIR}/${MYSQL_PACKAGE} ]; then
    cd ${WORK_DIR}
    wget -q ${MYSQL_DOWNLOAD_URL}/${MYSQL_PACKAGE} -O ${MYSQL_PACKAGE}
fi

sudo mkdir -p ${MYSQL_INSTALL_DIR}/data

sudo tar xf ${WORK_DIR}/${MYSQL_PACKAGE} -C ${MYSQL_INSTALL_DIR} --strip-components=1

sudo chown -R mysql:mysql ${MYSQL_INSTALL_DIR}

# MySQL 환경 변수 등록
if ! grep -q "${MYSQL_INSTALL_DIR}/bin" ~/.bashrc; then
    echo -e "\nexport PATH=${MYSQL_INSTALL_DIR}/bin:\$PATH" >> ~/.bashrc
fi

# MySQL 버전 확인
echo -e "\nMySQL Version\n---"
${MYSQL_INSTALL_DIR}/bin/mysqld -V

