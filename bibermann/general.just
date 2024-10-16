monitor *args:
    @cd /home/bibermann/scripts/set-monitor-configuration && poetry run app {{ args }}

upgrade:
    @~/scripts/upgrade-arch/upgrade.sh

bat-default:
    sudo tlp setcharge

bat-high:
    sudo tlp setcharge 70 90

bat-full:
    sudo tlp fullcharge
