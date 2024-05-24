import os
import subprocess
import urllib.request
import distro
import re
import pwd
import grp
from pathlib import Path
import shutil

# 설정 값 정의
MYSQL_VERSION = "8.0.37"
GLIBC_VERSION = "2.28"
MYSQL_DOWNLOAD_URL = f"https://dev.mysql.com/get/Downloads/MySQL-8.0"
MYSQL_PACKAGE = f"mysql-{MYSQL_VERSION}-linux-glibc{GLIBC_VERSION}-{os.uname().machine}.tar.xz"
WORK_DIR = "/tmp"
MYSQL_INSTALL_DIR = "/usr/local/mysql"
MY_CNF_PATH = f"{MYSQL_INSTALL_DIR}/my.cnf"
MY_CNF_URL = "https://raw.githubusercontent.com/anti1346/codes/main/python/mysql/my.cnf"
PASSWORD_FILE_PATH = f"{MYSQL_INSTALL_DIR}/mysql_password.txt"

# 명령어 실행 함수
def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error executing command: {command}")
        print(result.stderr)
    return result

# MySQL 사용자 및 그룹 생성
def create_mysql_user():
    user_exists = 'mysql' in (user.pw_name for user in pwd.getpwall())
    group_exists = 'mysql' in (group.gr_name for group in grp.getgrall())

    if not group_exists:
        run_command("sudo groupadd -r mysql")
    if not user_exists:
        run_command(f"sudo useradd -M -N -g mysql -o -r -d {MYSQL_INSTALL_DIR} -s /bin/false -c 'MySQL Server' -u 27 mysql")
        

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
    os.makedirs(f"{MYSQL_INSTALL_DIR}/log", exist_ok=True)
    os.chmod(f"{MYSQL_INSTALL_DIR}", 0o750)
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

# my.cnf 파일 작성
def write_my_cnf():
    response = urllib.request.urlopen(MY_CNF_URL)
    my_cnf_content = response.read().decode('utf-8')
    
    with open(MY_CNF_PATH, "w") as file:
        file.write(my_cnf_content)
    
    print(f"my_cnf written to {MY_CNF_PATH}")

# MySQL이 실행 중인지 확인
def is_mysql_running():
    try:
        result = subprocess.run(['pgrep', 'mysqld'], capture_output=True, text=True)
        return result.returncode == 0
    except Exception as e:
        print(f"An error occurred while checking MySQL status: {e}")
        return False

# MySQL 초기화 및 비밀번호 저장
def initialize_mysql():
    if is_mysql_running():
        print("MySQL is already running. Skipping initialization.")
        return

    print("Initializing MySQL...")
    shutil.rmtree(f"{MYSQL_INSTALL_DIR}/data")
    result = run_command(f"sudo {MYSQL_INSTALL_DIR}/bin/mysqld --defaults-file={MY_CNF_PATH} --initialize --user=mysql")
    if result.returncode == 0:
        temp_password = get_mysql_temp_password()
        if temp_password:
            with open(PASSWORD_FILE_PATH, "w") as file:
                file.write(f"Temporary MySQL root password: {temp_password}\n")
            print(f"Temporary MySQL root password saved to {PASSWORD_FILE_PATH}")
            start_mysql()
        else:
            print("Failed to find the temporary password in the error log.")
    else:
        print("Failed to initialize MySQL.")

# MySQL 서버 시작
def start_mysql():
    if is_mysql_running():
        print("MySQL is already running. Skipping start.")
        return

    print("Starting MySQL server...")
    command = f"sudo {MYSQL_INSTALL_DIR}/bin/mysqld_safe --defaults-file={MY_CNF_PATH} --user=mysql &"
    result = run_command(command)
    if result.returncode == 0:
        print("MySQL server started successfully.")
        exit(0)
    else:
        print("Failed to start MySQL server.")

# 임시 MySQL 비밀번호 가져오기
def get_mysql_temp_password():
    error_log_path = "/usr/local/mysql/log/error.log"
    with open(error_log_path, "r") as error_log:
        error_log_content = error_log.read()
        match = re.search(r"A temporary password is generated for root@localhost: (\S+)", error_log_content)
        if match:
            return match.group(1)
        else:
            return None

# MySQL 버전 확인
def check_mysql_version():
    result = run_command(f"{MYSQL_INSTALL_DIR}/bin/mysqld -V")
    print("\nMySQL Version\n---")
    print(result.stdout)

def main():
    create_mysql_user()
    install_libraries()
    download_and_install_mysql()
    write_my_cnf()
    setup_mysql_environment()
    initialize_mysql()
    start_mysql()
    check_mysql_version()

if __name__ == "__main__":
    main()
