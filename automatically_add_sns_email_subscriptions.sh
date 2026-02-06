#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# SNS Email Subscription Utility (Account-Agnostic)
#
# • Designed to run in AWS CloudShell
# • Automatically detects AWS account ID and region
# • Subscribes a list of emails to an SNS topic
# • Skips emails that are already subscribed
#
# IMPORTANT:
#   - SNS email subscriptions REQUIRE manual confirmation by recipients
#   - This script only creates the subscription requests
###############################################################################

# --------------------------------------------------
# Detect AWS context
# --------------------------------------------------
AWS_REGION="$(aws configure get region)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

if [[ -z "$AWS_REGION" ]]; then
  echo "ERROR: AWS region not configured. Run 'aws configure' or use CloudShell."
  exit 1
fi

echo "Detected AWS Account ID : $ACCOUNT_ID"
echo "Detected AWS Region     : $AWS_REGION"
echo

# --------------------------------------------------
# SNS Topic configuration
#
# OPTION A (recommended):
#   Fill in TOPIC_NAME only — ARN is derived automatically
#
# OPTION B:
#   Comment out TOPIC_NAME and directly set TOPIC_ARN
# --------------------------------------------------

# OPTION A — topic name (preferred)
TOPIC_NAME="secret-rotation-alerts-REPLACE_ME"

# OPTION B — explicit ARN (uncomment if needed)
# TOPIC_ARN="arn:aws:sns:REGION:ACCOUNT_ID:TOPIC_NAME"

# --------------------------------------------------
# Build Topic ARN (if using OPTION A)
# --------------------------------------------------
if [[ -z "${TOPIC_ARN:-}" ]]; then
  TOPIC_ARN="arn:aws:sns:${AWS_REGION}:${ACCOUNT_ID}:${TOPIC_NAME}"
fi

echo "Using SNS Topic ARN     : $TOPIC_ARN"
echo

# --------------------------------------------------
# Email list
#
# Replace these with your real addresses.
# One email per line for easy diffing.
# --------------------------------------------------
EMAILS=(
  "testuser1@example.com"
  "testuser2@example.com"
  "testuser3@example.com"
  "testuser4@example.com"
  "testuser5@example.com"
)

# --------------------------------------------------
# Fetch existing subscriptions (to avoid duplicates)
# --------------------------------------------------
echo "Fetching existing subscriptions..."
EXISTING_ENDPOINTS="$(aws sns list-subscriptions-by-topic \
  --region "$AWS_REGION" \
  --topic-arn "$TOPIC_ARN" \
  --query 'Subscriptions[].Endpoint' \
  --output text || true)"

echo

# --------------------------------------------------
# Subscribe emails (skip if already present)
# --------------------------------------------------
for email in "${EMAILS[@]}"; do
  if echo "$EXISTING_ENDPOINTS" | grep -qi "$email"; then
    echo "SKIP  : $email (already subscribed)"
  else
    echo "ADD   : $email"
    aws sns subscribe \
      --region "$AWS_REGION" \
      --topic-arn "$TOPIC_ARN" \
      --protocol email \
      --notification-endpoint "$email"
  fi
done

echo
echo "Done."
echo "Reminder: recipients must confirm the subscription via email."
