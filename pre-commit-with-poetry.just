# Run pre-commit for all files
[no-exit-message]
[group: "dev"]
pre-commit: _ensure-pre-commit
    poetry run pre-commit run -a

# Run pre-commit only in current directory
[no-exit-message]
[no-cd]
[script]
[group: "dev"]
pre-commit-here: _ensure-pre-commit
    GIT_ROOT="$(git rev-parse --show-toplevel)"
    CURRENT_DIR="$PWD"
    cd "$GIT_ROOT"
    git ls-files -- "$CURRENT_DIR" | xargs poetry run pre-commit run --files

# Run pre-commit for staged files (like `git commit` would)
[no-exit-message]
[group: "dev"]
pre-commit-staged: _ensure-pre-commit
    git add .pre-commit-config.yaml
    poetry run pre-commit run

# Run pre-commit for changed files
[no-exit-message]
[script]
[group: "dev"]
pre-commit-changed: _ensure-pre-commit
    git add .pre-commit-config.yaml

    STAGED_FILES=$(git diff --name-only --cached)
    UNSTAGED_FILES=$(git diff --name-only)

    FILES=$(echo -e "$STAGED_FILES\n$UNSTAGED_FILES" | sort -u)

    if [ -n "$FILES" ]; then
        poetry run pre-commit run --files $FILES
    fi

# Call pre-commit-changed as soon as any tracked file changes
[no-exit-message]
[script]
[group: "dev"]
pre-commit-loop: _ensure-pre-commit
    trap "exit 0" SIGINT
    while true; do
        git ls-files | entr -cd just pre-commit-changed || true
    done

_install-pre-commit: (_setup-python-project "false")
    poetry run pre-commit install

_ensure-pre-commit:
    @{ [ -f .git/hooks/pre-commit ] && [ poetry.lock -ot .git/hooks/pre-commit ]; } || just _install-pre-commit

_check-justile-relevance:
    @[ -f .pre-commit-config.yaml ] && [ -f poetry.lock ]
