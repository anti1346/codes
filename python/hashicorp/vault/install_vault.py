import os
import subprocess
import datetime

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
    install_packages(gpg)
    run_command("curl -s https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null")

    lsb_release = run_command("lsb_release -cs")
    run_command = (f"'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com {lsb_release} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list'")
    
    install_packages(["vault"])


