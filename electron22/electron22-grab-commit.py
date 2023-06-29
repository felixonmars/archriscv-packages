from importlib.util import spec_from_loader, module_from_spec
from importlib.machinery import SourceFileLoader
import sys

spec = spec_from_loader("deps", SourceFileLoader("deps", sys.argv[2]))
deps = module_from_spec(spec)

# The DEPS file is not a standard python file
# Let's apply some hacks to trick the interpreter.
deps.Str = str
deps.Var = str

spec.loader.exec_module(deps)

if sys.argv[1] == 'infra':
    # Return the commit of infra repo
    infra_rev = deps.vars['luci_go']
    print(infra_rev.split(':')[-1])
elif sys.argv[1] == 'luci_go':
    # Return the commit of luci repo
    luci_go_rev = deps.deps["infra/go/src/go.chromium.org/luci"]
    print(luci_go_rev.split('@')[-1])
else:
    print("Unsupported arguments!", file=sys.stderr)
    sys.exit(-1)
