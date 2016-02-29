#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $(readlink -f $0)) && pwd)
# config defaults:
CRT_NAME="${BASEDIR}/backup"
FILES_LIST="${BASEDIR}/files.list"
SSH_ID="${BASEDIR}/default.id_rsa"
BACKUP_SERVER="bacup-server"
BACKUP_USER="backup-user"
BACKUP_DIR="backup-dir"
LOG_FILE="${BASEDIR}/backup.log"
source ${BASEDIR}/config.sh


ssl_keygen() {
    local crt_name="$1"
    local crt_file="${crt_name}.crt"
    local crt_key="${crt_name}.key"

    openssl req -x509 -days 10000 -newkey rsa:2048 -nodes -keyout "${crt_key}" -out "${crt_file}" -subj '/'
}

ssl_encrypt() {
    openssl smime -encrypt -aes256 -binary -outform D "${CRT_NAME}.crt"
}

ssl_decrypt() {
    openssl smime -decrypt -inform D -binary -inkey "${CRT_NAME}.key"
}

write_log() {
    echo "$(date  '+%Y-%m-%d %T'): $1" >> "${LOG_FILE}"
}

do_backup() {
    write_log "start"
    local backup_file="$(date '+%Y-%m-%d_%H-%M-%S.tar.gz.enc')"
    tar -cz -T "${FILES_LIST}" | \
        ssl_encrypt | \
        ssh -i "${SSH_ID}" "$BACKUP_USER@$BACKUP_SERVER" \
            "mkdir -p $BACKUP_DIR; cat > ${BACKUP_DIR}/${backup_file}" 2>>"${LOG_FILE}"
    if [[ "$?" -eq 0 ]]; then
        write_log "success"
    else
        write_log "fail"
    fi
}


case "$1" in
    keygen)
        ssl_keygen "${CRT_NAME}"
        ;;
    encrypt)
        ssl_encrypt
        ;;
    decrypt)
        ssl_decrypt
        ;;
    backup)
        do_backup
        ;;
esac
