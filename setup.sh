#!/bin/bash

set -euo pipefail

echo "setup.sh is now a compatibility wrapper."
echo "Use ./bootstrap/bootstrap.sh directly for new installs."

exec "$(dirname "$0")/bootstrap/bootstrap.sh" "$@"
