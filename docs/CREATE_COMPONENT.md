# How to create my own component

## Component folder structure
```text
components/
├── traefik/
│   ├── base/
│   │   └── kustomization.yaml
│   ├── default/
│   ├── staging/
│   │   └── kustomization.yaml
│   ├── prod/
│   │   └── kustomization.yaml
│   ├── local/
│   │   └── kustomization.yaml
│   └── component.yaml
└── component_name/
    ├── base/
    │   └── kustomization.yaml
    ├── default/
    ├── local/
    │   └── kustomization.yaml
    └── component.yaml
```
The `base` folder is where the kustomize configuration is stored with all necessary kubernetes
manifests (CRDs, Deployments, Services, etc.) generated with `Helm` templates from chart.

The `default` folder is where the default values used by `Helm` for the chart.

The `local` folder is the kustomize overlay for the local environment.
If you whant to use this boilerplate as GitOps base, you can use the `staging` and `prod` folders for your kustomize variations.

## Component file

At your root component folder, you must have a `component.yaml` file.
This is the `Traefik` component for example.

```yaml
kind: Component
apiVersion: bbr.k8s.io/v1alpha1
metadata:
  name: traefik
helm:
  repo: traefik
  repo-url: https://traefik.github.io/charts
  version: v34.4.0
  chart: traefik/traefik
  crd-version: v1.4.0
  crd-chart: traefik/traefik-crds
```

This file is used by the `Makefile` script to understand the component structure.

## Create your own component

Create a new component folder and a `component.yaml` file.
```yaml 
kind: Component 
apiVersion: bbr.k8s.io/v1alpha1 
metadata:
  name: my-component
  #disabled: true     # If you don't want to use this component
```

If you want to use your own helm chart, you can add the `helm` section.
```yaml 
helm:
  repo: my-repo
  repo-url: https://my-repo-url
  chart: my-chart
  version: v1.0.0          # To force a specific version of the chart
  crd-chart: my-chart-crds # Only if your chart uses a specific version of the CRDs
  crd-version: v1.0.0      # Only if your chart uses a specific version of the CRDs
  post-init:
    renames:               # To rename files after the `Helm` templates are generated
      - original: bitnami.com_sealedsecrets.yaml
        renamed: crd.yaml
```

If you want to keep some files from being cleaned up into the `base` directory.
```yaml
files:
  keep:
    - ns.yaml
```

Lauchn the `Makefile` initialisation process with the following command:
```bash
make components/my-component/component.yaml
```
This command will create all necessary files into the `default` and `base` folders following the component file directives.
It's up to you to modify Helm configurations files into the `default` folder. 
To regenerate the `base` folder, run the same command.

After that, you must create the `kustomize.yaml` file into the `base` folder.
```bash
cd components/my-component/base
kustomize init                      # Create the `kustomize.yaml`
kustomize edit add resource ./*     # Add all resources from the component
# Don't forget remove unnecessary resources inside the new file, like `kustomization.yaml`.
```

Create your `kustomization.yaml` file into the `local` folder.
```bash
cd ..
mkdir -p local
cd local
kustomize init
kustomize edit add base ./../base
```
Modify the local overlay with your specific changes.
