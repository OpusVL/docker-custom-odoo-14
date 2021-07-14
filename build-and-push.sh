#!/bin/bash

if [ -z "$ODOO_RELEASE" ]
then
	echo "Set ODOO_RELEASE" >&2
	exit 1
elif [ -z "$ODOO_SHA" ]
then
	echo "Set ODOO_SHA" >&2
	exit 1
elif [ -z "$REPO_VERSION" ]
then
	echo "Set REPO_VERSION" >&2
	exit 1
else
	set -e
	set -x
	IMAGE="quay.io/opusvl/custom-odoo-14:$REPO_VERSION-release-$ODOO_RELEASE"
	docker build \
	    --build-arg "ODOO_RELEASE=$ODOO_RELEASE" \
	    --build-arg "ODOO_SHA=$ODOO_SHA" \
	    -t "$IMAGE" \
	    .
	docker push "$IMAGE"
fi
