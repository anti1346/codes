#!/usr/bin/env python3

import argparse
import os
import subprocess

def set_proxy(command, proxy_ip, proxy_port):
    proxy_config = ""
    proxy_file = ""

    if command == "apt_proxy":
        proxy_config = f'Acquire::http::Proxy "http://{proxy_ip}:{proxy_port}/";\nAcquire::https::Proxy "https://{proxy_ip}:{proxy_port}/";'
        proxy_file = "/etc/apt/apt.conf.d/02proxy"
    elif command == "bash_proxy":
        proxy_config = f'export http_proxy=http://{proxy_ip}:{proxy_port}\nexport https_proxy=https://{proxy_ip}:{proxy_port}'
        proxy_file = os.path.expanduser("~/.bashrc")

    with open(proxy_file, 'a') as file:
        file.write(proxy_config + "\n")

    if command == "apt_proxy":
        subprocess.run(["sudo", "tee", "-a", proxy_file], input=proxy_config.encode(), stdout=subprocess.DEVNULL)

    return proxy_file

def main():
    parser = argparse.ArgumentParser(description="Sets APT or Bash proxy configuration.")
    parser.add_argument("command", choices=["apt_proxy", "bash_proxy"], help="Command to set proxy (apt_proxy or bash_proxy)")
    parser.add_argument("proxy_ip", help="Proxy IP address")
    parser.add_argument("proxy_port", nargs='?', default="3128", help="Proxy port (default: 3128)")

    args = parser.parse_args()

    if args.command not in ["apt_proxy", "bash_proxy"]:
        parser.error("Invalid command. The first argument must be 'apt_proxy' or 'bash_proxy'.")

    proxy_file = set_proxy(args.command, args.proxy_ip, args.proxy_port)
    print(f"{args.command.capitalize()} 프록시 설정이 완료되었습니다.\n- 설정 파일: {proxy_file}")

if __name__ == "__main__":
    main()

