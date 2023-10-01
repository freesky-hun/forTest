#!/bin/bash

# Define necessary variables for backup
backup_dir="/var/backup"  # Location for backups
backup_log="/var/log/backup.log"  # Location of the log file

# Define necessary variables for rsync
source_dir="/var/backup"  # Source directory to be synced
server2_user="backup"    # Server2 username
server2_ip="192.168.56.20"  # Server2 IP address
destination_dir="/mnt/backup/server1backup"  # Destination directory on Server2

# Define date format
current_date=$(date +'%Y-%m-%d %H:%M:%S')

# Check if the backup directory exists; if not, create it
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
fi

# Backup process
logger -t backup -p local0.info "Backup started at $current_date"

# Backup MySQL database
mysql_user="mysql_username"
mysql_password="mysql_password"
mysql_database="mysql_database"
mysql_dump_file="$backup_dir/mysql_backup_$(date +'%Y%m%d_%H%M%S').sql"

if mysqldump -u "$mysql_user" -p"$mysql_password" "$mysql_database" > "$mysql_dump_file"; then
    logger -t backup -p local0.info "MySQL database backup successful: $mysql_dump_file"
else
    logger -t backup -p local0.crit "Failed to backup MySQL database"
fi

# Backup /etc directory
etc_backup_file="$backup_dir/etc_backup_$(date +'%Y%m%d_%H%M%S').tar.gz"

if tar -czf "$etc_backup_file" /etc; then
    logger -t backup -p local0.info "/etc directory backup successful: $etc_backup_file"
else
    logger -t backup -p local0.crit "Failed to backup /etc directory"
fi

# Use rsync to synchronize the directory with Server2
if rsync -avz -e "ssh" "$source_dir/" "$server2_user@$server2_ip:$destination_dir/"; then
    logger -t backup -p local0.info "rsync to $server2_ip successful: $source_dir -> $destination_dir"
else
    logger -t backup -p local0.crit "Failed to rsync to $server2_ip: $source_dir -> $destination_dir"
fi

# Log that the backup process has finished
logger -t backup -p local0.info "Backup completed at $current_date"
