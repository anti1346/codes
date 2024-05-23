import os
import subprocess
import urllib.request
from pathlib import Path
import distro

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

# MySQL 사용자 생성
def create_mysql_user():
    if run_command("id mysql").returncode != 0:
        if run_command("getent group mysql").returncode != 0:
            run_command("sudo groupadd -r mysql")
        run_command("sudo useradd -M -N -g mysql -o -r -d {} -s /bin/false -c 'MySQL Server' -u 27 mysql".format(MYSQL_INSTALL_DIR))

# 필수 라이브러리 설치
def install_libraries():
    distro_id = distro.id()
    if distro_id == 'ubuntu':
        run_command("sudo apt-get update")
        run_command("sudo apt-get install -y libncurses5 libaio1 libnuma1")
    elif distro_id == 'centos':
        run_command("sudo yum install -y ncurses-compat-libs libaio numactl")
    else:
        print("Unsupported package manager.")
        exit(1)

# MySQL 패키지 다운로드 및 설치
def download_and_install_mysql():
    mysql_package_path = Path(WORK_DIR) / MYSQL_PACKAGE
    if mysql_package_path.is_file():
        print(f"{mysql_package_path} already exists, skipping download.")
    else:
        urllib.request.urlretrieve(f"{MYSQL_DOWNLOAD_URL}/{MYSQL_PACKAGE}", mysql_package_path)
        print(f"Downloaded {MYSQL_PACKAGE} to {mysql_package_path}")

    os.makedirs(f"{MYSQL_INSTALL_DIR}/data", exist_ok=True)
    run_command(f"sudo tar xf {mysql_package_path} -C {MYSQL_INSTALL_DIR} --strip-components=1")
    run_command(f"sudo chown -R mysql:mysql {MYSQL_INSTALL_DIR}")

# MySQL 환경 변수 등록
def setup_mysql_environment():
    bashrc_path = Path.home() / ".bashrc"

    with open(bashrc_path, "r") as bashrc:
        content = bashrc.read()

    if f"{MYSQL_INSTALL_DIR}/bin" not in content:
        with open(bashrc_path, "a") as bashrc:
            bashrc.write(f"\nexport PATH={MYSQL_INSTALL_DIR}/bin:$PATH\n")










create_mysql_user()
install_libraries()
# download_and_install_mysql()
setup_mysql_environment()
