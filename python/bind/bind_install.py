import os
import subprocess
import distro

# BIND 버전
bind_version = "9.18.26"

def get_linux_distribution():
    # 운영체제 정보 가져오기
    os_info = distro.id()
    return os_info

# 운영 체제 판단 및 업데이트
distro = get_linux_distribution()

if distro == "ubuntu":
    print(f"이 스크립트는 {distro.capitalize()}만 지원합니다.")
else:
    print(f"이 스크립트는 {distro.capitalize()}를 지원하지 않습니다.")
    exit(1)

# update_result = subprocess.run(['sudo', 'apt-get', 'update'])
# if update_result.returncode != 0:
#     print(f"APT 업데이트 실패")
#     exit(1)

# # 빌드 필수 패키지 설치
# required_packages = ['wget', 'build-essential', 'pkg-config', 'make']

# for package in required_packages:
#     install_result = subprocess.run(['sudo', 'apt-get', 'install', '-y', package])
#     if install_result.returncode != 0:
#         print(f"빌드 필수 패키지 '{package}' 설치 실패")
#         exit(1)

# # BIND 필수 패키지 설치
# required_packages = ['libssl-dev', 'libuv1-dev', 'libcap-dev', 'libjemalloc2', 'libjemalloc-dev', 'libnghttp2-dev']

# for package in required_packages:
#     install_result = subprocess.run(['sudo', 'apt-get', 'install', '-y', package])
#     if install_result.returncode != 0:
#         print(f"BIND 필수 패키지 '{package}' 설치 실패")
#         exit(1)

# # # 사용자 및 그룹 추가
# # subprocess.run(['sudo', 'adduser', '--system', '--home', '/var/named', '--no-create-home', '--disabled-login', '--disabled-password', '--group', 'named'])
# # named 계정이 있는지 확인
# check_user_command = subprocess.run(['getent', 'passwd', 'named'], capture_output=True, text=True)
# if check_user_command.returncode == 0:
#     print("named 계정이 이미 존재합니다.")
# else:
#     # 사용자 및 그룹 추가
#     subprocess.run(['sudo', 'adduser', '--system', '--home', '/var/named', '--no-create-home', '--disabled-login', '--disabled-password', '--group', 'named'])
#     print("named 계정을 추가했습니다.")

# # 디렉토리1 이동
# change_dir_result = os.chdir('/usr/local/src')
# if change_dir_result is None:
#     print("/usr/local/src 디렉토리 변경 성공")
# else:
#     print("/usr/local/src 디렉토리 변경 실패")
#     exit(1)

# # 소스코드 다운로드 및 압축 해제
# download_result = subprocess.run(['sudo', 'wget', f'https://ftp.isc.org/isc/bind9/{bind_version}/bind-{bind_version}.tar.xz'])
# if download_result.returncode != 0:
#     print("BIND 패키지 다운로드 실패")
#     exit(1)

# extract_result = subprocess.run(['tar', '-xf', f'bind-{bind_version}.tar.xz'])
# if extract_result.returncode != 0:
#     print("압축 해제 실패")
#     exit(1)

# # 디렉토리2 이동
# change_dir_result = os.chdir(f'bind-{bind_version}')
# if change_dir_result is None:
#     print(f"bind-{bind_version} 디렉토리 변경 성공")
# else:
#     print(f"bind-{bind_version} 디렉토리 변경 실패")
#     exit(1)

# # 빌드(configure) 및 컴파일
# configure_result = subprocess.run(['./configure', f'--prefix=/usr/local/named', '--sysconfdir=/etc', '--localstatedir=/var', '--with-openssl'])
# if configure_result.returncode != 0:
#     print("빌드(configure) 실패")
#     exit(1)

# make_result = subprocess.run(['make', '-j', str(int(subprocess.check_output(['nproc'])) // 2)])
# if make_result.returncode != 0:
#     print("컴파일 실패")
#     exit(1)

# # 설치
# install_result = subprocess.run(['sudo', 'make', 'install'])
# if install_result.returncode != 0:
#     print("설치 실패")
#     exit(1)

# # symbolic link 생성
# subprocess.run(['ln', '-s', '/usr/local/named/bin/named-checkconf', '/bin/named-checkconf'])
# subprocess.run(['ln', '-s', '/usr/local/named/bin/named-checkzone', '/bin/named-checkzone'])
# subprocess.run(['ln', '-s', '/usr/local/named/sbin/named', '/sbin/named'])
# subprocess.run(['ln', '-s', '/usr/local/named/sbin/named', '/sbin/rndc'])

# named.conf 파일 작성
named_conf_content = """
options {
  directory "/var/named";
  version "not currently available";
};

logging {
  channel example_log {
    file "log/example.log" versions 3 size 250k;
    severity info;
  };
  category default {
    example_log;
  };
};
"""
with open('/etc/named.conf', 'w') as file:
    file.write(named_conf_content)

# 로그 디렉토리 생성 및 권한 설정
subprocess.run(['mkdir', '-p', '/var/named/log'])
subprocess.run(['chown', 'named.named', '-R', '/var/named'])

# 라이브러리 경로를 ld.so.conf 파일에 추가
with open('/etc/ld.so.conf', "a") as file:
    file.write('/usr/local/named/lib' + "\n")

# systemd 서비스 파일 작성
systemd_service_content = """
[Unit]
Description=BIND DNS server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/named/sbin/named -f -c /etc/named.conf
ExecReload=/usr/local/named/sbin/rndc reload
ExecStop=/usr/local/named/sbin/rndc stop

[Install]
WantedBy=multi-user.target
"""
with open('/etc/systemd/system/named.service', 'w') as file:
    file.write(systemd_service_content)

# systemd 데몬 재로드 및 서비스 등록 및 시작
subprocess.run(['sudo', 'systemctl', 'daemon-reload'])
subprocess.run(['sudo', 'systemctl', 'enable', 'named'])
subprocess.run(['sudo', 'systemctl', 'start', 'named'])

status_result = subprocess.run(['sudo', 'systemctl', 'status', 'named'])
if status_result.returncode != 0:
    print("BIND 서비스 상태 확인 실패")
    exit(1)

print("BIND 설치 및 설정이 성공적으로 완료되었습니다.")
