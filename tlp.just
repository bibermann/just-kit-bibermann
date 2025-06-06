bat-default: (_check-cmd "tlp")
    sudo tlp setcharge

bat-high: (_check-cmd "tlp")
    sudo tlp setcharge 70 90

bat-full: (_check-cmd "tlp")
    sudo tlp fullcharge

_check-justile-relevance:
    @command -v tlp
