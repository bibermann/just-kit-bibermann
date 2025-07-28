[no-cd]
[group: "system"]
[positional-arguments]
cleanup-backups *ARGS:
    "{{source_directory()}}/scripts/cleanup-backups.sh" "$@"
