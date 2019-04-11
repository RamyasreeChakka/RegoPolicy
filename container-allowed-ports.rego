    package admission

    import data.k8s.matches
    
    ###############################################################################
    #
    # Policy : Container allowed ports
    # e.g. should listen on 443
    #
    ###############################################################################
    deny[{
        "id": "container-allowed-ports", # identifies type of violation
        "resource": {
            "kind": "pods",                 # identifies kind of resource
            "namespace": namespace,         # identifies namespace of resource
            "name": name                    # identifies name of resource
        },
        "resolution": {"message": msg},     # provides human-readable message to display
    }] {
        matches[["pods", namespace, name, matched_pod]]
        container = matched_pod.spec.containers[_]
        port = container.ports[_]
        format_int(port.containerPort, 10, portstr)
        not re_match("^(443|9090)$", portstr)
        msg := sprintf("invalid container port %v for container %v", [portstr, container.name])
    }
