    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : Ingress hostnames don't overlap across all Namespaces.
    #
    ##############################################################################

    deny[{
        "id": "ingress-conflict",
        "resource": {"kind": "ingresses", "namespace": namespace, "name": name},
        "resolution": {"message": "ingress host conflicts with an existing ingress"},
    }] {
        matches[["ingresses", namespace, name, matched_ingress]]
        matches[["ingresses", other_ns, other_name, other_ingress]]
        name != other_name
        other_ingress.spec.rules[_].host == matched_ingress.spec.rules[_].host
    }
