import os
import subprocess
import urllib.request
from pathlib import Path

# 설정 값
MYSQL_VERSION = "8.0.37"
GLIBC_VERSION = "2.28"
MYSQL_DOWNLOAD_URL = f"https://dev.mysql.com/get/Downloads/MySQL-8.0"
MYSQL_PACKAGE = f"mysql-{MYSQL_VERSION}-linux-glibc{GLIBC_VERSION}-{os.uname().machine}.tar.xz"
WORK_DIR = "/tmp"
MYSQL_INSTALL_DIR = "/usr/local/mysql"

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error executing commnad: {command}")
        print(result.stderr)
    return result

#MySQL 사용자 생성
def create_mysql_user():
    if run_command("id mysql").returncode != 0:
        if run_command("getent group mysql").returncode != 0:
            run_command("sudo group mysql")
        run_command("sudo useradd -M -N -g mysql -o -r -d {} -s /bin/false -c 'MySQL Server' -u 27 mysql".format(MYSQL_INSTALL_DIR))


create_mysql_user()
