import os
import subprocess

def run_command(command, check=True):
    """명령어를 실행하고 결과를 출력합니다."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Command failed: {command}")
        print(result.stderr)
        exit(1)
    return result.stdout.strip()

def install_packages(packages):
    """주어진 패키지들을 설치합니다."""
    run_command("sudo apt-get update")
    for package in packages:
        run_command(f"sudo apt-get install -y {package}")

def install_vault():
    # 필요한 패키지 설치
    install_packages(["gpg", "lsb-release", "curl"])
    # HashiCorp GPG 키 추가
    run_command("curl -s https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null")
    # 배포판 코드네임 가져오기
    lsb_release = run_command("lsb_release -cs")
    # HashiCorp APT 리포지토리 추가
    run_command(f'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com {lsb_release} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list')
    # Vault 설치
    install_packages(["vault"])

def check_vault_version():
    """Vault 버전을 확인합니다."""
    result = run_command("vault --version")
    print(result)

if __name__ == "__main__":
    install_vault()
    check_vault_version()

