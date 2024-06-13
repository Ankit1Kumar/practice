#!/bin/bash

set -e

ls
pwd

# Install AWS CLI and jq
sudo apt-get update
sudo apt-get install -y awscli jq

# Get the current branch or tag
ACCOUNT_ID=$1
BRANCH_OR_TAG=$(git rev-parse --abbrev-ref HEAD)
TASK_DEFINITION_ARN="arn:aws:ecs:us-east-1:${ACCOUNT_ID}:task-definition/auto-normalize-iz6m29xlzo8a770dbc180028ba90d9b2"
NEW_IMAGE="${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/idscience/ecs-auto-normalize:$BRANCH_OR_TAG"

echo "Branch or Tag: $BRANCH_OR_TAG"
echo "New Image: $NEW_IMAGE"

# Retrieve the existing task definition
if ! aws ecs describe-task-definition \
    --task-definition "$TASK_DEFINITION_ARN" \
    --query 'taskDefinition' \
    --output json > task-def.json; then
  echo "Failed to retrieve task definition" >&2
  exit 1
fi

# Modify the image URL in the container definition
if ! jq --arg new_image "$NEW_IMAGE" '
  .containerDefinitions[0].image = $new_image |
  del(.revision, .status, .taskDefinitionArn, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
  ' task-def.json > updated-task-def.json; then
  echo "Failed to modify task definition" >&2
  exit 1
fi

# Register the new task definition
if ! aws ecs register-task-definition --cli-input-json file://updated-task-def.json; then
  echo "Failed to register new task definition" >&2
  exit 1
fi

# Retrieve branch or tag name and update Parameter Store
BRANCH_OR_TAG=$(git rev-parse --abbrev-ref HEAD)
aws ssm put-parameter --name "container_tag-data-normalization" --value "$BRANCH_OR_TAG" --type String --overwrite
