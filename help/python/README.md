# Python Setup

## Installation

```shell
./setup.sh python
```

## pre-commit

`.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-ast
        language_version: python3
      - id: check-yaml
      - id: check-case-conflict
      - id: check-executables-have-shebangs
      - id: check-merge-conflict
      - id: end-of-file-fixer
      - id: requirements-txt-fixer
      - id: trailing-whitespace
  - repo: https://github.com/ambv/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3
```

Install pre-commit hooks for repos

```shell
pre-commit install
```

## Maya Development

### Code inspection for maya api, cmds, and pymel.

- Download [Maya devkit](https://aps.autodesk.com/developer/overview/maya)
- Install to `Autodesk/Maya<Version>/devkit`
  - _Notably `devkit/other` which contains python completions._
- In Settings > Python Interpreter, add a new System interpreter for `mayapy.exe`
- Select the interpreter drop down > Show All...
- Click Show Interpreter Paths icon to customize paths for the maya interpreter.
- Add `Maya<Version>/devkit/other/Python<Version>/pymel/extras/completion/pyi`
- Disable `Maya<Version>/Python<Version>/Lib/site-packages` to avoid competing stubs.
- In Project view > External Libraries > Binary Skeletons, delete `maya` and `PySide2`
  - _Note that these will be regenerated on startup and need to be deleted each time_

### External documentation

- Open Settings > Tools > Python External Documentation
- Add a new entry for `maya.cmds`

```
http://help.autodesk.com/cloudhelp/2024/ENU/Maya-Tech-Docs/CommandsPython/{element.name}.html
```


## Motion Builder Development

### Code inspection for pyfbsdk

- ...