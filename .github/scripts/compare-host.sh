#!/usr/bin/env bash
set -euo pipefail

started_at="$(date +%s)"
comparison_result="Current host evaluation failed"
should_build=true

summarize() {
  local exit_code=$?
  local elapsed
  elapsed=$(( $(date +%s) - started_at ))
  {
    echo "### Host comparison: ${HOST_SYSTEM} / ${HOST_NAME}"
    echo
    echo "${comparison_result}"
    echo
    echo "Comparison duration: ${elapsed} s"
  } >>"${GITHUB_STEP_SUMMARY}"
  return "${exit_code}"
}
trap summarize EXIT

compare_host() {
  if [[ "${EVENT_NAME}" != "push" ]]; then
    comparison_result="Manual selection, building without a base comparison"
    return
  fi

  # Never recover from a current evaluation failure or force sibling hosts
  current_drv="$(nix eval --raw ".#hostChecksBySystem.${HOST_SYSTEM}.${HOST_NAME}")"

  if [[ "${BASE_AVAILABLE:-false}" != "true" ]]; then
    echo "::warning::Comparison checkout unavailable for ${HOST_NAME}. Building conservatively."
    comparison_result="Comparison checkout unavailable, building conservatively"
    return
  fi

  # A newly pushed branch compares against its first parent when one exists
  if [[ "${BEFORE_REVISION}" == "0000000000000000000000000000000000000000" ]]; then
    if ! git -C .host-base checkout --detach HEAD^; then
      echo "::warning::No comparison parent available for ${HOST_NAME}. Building conservatively."
      comparison_result="Comparison parent unavailable, building conservatively"
      return
    fi
  fi

  # Historical bases may need parallel-eval or lack this host/output entirely
  # Keep their diagnostics visible, but never let that prevent a current build
  if previous_drv="$(
    nix --extra-experimental-features parallel-eval eval --raw \
      "./.host-base#hostChecksBySystem.${HOST_SYSTEM}.${HOST_NAME}"
  )"; then
    if [[ "${current_drv}" == "${previous_drv}" ]]; then
      should_build=false
      comparison_result="Derivation unchanged, skipping build"
    else
      comparison_result="Derivation changed, building"
    fi
  else
    echo "::warning::Base evaluation unavailable for ${HOST_NAME}. Building conservatively."
    comparison_result="Base evaluation unavailable, building conservatively"
  fi
}

compare_host
printf 'should-build=%s\n' "${should_build}" >>"${GITHUB_OUTPUT}"
