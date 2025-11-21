import '../core.just'

[group: "hardware"]
monitor *args:
    @cd /home/bibermann/scripts/set-monitor-configuration && poetry run app {{ args }}

[group: "system"]
upgrade:
    @~/scripts/upgrade-arch/upgrade.sh

_check-justile-relevance:
    @[[ "$(whoami)" == "bibermann" ]]
