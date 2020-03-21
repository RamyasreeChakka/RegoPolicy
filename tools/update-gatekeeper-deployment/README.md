# Auto Update Gatkeeper Deployment Files

This script updates a given gatekeeper deployment file from a given source.

## Usage

```
$ updategatekeeper.sh --input <inputFileName> --output <outputFileName>
```

eg:
```
$ ./tools/update-gatekeeper-deployment/updategatekeeper.sh --input ../gatekeep er/deploy/gatekeeper.yaml --output ./Kubernetes/helmcharts/azure-policy-addon-aks-engine/templates/gatekeeper.yaml
```

### Arguments

- `--input` or `-i`: input file path 
- `--outpu` or `-o`: outpu file path 