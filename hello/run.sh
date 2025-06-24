#!/usr/bin/env bash

usage() {
  cat <<EOF
Usage: $0 <command> [options]

Commands:
  Setup:
    sandbox                                Run Aztec node + pxe locally
    import-test-accounts                   Import test accounts into aztec-wallet
    deploy-hello                           Deploy the hello contract without initialization
  gate-flamegraph <function_name>          Generate gate flamegraph for the specified private function
  gate-profile <function_name> [args...]   Show total gates for the specified private function with optional arguments
  -h, --help                               Show this help message

Examples:
  $0 sandbox
  $0 import-test-accounts
  $0 deploy-hello
  $0 gate-flamegraph myFunction
  $0 gate-profile myFunction 1 2 3
EOF
}

if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  usage
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  sandbox)
    aztec start --sandbox
    ;;
  import-test-accounts)
    aztec-wallet import-test-accounts
    ;;
  deploy-hello)
    aztec-wallet deploy --no-init target/hello-Hello.json --from test0 --alias hello
    ;;
  gate-flamegraph)
    if [[ $# -lt 1 ]]; then
      echo "Error: function_name required for flamegraph"
      usage
      exit 1
    fi
    SERVE=1 aztec flamegraph target/hello-Hello.json "$1"
    ;;
  gate-profile)
    if [[ $# -lt 1 ]]; then
      echo "Error: function_name required for profile"
      usage
      exit 1
    fi
    fn="$1"; shift
    aztec-wallet profile "$fn" --args "$@" --contract-address hello -f test0
    ;;
  *)
    echo "Unknown command: $COMMAND"
    usage
    exit 1
    ;;
esac
