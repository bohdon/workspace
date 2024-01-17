# Python Setup

## Installation

Install python

```shell
choco install python
```

Install core development packages

```shell
pip install black[d] pre-commit
```

Install PyCharm

```shell
choco install pycharm-community
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
