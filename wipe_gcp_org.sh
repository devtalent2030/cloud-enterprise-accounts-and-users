#!/usr/bin/env bash
set -euo pipefail

# === CONFIG: set your org ID and (optional) known project name prefix(es) ===
ORG_ID="496460677641"

# Safety: show context
ME=$(gcloud config get-value account 2>/dev/null || true)
ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
echo "Logged in as     : ${ME:-<none>}"
echo "Active gcloud prj: ${ACTIVE_PROJECT:-<none>}"
echo "Target ORG_ID    : ${ORG_ID}"
echo
read -r -p "This will delete org policy, ALL projects under folders in org ${ORG_ID}, and the folders themselves. Continue? [y/N] " ans
[[ "${ans:-N}" == "y" || "${ans:-N}" == "Y" ]] || { echo "Aborted."; exit 1; }

# 1) Remove org-level region lock policy if present
echo "==> Deleting org policy constraints/gcp.resourceLocations (if exists)..."
gcloud org-policies delete constraints/gcp.resourceLocations \
  --organization="${ORG_ID}" \
  --quiet || true

# 2) Find folders under the org
echo "==> Listing folders under org..."
FOLDERS=$(gcloud resource-manager folders list \
  --organization="${ORG_ID}" \
  --format="value(name)")
echo "${FOLDERS:-<none>}"

# 3) For each folder, delete all projects under it
echo "==> Deleting projects under each folder (this moves projects into PENDING DELETE for ~30 days)..."
if [[ -n "${FOLDERS}" ]]; then
  while IFS= read -r F; do
    F_ID="${F#folders/}"
    echo "  -> Folder ${F} : projects:"
    PRJS=$(gcloud projects list --filter="parent.type=folder parent.id=${F_ID}" --format="value(projectId)")
    if [[ -z "${PRJS}" ]]; then
      echo "     (none)"
      continue
    fi
    while IFS= read -r P; do
      echo "     Deleting project: ${P}"
      gcloud projects delete "${P}" --quiet || true
    done <<< "${PRJS}"
  done <<< "${FOLDERS}"
else
  echo "No folders found under org."
fi

# 4) Also delete any projects that are directly under the org (no folder parent)
echo "==> Deleting projects directly under org (if any)..."
PRJS_ORG=$(gcloud projects list --filter="parent.type=organization parent.id=${ORG_ID}" --format="value(projectId)")
if [[ -n "${PRJS_ORG}" ]]; then
  while IFS= read -r P; do
    echo "   Deleting project: ${P}"
    gcloud projects delete "${P}" --quiet || true
  done <<< "${PRJS_ORG}"
else
  echo "   (none)"
fi

# 5) Delete folders (must be empty first)
# Delete children first: try to delete all; failures are ignored if already gone
echo "==> Deleting folders..."
if [[ -n "${FOLDERS}" ]]; then
  # Sort longest names last/first doesn’t matter much with flat tree, but we’ll just loop twice
  while IFS= read -r F; do
    echo "   Deleting ${F}"
    gcloud resource-manager folders delete "${F}" --quiet || true
  done <<< "${FOLDERS}"
else
  echo "   (none)"
fi

echo "==> Done."
echo
echo "Notes:"
echo "- Project deletion is soft for ~30 days (PENDING DELETE). You can restore during that window."
echo "- The organization node itself cannot be deleted."

