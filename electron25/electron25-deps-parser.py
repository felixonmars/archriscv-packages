from importlib.util import spec_from_loader, module_from_spec
from importlib.machinery import SourceFileLoader
import sys
import re

spec = spec_from_loader("deps", SourceFileLoader("deps", sys.argv[2]))
deps = module_from_spec(spec)

# The DEPS file is not a standard python file
# Let's apply some hacks to trick the interpreter.
deps.Str = str
deps.Var = str

spec.loader.exec_module(deps)

match sys.argv[1]:
    case 'infra':
        # Return the commit of infra repo
        infra_rev = deps.vars['luci_go']
        print(infra_rev.split(':')[-1])
    case 'luci_go':
        # Return the commit of luci repo
        luci_go_rev = deps.deps["infra/go/src/go.chromium.org/luci"]
        print(luci_go_rev.split('@')[-1])
    case 'esbuild':
        esbuild_ver_full = deps.deps["src/third_party/devtools-frontend/src/third_party/esbuild"]["packages"][0]["version"]
        esbuild_ver = re.match("^(.+)\.chromium.*$", esbuild_ver_full.split("@")[-1])[1]
        print(esbuild_ver)
    case 'depot_tools':
        depot_tools_rev = deps.deps['src/third_party/depot_tools'].split('@')[-1]
        print(depot_tools_rev)
    case _:
        print("Unsupported arguments!", file=sys.stderr)
        sys.exit(-1)
