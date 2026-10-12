# Prints a deprecation warning, once, to stderr.
if [[ -z "${SNSDEMO_DEPRECATION_WARNED:-}" ]]; then
  {
    echo "WARNING: snsdemo is being shut down. It is built on dfx, which is deprecated in favour of icp-cli,"
    echo "WARNING: so snsdemo can no longer use newer dfinity/ic commits. If you depend on snsdemo, please say so at"
    echo "WARNING: https://github.com/dfinity/snsdemo/issues/628"
  } >&2
  export SNSDEMO_DEPRECATION_WARNED=1
fi
