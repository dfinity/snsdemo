# Prints a deprecation warning, once, to stderr.
#
# snsdemo is being shut down (see the notice at the top of README.md and
# https://github.com/dfinity/snsdemo/issues/628).  This file is sourced by
# clap.bash, so every script that uses clap prints the warning:
#
# - to stderr only, so that scripts whose stdout is parsed by callers
#   (e.g. dfx-canister-id, dfx-canister-url) keep working exactly as before;
# - at most once per process tree: SNSDEMO_DEPRECATION_WARNED is exported after
#   the first print, so scripts calling other scripts do not repeat it;
# - unless SNSDEMO_NO_DEPRECATION_WARNING is set to a non-empty value.
if [[ -z "${SNSDEMO_NO_DEPRECATION_WARNING:-}" ]] && [[ -z "${SNSDEMO_DEPRECATION_WARNED:-}" ]]; then
  {
    echo "WARNING: snsdemo is being shut down. It is built on dfx, which is deprecated in favour of icp-cli,"
    echo "WARNING: so it can no longer use newer dfinity/ic commits. If you depend on snsdemo, please say so at"
    echo "WARNING: https://github.com/dfinity/snsdemo/issues/628 (set SNSDEMO_NO_DEPRECATION_WARNING=1 to silence this)."
  } >&2
  export SNSDEMO_DEPRECATION_WARNED=1
fi
