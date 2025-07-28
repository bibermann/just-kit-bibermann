[no-exit-message]
[script]
[positional-arguments]
_check-cmd *CMDS:
    missing=0
    for cmd in "$@"; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        echo >&2 "ERROR: Please install '$cmd'."
        just _install-instructions "$cmd" || true
        missing=1
      fi
    done
    exit $missing

[no-exit-message]
[linux]
[script]
_install-instructions CMD:
    is_debian() {
      if [ -z ${is_debian_exit_code+x} ]; then
        [ -f /etc/debian_version ] \
          || grep -q -Ei 'debian|buntu|mint' /etc/issue \
          || grep -q -Ei '^ID(_LIKE)=.*(debian|buntu|mint)' /etc/*release \
          || grep -q -Ei '^ID(_LIKE)=.*(debian|buntu|mint)' /usr/lib/*release
        is_debian_exit_code=$?
      fi
      return "$is_debian_exit_code"
    }

    is_arch() {
      if [ -z ${is_arch_exit_code+x} ]; then
        [ -f /etc/arch-release ] \
          || grep -q -Ei 'arch' /etc/issue \
          || grep -q -Ei '^ID(_LIKE)=.*arch' /etc/*release \
          || grep -q -Ei '^ID(_LIKE)=.*arch' /usr/lib/*release
        is_arch_exit_code=$?
      fi
      return "$is_arch_exit_code"
    }

    ! is_debian || just _install-instructions-for-dir linux/debian '{{ CMD }}' || exit 1
    ! is_arch || just _install-instructions-for-dir linux/arch '{{ CMD }}' || exit 1
    just _install-instructions-for-dir linux '{{ CMD }}' || exit 1
    just _install-instructions-for-dir generic '{{ CMD }}' || exit 1

    exit 1

[no-exit-message]
[macos]
[script]
_install-instructions CMD:
    just _install-instructions-for-dir macos '{{ CMD }}' || exit 1
    just _install-instructions-for-dir generic '{{ CMD }}' || exit 1

    exit 1

[no-exit-message]
[script]
_install-instructions-for-dir DIR CMD:
    IFS=':' read -ra ROOT_DIRS <<< "${INSTALL_INSTRUCTIONS_DIRS:-.just/install-instructions:$HOME/.just/install-instructions}"
    for ROOT_DIR in "${ROOT_DIRS[@]}"; do
      if [ -f "$ROOT_DIR/{{ DIR }}/{{ CMD }}.sh" ]; then
        "$SHELL" "$ROOT_DIR/{{ DIR }}/{{ CMD }}.sh"
        exit 1
      fi
    done

_check-justile-relevance:
    false
