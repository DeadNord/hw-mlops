#!/usr/bin/env bash
# =============================================
# purge-and-delete-s3.sh   –  повне очищення й
# видалення версійного S3-бакета.
#
# Usage: ./purge-and-delete-s3.sh <bucket> [region]
#
# Потрібні: AWS CLI v2, jq, base64.
# =============================================
set -euo pipefail

BUCKET="${1:-}"
REGION="${2:-}"   # можна не задавати – CLI візьме з env / профайлу

[[ -z "$BUCKET" ]] && { echo "✖  Usage: $0 <bucket> [region]" >&2; exit 1; }

echo "Bucket : $BUCKET"
[[ -n "$REGION" ]] && echo "Region : $REGION"

# ------------------------------------------------
# 1. Видаляємо ВСІ версії й delete-markers
# ------------------------------------------------
echo "→ Purging object versions & delete-markers…"
while true; do
  JSON=$(aws s3api list-object-versions  \
           --bucket "$BUCKET" ${REGION:+--region "$REGION"} \
           --output json)

  DEL=$(echo "$JSON" | jq -c '[.Versions[]?, .DeleteMarkers[]?]      # зібрали в масив
                              | map({Key:.Key,VersionId:.VersionId}) # зберегли потрібні поля
                              | {Objects: ., Quiet: true}')

  [[ "$(echo "$DEL" | jq '.Objects|length')" -eq 0 ]] && break

  aws s3api delete-objects --bucket "$BUCKET" \
        ${REGION:+--region "$REGION"} \
        --delete "$DEL" >/dev/null
done
echo "✓ Object versions cleaned"

# ------------------------------------------------
# 2. Абортимо незавершені multipart-upload’и
# ------------------------------------------------
echo "→ Aborting multipart uploads (якщо є)…"
while true; do
  MPU=$(aws s3api list-multipart-uploads \
           --bucket "$BUCKET" ${REGION:+--region "$REGION"} \
           --output json)

  COUNT=$(echo "$MPU" | jq '.Uploads|length')
  [[ "$COUNT" -eq 0 ]] && break

  echo "$MPU" | jq -r '.Uploads[] | [.Key,.UploadId] | @tsv' |
  while read -r KEY UPID; do
    aws s3api abort-multipart-upload \
        --bucket "$BUCKET" --key "$KEY" --upload-id "$UPID" \
        ${REGION:+--region "$REGION"} >/dev/null
  done
done
echo "✓ Multipart uploads aborted"

# ------------------------------------------------
# 3. Видаляємо сам бакет
# ------------------------------------------------
echo "→ Deleting bucket…"
aws s3api delete-bucket --bucket "$BUCKET" ${REGION:+--region "$REGION"}
echo "✓ Bucket $BUCKET removed 🎉"
