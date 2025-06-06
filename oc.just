[script]
oc-login project: (_check-cmd "oc") (_check-env "OC_API" "OC_USER" "OC_PROXY")
    source .env
    export HTTPS_PROXY="$OC_PROXY"

    if ! oc whoami >/dev/null 2>&1; then
      oc login -u "$OC_USER" "$OC_API"
      oc registry login
    fi

    oc project '{{ project }}' >&2

oc-logout: (_check-cmd "oc")
    oc logout

[script]
oc-port-forward project instance labels *ports: (_check-cmd "oc") (_check-env "OC_API" "OC_USER" "OC_PROXY")
    # `labels` is a comma-separated list to identify the pod,
    # for example: "app.kubernetes.io/name=my-app"
    # A label to filter the instance is added automatically.
    # `ports` is [<local_port>:]<remote_port> [...[<local_port_n>:]<remote_port_n>]

    [ ! -z '{{ labels }}' ] || { echo >&2 'ERROR: Specify labels to identify the pod.'; exit 1; }
    [ ! -z '{{ ports }}' ] || { echo >&2 'ERROR: Specify port mappings.'; exit 1; }

    just oc-login '{{ project }}'
    source .env
    export HTTPS_PROXY="$OC_PROXY"

    POD="$(oc get pods -o=custom-columns=NAME:.metadata.name --no-headers -l app.kubernetes.io/instance="{{ instance }},{{ labels }}")"
    echo "Pod: $POD"
    while true; do oc port-forward "$POD" {{ ports }} || true; done

[script]
oc-get-secret project name data-key: (_check-cmd "oc") (_check-env "OC_API" "OC_USER" "OC_PROXY")
    just oc-login '{{ project }}'
    source .env
    export HTTPS_PROXY="$OC_PROXY"

    oc get secret '{{ name }}' -o jsonpath="{.data['{{ data-key }}']}" | base64 -d

_check-justile-relevance:
    @command -v oc
