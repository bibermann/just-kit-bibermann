# Run pre-commit for all files
[no-exit-message]
pre-commit: _ensure-pre-commit
    poetry run pre-commit run -a

# Run pre-commit only in current directory
[no-exit-message]
[no-cd]
[script]
pre-commit-here: _ensure-pre-commit
    GIT_ROOT="$(git rev-parse --show-toplevel)"
    CURRENT_DIR="$PWD"
    cd "$GIT_ROOT"
    git ls-files -- "$CURRENT_DIR" | xargs poetry run pre-commit run --files

# Run pre-commit for staged files (like `git commit` would)
[no-exit-message]
pre-commit-staged: _ensure-pre-commit
    git add .pre-commit-config.yaml
    poetry run pre-commit run

_install-pre-commit: (_setup-python-subproject "false")
    poetry run pre-commit install

_ensure-pre-commit:
    @{ [ -f .git/hooks/pre-commit ] && [ poetry.lock -ot .git/hooks/pre-commit ]; } || just _install-pre-commit
