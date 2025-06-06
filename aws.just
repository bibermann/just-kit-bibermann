# Sign on to AWS
[no-exit-message]
aws-login:
    source .env && export AWS_PROFILE && aws sso login

_check-justile-relevance:
    @command -v aws

_get-required-variables:
    @echo "AWS_PROFILE"
