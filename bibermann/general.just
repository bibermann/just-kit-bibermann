monitor *args:
    @cd /home/bibermann/scripts/set-monitor-configuration && poetry run app {{ args }}

upgrade:
    @~/scripts/upgrade-arch/upgrade.sh
