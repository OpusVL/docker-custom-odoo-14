#!/usr/bin/env python3

import glob
import sys
import os

def main():
    print("Entered opusvl-entrypoint.py", file=sys.stderr)
    convert_environment_variables()

    dev_odoo = os.environ.get('DEV_ODOO')
    if dev_odoo is not None:
        os.environ['PATH'] = ':'.join([ dev_odoo, os.environ['PATH'] ])
        base_addons = os.path.join(dev_odoo, 'addons')
    else:
        base_addons = "/usr/lib/python3/dist-packages/openerp/addons"
    #

    candidate_addon_bundles = (
        glob.glob("/mnt/extra-addons-bundles/*")
        + ["/mnt/extra-addons", base_addons]
    )

    arglist = sys.argv[1:]

    # If we're actually going to run openerp, set up the args before we exec
    # it. Otherwise, exec ARGV as-is
    setup_config = not arglist or (
        arglist[0] == 'openerp-server'
        or arglist[0].startswith('-')
    )
    if setup_config:
        # Yes the config file env var is called OPENERP_SERVER.
        # Odoo looks at this environment variable so we're stuck with it.

        # Allow augmenting with a special config file
        # AFAIK there's only one project using this, which can probably be
        # changed
        local_config = os.environ.get('ODOO_LOCAL_CONFIG_FILE')
        if local_config and os.path.exists(local_config):
            main_config = os.environ['OPENERP_SERVER']
            arglist += ['-c', main_config]
            arglist += ['-c', local_config]

        addons_path = build_addons_path_arguments(candidate_addon_bundles)
        arglist += addons_path
        arglist.append('--logfile=/dev/stderr')   # so that docker can see them
    #

    print("/entrypoint.sh {}".format(arglist), file=sys.stderr)
    os.execl('/entrypoint.sh', '/entrypoint.sh', *arglist)
    return


def convert_environment_variables():
    """Pass through the old environment variables as the new ones
    Because Odoo changed their entrypoint, but we want all our old docker-compose files
    to work.
    See https://github.com/odoo/docker/commit/a3d207f2d49c3a0eb0e959fbf2cb33909c382a3f
    """
    envmap = {
        'PGUSER': 'USER',
        'PGPASSWORD': 'PASSWORD',
        'PGHOST': 'HOST',
        'PGPORT': 'PORT',
    }
    for (old_env_var, new_env_var) in envmap.items():
        try:
            os.environ[new_env_var] = os.environ[old_env_var]
        except KeyError:
            pass # Happy to skip where the old environment variable is not found
        #
    #
    return
#


def is_valid_addon_bundle(path):
    """Return whether the given path is a valid Odoo addon bundle.

    If this returns False, putting it in the --addons-path argument will cause
    Odoo to break on startup.
    """
    if not os.path.isdir(path):
        return False
    candidate_addons = glob.glob(os.path.join(path, '*'))
    return any(map(is_valid_addon, candidate_addons))



def is_valid_addon(path):
    """Return whether the given path looks like an Odoo addon.
    """
    valid_manifests = ['__init__.py', '__openerp__.py', '__terp__.py']
    return any(os.path.exists(os.path.join(path, m)) for m in valid_manifests)


def build_addons_path_arguments(paths):
    """Return list optionally contaiing the --addons-path=a,b,c arguments.

    If paths is empty, the empty list is produced.
    """
    valid_paths = filter(is_valid_addon_bundle, paths)
    if valid_paths:
        conjoined_paths = ','.join(valid_paths)
        if conjoined_paths != '':
            return ['--addons-path='+conjoined_paths]
    return []


if __name__ == "__main__":
    main()
