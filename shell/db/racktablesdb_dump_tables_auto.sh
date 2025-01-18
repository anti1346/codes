#!/bin/bash

# 데이터베이스 접속 정보
DB_HOST="localhost"
DB_USER="root"
DB_PASS="your_database_password"
DB_NAME="racktablesdb"
BACKUP_DIR="/app/backup_dir/dbdata"
DATE=$(date +%Y%m%d_%H%M%S)

# MySQL 명령어 경로 확인
MYSQL=$(command -v mysql)
MYSQLDUMP=$(command -v mysqldump)

# MySQL 명령어 확인
if [[ -z "$MYSQL" || -z "$MYSQLDUMP" ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 오류: mysql 또는 mysqldump 명령어를 찾을 수 없습니다."
    exit 1
fi

# 백업 디렉토리 생성
BACKUP_PATH="${BACKUP_DIR}/${DB_NAME}_${DATE}"
mkdir -p "$BACKUP_PATH"

# 사용자 입력 확인
if [[ -n "$1" ]]; then
    # 사용자가 테이블을 지정한 경우
    TABLES="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 지정된 테이블: $TABLES"
else
    # 사용자가 테이블을 지정하지 않은 경우, 데이터베이스에서 목록 가져오기
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 테이블 목록을 데이터베이스에서 가져옵니다..."
    TABLES=$($MYSQL -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "SHOW TABLES;" | awk 'NR > 1')
    if [[ -z "$TABLES" ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] 오류: 데이터베이스에서 테이블 목록을 가져올 수 없습니다."
        exit 1
    fi
fi

# 각 테이블 단위로 백업
echo "[$(date +'%Y-%m-%d %H:%M:%S')] RackTables 데이터베이스 테이블 단위 백업을 시작합니다..."
for TABLE in $TABLES; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 백업 중: $TABLE"
    $MYSQLDUMP -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" "$TABLE" > "${BACKUP_PATH}/${TABLE}.sql"
    if [[ $? -eq 0 ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] -> $TABLE 백업 완료."
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] -> $TABLE 백업 실패!"
    fi
done

# 백업 디렉토리를 압축
ARCHIVE_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.tar.gz"
tar -czf "$ARCHIVE_FILE" -C "$BACKUP_PATH" .
if [[ $? -eq 0 ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 백업 디렉토리 압축 완료: $ARCHIVE_FILE"
    # # 임시 백업 디렉토리 삭제
    # rm -rf "$BACKUP_PATH"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] 오류: 백업 디렉토리 압축 실패!"
    exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 모든 테이블 백업 및 압축 완료!"
echo "백업 경로: $BACKUP_PATH"



##### Shell Execute
### 비밀번호 보안(모든 테이블 백업)
# DB_PASS="database_password" ./racktablesdb_dump_tables_auto.sh
### 특정 테이블만 백업
# DB_PASS="database_password" ./racktablesdb_dump_tables_auto.sh TableName
### 여러 테이블만 백업
# DB_PASS="database_password" ./racktablesdb_dump_tables_auto.sh "TableName1 TableName2 TableName3"