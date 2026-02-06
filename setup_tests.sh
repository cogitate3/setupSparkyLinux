#!/bin/bash
# setup_tests.sh - Set up BATS testing framework

set -e

BATS_VERSION="1.10.0"
BATS_DIR="tests/bats-core"

# Check if BATS is already installed
if [ -d "$BATS_DIR" ]; then
    echo "BATS core already present in $BATS_DIR"
else
    echo "Installing BATS v$BATS_VERSION..."
    mkdir -p tests
    git clone --branch "v$BATS_VERSION" --depth 1 https://github.com/bats-core/bats-core.git "$BATS_DIR"
fi

# Create test runner
if [ ! -f "tests/run_tests.sh" ]; then
    cat << 'EOF' > tests/run_tests.sh
#!/bin/bash
# Wrapper to run BATS tests
export BATS_LIB_PATH="$PWD/tests/bats-core/lib"
"$PWD/tests/bats-core/bin/bats" "$@"
EOF
    chmod +x tests/run_tests.sh
    echo "Created tests/run_tests.sh wrapper"
fi

echo "Testing setup complete. Run 'tests/run_tests.sh tests/' to execute tests."
