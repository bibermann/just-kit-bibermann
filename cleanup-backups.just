[no-cd]
[group: "system"]
cleanup-backups *ARGS:
    "{{source_directory()}}/scripts/cleanup-backups.sh" "$@"
