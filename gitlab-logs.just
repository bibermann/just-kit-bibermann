# Print GitLab CI/CD pipeline logs
[no-cd]
[group: "debug"]
[positional-arguments]
gl-logs *ARGS: (_check-cmd "jq") (_check-env "GITLAB_API" "GITLAB_TOKEN" "GITLAB_PROJECT_ID")
    "{{source_directory()}}/scripts/get-pipeline-logs.sh" "$@"
