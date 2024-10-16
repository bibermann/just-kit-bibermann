[no-exit-message]
_check-cmd CMD:
    @which '{{ CMD }}' >/dev/null || (echo >&2 'ERROR: Please install `{{ CMD }}`.' && just _install-instructions '{{ CMD }}')

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

    if is_debian; then
      case '{{ CMD }}' in
        "make") echo >&2 "Install the following packages: build-essential python3 python3-setuptools python3-pip python3-venv libssl-dev libsqlite3-dev libbz2-dev libncurses5-dev liblzma-dev libreadline-dev libffi-dev python3-tk tk-dev" && exit 1;;
        "java") echo >&2 "Install the following packages: default-jre" && exit 1;;
      esac
    elif is_arch; then
      case '{{ CMD }}' in
      esac
    fi

    just _install-instructions-generic '{{ CMD }}'

[no-exit-message]
[macos]
[script]
_install-instructions CMD:
    case '{{ CMD }}' in
    esac

    just _install-instructions-generic '{{ CMD }}'

[no-exit-message]
[script]
_install-instructions-generic CMD:
    case '{{ CMD }}' in
      "docker") echo >&2 "See https://docs.docker.com/get-docker/" && exit 1;;
      "pyenv") echo >&2 "See https://github.com/pyenv/pyenv#getting-pyenv" && exit 1;;
      "poetry") echo >&2 "See https://python-poetry.org/docs/#installation" && exit 1;;
      "nvm") echo >&2 "See https://github.com/nvm-sh/nvm#installing-and-updating" && exit 1;;
    esac
