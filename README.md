# docker-odoo-custom
An Odoo docker image with extended capabilities and fixes over the official one.

Some of these are development aids, while some make a difference to how images
are built for production.

[![Docker Repository on Quay](https://quay.io/repository/opusvl/odoo-custom/status "Docker Repository on Quay")](https://quay.io/repository/opusvl/odoo-custom)

# Locales

Locales are generated for en_GB, and are set as default in the environment.

# Extra fonts

* fonts-dejavu
* fonts-dejavu-extra
* Reportlab barcode font

# Addons Bundles

An `--addons-path` argument is automatically built on each startup to contain any subdirectories within `/mnt/extra-addons-bundles` that contain at least one valid Odoo addon.  This could be a checkout of a repository from https://github.com/OCA for example.

So you can check out a set of modules directly into there (in a volume or copied in via a Dockerfile extending this one) and have Odoo pick them up, instead of having to flatten the tree yourself or manually build an addons_path in the config file.

## How to base your own image off this

Create a git repo with the following structure:

* a directory `addons-bundles` containing the repositories we are using modules from as git submodules (though sometimes customer-specific modules live in a plain subdirectory of this directory).  Can be empty but must be there.  Use a .gitkeep file if necessary.
* a `requirements.txt` listing extra modules to install via pip.  Can be empty but must be there.
* a `Dockerfile`

The Dockerfile might have something like this in it:

```
FROM quay.io/opusvl/odoo-custom:10.0
```

# Run Odoo from a git checkout

Setting the `DEV_ODOO` environment variable to a path, e.g. `/opt/odoo`, where you have
mounted a git clone of an Odoo source tree, will cause that path to be prepended to the
PATH and the default addons path to point to it.

# Old DB config environment variables still work

EXPERIMENTAL

The `DB*` environment variables we have in our existing docker-compose setups are, if set, copied to the new equivalents as of about 6 months ago.

This is for backwards compatibility with existing environments that are configured using the `DB*` variables.  If they are set, then they will override the official ones - depending on internal feedback or feedback from you, the community, we may change the priorities so consider this particular bit experimental.


# How it works

There is a new entrypoint `opusvl-entrypoint.py` which augments environment variables and the command line with its own stuff depending on environment variables you set and what it finds in `/mnt/extra-addons-bundles`, then despatches to the upstream `entrypoint.sh`, re-using the logic contained therein.


# Copyright and License

Copyright (C) 2017  Opus Vision Limited

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

If you require assistance, support, or further development of this
software, please contact OpusVL using the details below:

* Telephone: +44 (0)1788 298 410
* Email: community@opusvl.com
* Web: http://opusvl.com

