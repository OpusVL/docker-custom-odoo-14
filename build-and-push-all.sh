#!/bin/bash

function remove-blank-lines()
{
	grep -v '^$'
}

if [ -z "$REPO_VERSION" ]
then
	echo "Set REPO_VERSION, e.g. v1" >&2
	exit 1
else
	set -v
	# By default read splits on any whitespace, not just tabs
	# so beware of this if you introduce a field that could
	# validly contain whitespace.  Porting to python3 could
	# be the easiest solution
	cat ./odoo-revisions.tsv \
		|	remove-blank-lines \
		|	while read ODOO_RELEASE ODOO_SHA
			do
				export ODOO_RELEASE
				export ODOO_SHA
				echo "ODOO_RELEASE=$ODOO_RELEASE" >&2
				echo "ODOO_SHA=$ODOO_SHA" >&2
				./build-and-push.sh
			done
fi
