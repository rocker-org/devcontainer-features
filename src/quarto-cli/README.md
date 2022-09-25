
# Quarto CLI (quarto-cli)

Installs the Quarto cli. Auto-detects latest version.

## Example Usage

```json
"features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:0": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of the Quarto CLI, if not latest. | string | latest |
| installTinyTex | Install TinyTeX by using the  `quarto tools install tinytex` command. | boolean | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/quarto-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
