#!/bin/bash

# Backup cleanup script with snapper-like retention policy
# Usage: ./backup-cleanup.sh [backup_directory] [--dry-run]

set -euo pipefail

# Configuration - adjust these values as needed
KEEP_LAST=7          # Keep last 7 backups regardless of age
KEEP_DAILY=14        # Keep daily backups for 14 days
KEEP_WEEKLY=8        # Keep weekly backups for 8 weeks
KEEP_MONTHLY=12      # Keep monthly backups for 12 months
KEEP_YEARLY=5        # Keep yearly backups for 5 years

# Default backup directory
BACKUP_DIR="${1:-./}"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [backup_directory] [--dry-run]"
            echo "  backup_directory: Directory containing backup folders (default: current directory)"
            echo "  --dry-run: Show what would be deleted without actually deleting"
            echo ""
            echo "Retention policy:"
            echo "  - Keep last $KEEP_LAST backups"
            echo "  - Keep daily backups for $KEEP_DAILY days"
            echo "  - Keep weekly backups for $KEEP_WEEKLY weeks"
            echo "  - Keep monthly backups for $KEEP_MONTHLY months"
            echo "  - Keep yearly backups for $KEEP_YEARLY years"
            exit 0
            ;;
        *)
            BACKUP_DIR="$1"
            shift
            ;;
    esac
done

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory '$BACKUP_DIR' does not exist"
    exit 1
fi

# Function to convert date to timestamp
date_to_timestamp() {
    local date_str="$1"
    # Extract date part (YYYY-MM-DD) from backup-YYYY-MM-DD_HH.MM format
    local date_part=$(echo "$date_str" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    date -d "$date_part" +%s 2>/dev/null || echo 0
}

# Function to get week number for a date
get_week_key() {
    local timestamp="$1"
    date -d "@$timestamp" +%Y-W%U
}

# Function to get month key for a date
get_month_key() {
    local timestamp="$1"
    date -d "@$timestamp" +%Y-%m
}

# Function to get year key for a date
get_year_key() {
    local timestamp="$1"
    date -d "@$timestamp" +%Y
}

# Get current timestamp
NOW=$(date +%s)

# Find all backup directories matching the pattern
declare -a backups=()
while IFS= read -r -d '' backup; do
    if [[ -d "$backup" && $(basename "$backup") =~ ^backup-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}\.[0-9]{2}$ ]]; then
        backups+=("$backup")
    fi
done < <(find "$BACKUP_DIR" -maxdepth 1 -name "backup-*" -type d -print0)

# Sort backups by date (newest first)
IFS=$'\n' backups=($(sort -r <<<"${backups[*]}"))
unset IFS

if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backup directories found matching pattern backup-YYYY-MM-DD_HH.MM"
    exit 0
fi

echo "Found ${#backups[@]} backup directories"
echo "Retention policy: last=$KEEP_LAST, daily=${KEEP_DAILY}d, weekly=${KEEP_WEEKLY}w, monthly=${KEEP_MONTHLY}m, yearly=${KEEP_YEARLY}y"
echo ""

# Arrays to track what to keep
declare -A keep_backups=()
declare -A weekly_kept=()
declare -A monthly_kept=()
declare -A yearly_kept=()

# Process each backup
for i in "${!backups[@]}"; do
    backup="${backups[$i]}"
    backup_name=$(basename "$backup")

    # Extract timestamp
    timestamp=$(date_to_timestamp "$backup_name")
    if [[ $timestamp -eq 0 ]]; then
        echo "Warning: Could not parse date from $backup_name, skipping"
        continue
    fi

    # Calculate age in days
    age_seconds=$((NOW - timestamp))
    age_days=$((age_seconds / 86400))

    keep_reason=""

    # Rule 1: Keep last N backups regardless of age
    if [[ $i -lt $KEEP_LAST ]]; then
        keep_reason="last $KEEP_LAST"
        keep_backups["$backup"]=1

    # Rule 2: Keep daily backups for specified days
    elif [[ $age_days -le $KEEP_DAILY ]]; then
        keep_reason="daily (${age_days}d old)"
        keep_backups["$backup"]=1

    # Rule 3: Keep weekly backups
    elif [[ $age_days -le $((KEEP_WEEKLY * 7)) ]]; then
        week_key=$(get_week_key "$timestamp")
        if [[ -z "${weekly_kept[$week_key]:-}" ]]; then
            keep_reason="weekly ($week_key)"
            keep_backups["$backup"]=1
            weekly_kept["$week_key"]=1
        fi

    # Rule 4: Keep monthly backups
    elif [[ $age_days -le $((KEEP_MONTHLY * 30)) ]]; then
        month_key=$(get_month_key "$timestamp")
        if [[ -z "${monthly_kept[$month_key]:-}" ]]; then
            keep_reason="monthly ($month_key)"
            keep_backups["$backup"]=1
            monthly_kept["$month_key"]=1
        fi

    # Rule 5: Keep yearly backups
    elif [[ $age_days -le $((KEEP_YEARLY * 365)) ]]; then
        year_key=$(get_year_key "$timestamp")
        if [[ -z "${yearly_kept[$year_key]:-}" ]]; then
            keep_reason="yearly ($year_key)"
            keep_backups["$backup"]=1
            yearly_kept["$year_key"]=1
        fi
    fi

    # Output status
    if [[ -n "${keep_backups[$backup]:-}" ]]; then
        printf "KEEP    %-35s (%-15s) - %s\n" "$backup_name" "${age_days}d old" "$keep_reason"
    else
        printf "DELETE  %-35s (%-15s) - too old\n" "$backup_name" "${age_days}d old"
    fi
done

echo ""

# Count what will be deleted
delete_count=0
total_size=0

for backup in "${backups[@]}"; do
    if [[ -z "${keep_backups[$backup]:-}" ]]; then
        ((delete_count++))
        if command -v du >/dev/null 2>&1; then
            size=$(du -sh "$backup" 2>/dev/null | cut -f1 || echo "unknown")
            total_size=$((total_size + $(du -sb "$backup" 2>/dev/null | cut -f1 || echo 0)))
        fi
    fi
done

if [[ $delete_count -eq 0 ]]; then
    echo "No backups to delete."
    exit 0
fi

echo "Summary:"
echo "  Total backups: ${#backups[@]}"
echo "  Will keep: $((${#backups[@]} - delete_count))"
echo "  Will delete: $delete_count"

if command -v du >/dev/null 2>&1 && [[ $total_size -gt 0 ]]; then
    human_size=$(numfmt --to=iec-i --suffix=B $total_size 2>/dev/null || echo "$total_size bytes")
    echo "  Space to free: $human_size"
fi

echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN - No files were deleted"
    exit 0
fi

# Confirm deletion
read -p "Delete $delete_count backup directories? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Delete backups
deleted_count=0
for backup in "${backups[@]}"; do
    if [[ -z "${keep_backups[$backup]:-}" ]]; then
        echo "Deleting $(basename "$backup")..."
        if rm -rf "$backup"; then
            ((deleted_count++))
        else
            echo "Error: Failed to delete $backup"
        fi
    fi
done

echo ""
echo "Cleanup complete. Deleted $deleted_count backup directories."
