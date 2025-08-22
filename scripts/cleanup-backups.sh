#!/usr/bin/env bash
set -euo pipefail

# Backup cleanup script with snapper-like retention policy
# Usage: ./backup-cleanup.sh [BACKUP_DIRECTORY] [--name NAME] [--dry-run]

# Configuration - adjust these values as needed
KEEP_LAST=7     # Keep last 7 backups regardless of age
KEEP_DAILY=14   # Keep daily backups for 14 days
KEEP_WEEKLY=8   # Keep weekly backups for 8 weeks
KEEP_MONTHLY=12 # Keep monthly backups for 12 months
KEEP_YEARLY=5   # Keep yearly backups for 5 years

# Default backup directory
BACKUP_DIR="./"
DRY_RUN=false

DATE_REGEX='\b([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{4}_[0-9]{2}_[0-9]{2}|[0-9]{4}\.[0-9]{2}\.[0-9]{2})\b'
FULL_DATE_PART_REGEX="$DATE_REGEX([-._][0-9]{2}[-._][0-9]{2}\b([-._][0-9]{2}\b)?)?"
BACKUP_REGEX="backup"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --name)
    BACKUP_REGEX="$2"
    shift 2
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --help | -h)
    echo "Usage: $0 [BACKUP_DIRECTORY] [--name NAME] [--dry-run]"
    echo "  BACKUP_DIRECTORY: Directory containing backup folders/files (default: current directory)"
    echo "  NAME: Regular expression, additionally to date/time (default: $BACKUP_REGEX)"
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
  # Extract date part (YYYY-MM-DD) from backup file name (replacing non-digit chars with dash)
  local date_part=$(echo "$date_str" | grep -oE "$DATE_REGEX" | sed 's/[^0-9]/-/g')
  date -d "$date_part" +%s 2>/dev/null || echo 0
}

# Function to extract date/time part
extract_datetime_part() {
  local date_str="$1"
  echo "$date_str" | grep -oE "$FULL_DATE_PART_REGEX"
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

# Find all backup folders/files matching the pattern
declare -a backups=()
while IFS= read -r -d '' backup; do
  backup_name="$(basename "$backup")"
  if [[ (-f "$backup" || -d "$backup") && "$backup_name" =~ $DATE_REGEX && "$backup_name" =~ $BACKUP_REGEX ]]; then
    backups+=("$backup")
  fi
done < <(find "$BACKUP_DIR" -maxdepth 1 -print0)

# Sort backups by date (newest first)
IFS=$'\n' backups=($(sort -r <<<"${backups[*]}"))
unset IFS

if [[ ${#backups[@]} -eq 0 ]]; then
  echo "No backup folders/files found matching pattern '$BACKUP_REGEX'"
  exit 0
fi

echo "Found ${#backups[@]} backup folders/files"
echo "Retention policy: last=$KEEP_LAST, daily=${KEEP_DAILY}d, weekly=${KEEP_WEEKLY}w, monthly=${KEEP_MONTHLY}m, yearly=${KEEP_YEARLY}y"
echo ""

# Arrays to track what to keep
declare -A keep_backups=()
declare -A weekly_kept=()
declare -A monthly_kept=()
declare -A yearly_kept=()

num_backups=0

last_datetime_part=
is_last_kept=

# Process each backup
num_backups=1
for i in "${!backups[@]}"; do
  backup="${backups[$i]}"
  backup_name=$(basename "$backup")

  # Extract timestamp
  timestamp=$(date_to_timestamp "$backup_name")
  if [[ $timestamp -eq 0 ]]; then
    echo "Warning: Could not parse date from '$backup_name' using pattern '$DATE_REGEX', skipping"
    continue
  fi

  # Extract date/time part
  datetime_part=$(extract_datetime_part "$backup_name")

  # Calculate age in days
  age_seconds=$((NOW - timestamp))
  age_days=$((age_seconds / 86400))

  is_same_part=false
  keep_reason="delete, ${age_days}d ago"

  # Rule 0: Keep directories with same date/time pattern (grouping backup dirs)
  if [[ "$datetime_part" == "$last_datetime_part" ]]; then
    is_same_part=true
    keep_reason="..."
    if [[ "$is_last_kept" == true ]]; then
      keep_backups["$backup"]=1
    fi

  # Rule 1: Keep last N backups regardless of age
  elif [[ $num_backups -le $KEEP_LAST ]]; then
    keep_reason="last $KEEP_LAST backups, ${age_days}d ago"
    keep_backups["$backup"]=1

  # Rule 2: Keep daily backups for specified days
  elif [[ $age_days -le $KEEP_DAILY ]]; then
    keep_reason="daily, ${age_days}d ago"
    keep_backups["$backup"]=1

  # Rule 3: Keep weekly backups
  elif [[ $age_days -le $((KEEP_WEEKLY * 7)) ]]; then
    week_key=$(get_week_key "$timestamp")
    if [[ -z "${weekly_kept[$week_key]:-}" ]]; then
      keep_reason="weekly, $week_key, ${age_days}d ago"
      keep_backups["$backup"]=1
      weekly_kept["$week_key"]=1
    fi

  # Rule 4: Keep monthly backups
  elif [[ $age_days -le $((KEEP_MONTHLY * 30)) ]]; then
    month_key=$(get_month_key "$timestamp")
    if [[ -z "${monthly_kept[$month_key]:-}" ]]; then
      keep_reason="monthly, $month_key, ${age_days}d ago"
      keep_backups["$backup"]=1
      monthly_kept["$month_key"]=1
    fi

  # Rule 5: Keep yearly backups
  elif [[ $age_days -le $((KEEP_YEARLY * 365)) ]]; then
    year_key=$(get_year_key "$timestamp")
    if [[ -z "${yearly_kept[$year_key]:-}" ]]; then
      keep_reason="yearly, $year_key, ${age_days}d ago"
      keep_backups["$backup"]=1
      yearly_kept["$year_key"]=1
    fi
  fi

  # Output status
  if [[ -n "${keep_backups[$backup]:-}" ]]; then
    printf "KEEP    %s  (%s)\n" "$backup_name" "$keep_reason"
    is_last_kept=true
  else
    printf "DELETE  %s  (%s)\n" "$backup_name" "$keep_reason"
    is_last_kept=false
  fi

  if [[ "$is_same_part" != true ]]; then
    ((num_backups += 1))
    last_datetime_part="$datetime_part"
  fi
done

echo ""

# Count what will be deleted
delete_count=0
total_size=0

for backup in "${backups[@]}"; do
  if [[ -z "${keep_backups[$backup]:-}" ]]; then
    ((delete_count += 1))
    total_size=$((total_size + $(du -sb "$backup" 2>/dev/null | cut -f1 || echo 0)))
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

if [[ $total_size -gt 0 ]]; then
  human_size=$(numfmt --to=iec-i --suffix=B $total_size 2>/dev/null || echo "$total_size bytes")
  echo "  Space to free: $human_size"
fi

echo ""

if [[ "$DRY_RUN" != "false" ]]; then
  echo "DRY RUN - No files were deleted"
  exit 0
fi

# Confirm deletion
read -p "Delete $delete_count backup folders/files? [y/N] " -n 1 -r
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
      ((deleted_count += 1))
    else
      echo "Error: Failed to delete $backup"
    fi
  fi
done

echo ""
echo "Cleanup complete. Deleted $deleted_count backup directories."
