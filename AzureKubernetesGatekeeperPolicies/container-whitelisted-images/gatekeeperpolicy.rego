    package admission

    import data.k8s.matches
    
    ###############################################################################
    #
    # Policy : Container image name check if it matches the whitelisted patterns
    # e.g. should be from an organization registry. 
    #
    ###############################################################################
    deny[{
        "id": "{{AzurePolicyID}}",          # identifies type of violation
        "resource": {
            "kind": "pods",                 # identifies kind of resource
            "namespace": namespace,         # identifies namespace of resource
            "name": name                    # identifies name of resource
        },
        "resolution": {"message": msg},     # provides human-readable message to display
    }] {
        matches[["pods", namespace, name, matched_pod]]
        container = matched_pod.spec.containers[_]
        not re_match("{{policyParameters.containerAllowedImagesRegex}}", container.image)
        msg := sprintf("invalid container registry image %q", [container.image])
    }