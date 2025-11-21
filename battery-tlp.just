import 'core.just'

[group: "hardware"]
bat-default: (_check-cmd "tlp")
    sudo tlp setcharge

[group: "hardware"]
bat-high: (_check-cmd "tlp")
    sudo tlp setcharge 70 90

[group: "hardware"]
bat-full: (_check-cmd "tlp")
    sudo tlp fullcharge

_check-justile-relevance:
    @command -v tlp
