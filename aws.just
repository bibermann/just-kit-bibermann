# Sign on to AWS
[no-exit-message]
aws-login: (_check-cmd "aws") (_check-env "AWS_PROFILE")
    source .env && export AWS_PROFILE && aws sso login

_check-justile-relevance:
    @command -v aws
