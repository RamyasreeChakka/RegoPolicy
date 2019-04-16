    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : If service is of type LoadBalancer, then no public IP is allowed.
    # e.g. service only allows ILB
    #
    ##############################################################################

    deny[{
        "id": "loadbalancer-no-pip",
        "resource": {"kind": "services", "namespace": namespace, "name": name},
        "resolution": {"message": msg},
    }] {
        matches[["services", namespace, name, matched_service]]
        not loadbalancer_no_pip(matched_service)
        msg := sprintf("loadbalancers should not have public ips. azure-load-balancer-internal annotation is required for %v", [matched_service.metadata.name])
    }
    
    loadbalancer_no_pip(service) = true {
        service.spec.type == "LoadBalancer"
        service.metadata.annotations["service.beta.kubernetes.io/azure-load-balancer-internal"] == "true"
    }

    loadbalancer_whitelisted_ip(service) = true {
    	service.spec.type != "LoadBalancer"
    }
