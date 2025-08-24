#!/usr/bin/env bash
set -euo pipefail

# Usage: ./nuke-org.sh <ORG_ID> [--no-dry-run]
: "${1:?Usage: $0 <ORG_ID> [--no-dry-run]}"
ORG_ID="$1"
NO_DRY_RUN="${2:-}"

# Safety: refuse if not explicitly confirmed with exact org id
ME=$(gcloud config get-value account 2>/dev/null || true)
ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
echo "Logged in as     : ${ME:-<none>}"
echo "Active gcloud prj: ${ACTIVE_PROJECT:-<none>}"
echo "Target ORG_ID    : ${ORG_ID}"

# Verify we can see this org
if ! gcloud organizations list --format='value(ID)' | grep -qx "${ORG_ID}"; then
  echo "ERROR: You do not have visibility on org ${ORG_ID} with current credentials."
  exit 1
fi

# Summarize what would be deleted
FOLDERS=$(gcloud resource-manager folders list --organization="${ORG_ID}" --format="value(name)")
PRJ_UNDER_FOLDERS=0
if [[ -n "${FOLDERS}" ]]; then
  while read -r F; do
    F_ID="${F#folders/}"
    CNT=$(gcloud projects list --filter="parent.type=folder parent.id=${F_ID}" --format="value(projectId)" | wc -l | tr -d ' ')
    PRJ_UNDER_FOLDERS=$((PRJ_UNDER_FOLDERS + CNT))
  done <<< "${FOLDERS}"
fi
PRJS_ORG=$(gcloud projects list --filter="parent.type=organization parent.id=${ORG_ID}" --format="value(projectId)")
PRJ_DIRECT_COUNT=$(printf "%s\n" "${PRJS_ORG}" | sed '/^$/d' | wc -l | tr -d ' ')

echo
echo "Summary:"
echo "- Folders: $(printf "%s\n" "${FOLDERS}" | sed '/^$/d' | wc -l | tr -d ' ')"
echo "- Projects under folders: ${PRJ_UNDER_FOLDERS}"
echo "- Projects directly under org: ${PRJ_DIRECT_COUNT}"
echo "- Will also remove org-policy constraints/gcp.resourceLocations (if present)."
echo
read -r -p "Type the ORG_ID (${ORG_ID}) to confirm: " confirm
[[ "${confirm}" == "${ORG_ID}" ]] || { echo "Aborted."; exit 1; }

DRY_RUN=1
if [[ "${NO_DRY_RUN}" == "--no-dry-run" ]]; then DRY_RUN=0; fi
[[ $DRY_RUN -eq 1 ]] && echo "RUN MODE: DRY RUN (no deletions will occur)"

run() { echo "+ $*"; [[ $DRY_RUN -eq 0 ]] && eval "$@"; }

# 1) Delete org policy
run gcloud org-policies delete constraints/gcp.resourceLocations --organization="${ORG_ID}" --quiet || true

# 2) Delete projects under folders
if [[ -n "${FOLDERS}" ]]; then
  while read -r F; do
    F_ID="${F#folders/}"
    PRJS=$(gcloud projects list --filter="parent.type=folder parent.id=${F_ID}" --format="value(projectId)")
    while read -r P; do
      [[ -z "$P" ]] && continue
      # Example denylist: skip critical projects by ID
      case "$P" in
        billing-*|identity-* ) echo "Skipping protected project: $P"; continue;;
      esac
      run gcloud projects delete "$P" --quiet
      [[ $DRY_RUN -eq 0 ]] && sleep 1
    done <<< "${PRJS}"
  done <<< "${FOLDERS}"
fi

# 3) Delete projects directly under org
while read -r P; do
  [[ -z "$P" ]] && continue
  case "$P" in
    billing-*|identity-* ) echo "Skipping protected project: $P"; continue;;
  esac
  run gcloud projects delete "$P" --quiet
  [[ $DRY_RUN -eq 0 ]] && sleep 1
done <<< "${PRJS_ORG}"

# 4) Delete folders (must be empty)
if [[ -n "${FOLDERS}" ]]; then
  while read -r F; do
    [[ -z "$F" ]] && continue
    run gcloud resource-manager folders delete "$F" --quiet || true
    [[ $DRY_RUN -eq 0 ]] && sleep 1
  done <<< "${FOLDERS}"
fi

echo "Done. Note: project deletion is soft (~30 days)."
