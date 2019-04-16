    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : LoadBalancer IP check if it matches the whitelisted patterns
    # e.g. should be a static IP created ahead of time . 
    #
    ##############################################################################

    deny[{
        "id": "loadbalancer-whitelisted-sourceip",
        "resource": {"kind": "services", "namespace": namespace, "name": name},
        "resolution": {"message": msg},
    }] {
        matches[["services", namespace, name, matched_service]]
        not loadbalancer_whitelisted_sourceip(matched_service)
        msg := sprintf("invalid load-balancer-source-ranges for service %v", [matched_service.metadata.name])
    }

    loadbalancer_whitelisted_sourceip(service) = true {
        service.spec.type == "LoadBalancer"
        re_match("^17.0.0.0/8$", service.metadata.annotations["service.beta.kubernetes.io/load-balancer-source-ranges"])
    }
    loadbalancer_whitelisted_sourceip(service) = true {
    	service.spec.type != "LoadBalancer"
    }
