
# R (via rig) (r-rig)

Installs R, rig, some R packages, and needed dependencies.

## Example Usage

```json
"features": {
        "ghcr.io/rocker-org/devcontainer-features/r-rig:0": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of R, if not the latest release version. | string | release |
| installRMarkdown | Install the rmarkdown R package. | boolean | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-rig/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
