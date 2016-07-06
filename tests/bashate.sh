#!/usr/bin/env bash

echo "Executing Bashate (https://github.com/openstack-dev/bashate)"
if bashate hebato.sh; then
    echo "Bashate exited without errors."
fi
