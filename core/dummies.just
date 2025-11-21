# dummy
[no-exit-message]
_bootstrap-python-env RECREATE="true":
    @echo >&2 "ERROR: No python setup recipe added to justfile."
    @exit 1

# dummy
[no-exit-message]
_bootstrap-node-env RECREATE="true":
    @echo >&2 "ERROR: No node setup recipe added to justfile."
    @exit 1

# dummy
[no-exit-message]
_setup-python-project RECREATE="true":
    @echo >&2 "ERROR: No python setup recipe added to justfile."
    @exit 1

# dummy
[no-exit-message]
_setup-node-project RECREATE="true":
    @echo >&2 "ERROR: No node setup recipe added to justfile."
    @exit 1

_check-dot-env:

_ensure-pre-commit:

_check-justile-relevance:
    false
