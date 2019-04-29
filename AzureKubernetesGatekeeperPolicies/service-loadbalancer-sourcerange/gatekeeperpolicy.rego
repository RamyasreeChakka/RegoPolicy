    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : Ensure service load balancer source ranges are in the whitelisted range.
    #
    ##############################################################################

    deny[{
        "id": "{{AzurePolicyID}}",        # identifies type of violation
        "resource": {
            "kind": "services",           # identifies kind of resource
            "namespace": namespace,       # identifies namespace of resource
            "name": name                  # identifies name of resource
        },
        "resolution": {"message": msg},   # provides human-readable message to display
    }] {
        matches[["services", namespace, name, matched_service]]
        namespace != "kube-system"
        not loadbalancer_whitelisted_sourceip(matched_service)
        msg := sprintf("The operation was disallowed by policy ‘{{AzurePolicyID}}’. Error details: load-balancer-source-ranges for service %v has not been whitelisted.", [matched_service.metadata.name])
    }

    loadbalancer_whitelisted_sourceip(service) = true {
        service.spec.type == "LoadBalancer"
        re_match("{{policyParameters.serviceLoadBalancerSourceRangeRegex}}", service.metadata.annotations["service.beta.kubernetes.io/load-balancer-source-ranges"])
    }
    loadbalancer_whitelisted_sourceip(service) = true {
    	service.spec.type != "LoadBalancer"
    }