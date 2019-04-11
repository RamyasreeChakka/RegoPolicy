    package admission

    import data.k8s.matches
    
    ##############################################################################
    #
    # Policy : Ingress should be https.
    #
    ##############################################################################

    deny[{
        "id": "ingress-https",
        "resource": {"kind": "ingresses", "namespace": namespace, "name": name},
        "resolution": {"message": msg},
    }] {
        matches[["ingresses", namespace, name, matched_ingress]]
        not https_complete(matched_ingress)
        msg := sprintf("ingress should be https. tls configuration and allow_http annotation are required for %v", [matched_ingress.metadata.name])
    }
    
    https_complete(ingress) = true {
        ingress.spec["tls"]
        count(ingress.spec.tls) > 0
        ingress.metadata.annotations["kubernetes.io/ingress.allow-http"] == "false"
    }
