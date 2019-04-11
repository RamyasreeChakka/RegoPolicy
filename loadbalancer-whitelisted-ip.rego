    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : LoadBalancer IP check if it matches the whitelisted patterns
    # e.g. should be a static IP created ahead of time . 
    #
    ##############################################################################

    deny[{
        "id": "loadbalancer-whitelisted-ip",
        "resource": {"kind": "services", "namespace": namespace, "name": name},
        "resolution": {"message": msg},
    }] {
        matches[["services", namespace, name, matched_service]]
        not loadbalancer_whitelisted_ip(matched_service)
        msg := sprintf("invalid loadBalancerIP for service %v", [matched_service.metadata.name])
    }

    loadbalancer_whitelisted_ip(service) = true {
        service.spec.type == "LoadBalancer"
        service.spec["loadBalancerIP"]
        re_match("^78.11.24..+$", service.spec.loadBalancerIP)
    }
    loadbalancer_whitelisted_ip(service) = true {
    	service.spec.type != "LoadBalancer"
    }
