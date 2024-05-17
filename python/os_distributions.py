#!/usr/bin/env python3

import os

def check_command(command):
    """명령어가 시스템에 존재하는지 확인"""
    return bool(os.system(f"command -v {command} > /dev/null 2>&1") == 0)

def main():
    if check_command('apt'):
        print("Ubuntu")
    elif check_command('yum'):
        print("CentOS")
    else:
        print("other operating system.")
        exit(1)

if __name__ == "__main__":
    main()
