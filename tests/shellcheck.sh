#!/usr/bin/env bash

echo "Executing Shellcheck (http://www.shellcheck.net/)"
if shellcheck ../hebato.sh; then
    echo "Shellcheck exited without errors."
fi
