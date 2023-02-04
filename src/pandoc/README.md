
# Pandoc (pandoc)

Installs Pandoc, a universal document converter.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/pandoc:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Pandoc, if not latest. | string | latest |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu`.

## Available versions

This feature automatically fills in the missing part of the version number
and selects the latest version number among them.

For example, if version `2.17` is specified as follows, version `2.17.1.1` will be installed.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/pandoc:latest": {
        "version": "2.17"
    }
}
```

## References

- [Pandoc](https://pandoc.org)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/pandoc/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
