import os
import subprocess

# 설정 값 정의
VAULT_VERSION = "1.16.2"
VAULT_DOWNLOAD_URL = "https://releases.hashicorp.com/vault"
WORK_DIR = "/tmp"
VAULT_INSTALL_DIR = "/usr/local/bin"
VAULT_CONF_DIR = "/etc/vault.d"
VAULT_ZIP_PATH = f"{WORK_DIR}/vault.zip"
CONFIG_HCL_PATH = f"{VAULT_CONF_DIR}/config.hcl"

# Vault 다운로드 및 설치
download_command = f"curl -fsSL {VAULT_DOWNLOAD_URL}/{VAULT_VERSION}/vault_{VAULT_VERSION}_linux_{os.uname().machine}.zip -o {VAULT_ZIP_PATH}"
subprocess.run(download_command, shell=True, check=True)

os.chdir(WORK_DIR)
subprocess.run("unzip vault.zip", shell=True, check=True)
subprocess.run(f"mv vault {VAULT_INSTALL_DIR}/", shell=True, check=True)

# Vault 설정 파일 생성
os.makedirs(f"{VAULT_CONF_DIR}/data", exist_ok=True)

with open(CONFIG_HCL_PATH, "w") as f:
    f.write(f"""
ui = true
disable_mlock = true

storage "raft" {{
  path    = "{VAULT_CONF_DIR}/data"
  node_id = "node1"
}}

listener "tcp" {{
  address     = "0.0.0.0:8200"
  tls_disable = true
}}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"
""")

print("Vault 설치 및 설정이 완료되었습니다.")
