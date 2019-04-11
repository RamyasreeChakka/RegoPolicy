    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : Service port check if it matches the whitelisted ports
    # e.g. 443
    #
    ##############################################################################

    deny[{
        "id": "service-whitelisted-ports",
        "resource": {"kind": "services", "namespace": namespace, "name": name},
        "resolution": {"message": msg},
    }] {
        matches[["services", namespace, name, matched_service]]
        port = matched_service.spec.ports[_]
        format_int(port.port, 10, portstr)
        not re_match("^(443|9090)$", portstr)
        msg := sprintf("invalid port %v for service %v", [portstr, matched_service.metadata.name])
    }
