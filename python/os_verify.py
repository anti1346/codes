### OS 플랫폼 정보 API
# https://pypi.org/project/distro/
# pip install distro

import distro

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

print("다음 단계를 진행합니다.")
