#!/usr/bin/env bash
set -euo pipefail

yamllint .
ansible-lint
