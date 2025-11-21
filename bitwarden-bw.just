import 'core.just'

bw-unlock: (_check-cmd "bw")
  bw login --apikey
  bw unlock --raw >>~/.bw_session

_check-justile-relevance:
    @command -v bw
