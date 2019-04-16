    package admission

    import data.k8s.matches
    
    ###############################################################################
    #
    # Policy : Enforce labels on pod
    # e.g. pod should have required labels
    #
    ###############################################################################
    deny[{
        "id": "pod-enforce-labels", # identifies type of violation
        "resource": {
            "kind": "pods",                 # identifies kind of resource
            "namespace": namespace,         # identifies namespace of resource
            "name": name                    # identifies name of resource
        },
        "resolution": {"message": msg},     # provides human-readable message to display
    }] {
        matches[["pods", namespace, name, matched_pod]]
        requiredLabels := "test1|test2"
        delimiter := "|"
        split(requiredLabels, delimiter, labels)
        label = labels[_]
        not matched_pod.metadata.labels[label]
        msg := sprintf("required label %v is missing for pod: %v", [label, matched_pod.metadata.name])
    }
