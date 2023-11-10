#!/bin/bash
set -euo pipefail

# Pre-defined variables in the Jenkins environment
# Default values are provided in case they are not supplied externally
MINIMO_DURANTE_DEPLOY="${MINIMO_DURANTE_DEPLOY:-100}"
MAXIMO_DURANTE_DEPLOY="${MAXIMO_DURANTE_DEPLOY:-200}"
SERVICE_NAME_REVISION="${DOCKER_APP_NAME}"
ENV="${ENVIRONMENT}"
WORKING_PATH="deploy/ecs/"
DOCKER_IMAGE="${DOCKER_APP_IMAGE}"
DOCKER_REPOSITORY="${DOCKER_REPOSITORY_WORK}"
NOM_VAR_VERSION="${DOCKER_APP_VERSION}"

# Construct service and task JSON file paths with properly quoted variables
SERVICE_DEFINITION_TEMPLATE="$WORKING_PATH$ENV/$SERVICE_NAME_REVISION-servicedef-template.json"
TASK_DEFINITION_TEMPLATE="$WORKING_PATH$ENV/$SERVICE_NAME_REVISION-taskdef-template.json"

# Retrieve the ECS cluster name from the ECS service definition file
ECS_CLUSTER=$(jq --raw-output '.cluster' < "$SERVICE_DEFINITION_TEMPLATE")
echo "ECS_CLUSTER: $ECS_CLUSTER"

# Determine the latest Docker image version available in the ECR repository
LATEST_VERSION=$(aws ecr describe-images --repository-name "$DOCKER_REPOSITORY/$DOCKER_IMAGE" \
                                         --image-ids imageTag=latest \
                                         --query "imageDetails[0].imageTags[? @ != 'latest'] | [0]" \
                                         --output text \
                                         --region us-east-1)
echo "LATEST_VERSION: $LATEST_VERSION"

# Use the provided tentative version, or fall back to the latest version if none is provided
VERSION_A_INSTALAR="${NOM_VAR_VERSION:-$LATEST_VERSION}"
echo "VERSION_A_INSTALAR: $VERSION_A_INSTALAR"

# Replace the Docker image tag placeholder in the task definition JSON with the actual version
sed -i "s|_DOCKER_TAG_|$VERSION_A_INSTALAR|g" "$TASK_DEFINITION_TEMPLATE"

# # Register the new task definition with ECS and capture the revision number
# TASK_NUM=$(aws ecs register-task-definition --cli-input-json file://"$TASK_DEFINITION_TEMPLATE" \
#                                             --region us-east-1 \
#                                             --query 'taskDefinition.revision')

# # Ensure TASK_NUM is a valid number; if not, abort with an error message
# if ! [[ "$TASK_NUM" =~ ^[0-9]+$ ]]; then
#     echo "Failed to register ECS task definition. Task number is invalid: $TASK_NUM"
#     exit 1
# fi

# # Update the minimum and maximum healthy percent values in the ECS service definition file
# sed -i "s/101/$MINIMO_DURANTE_DEPLOY/g" "$SERVICE_DEFINITION_TEMPLATE"
# sed -i "s/201/$MAXIMO_DURANTE_DEPLOY/g" "$SERVICE_DEFINITION_TEMPLATE"

# # Replace the task revision number placeholder in the ECS service definition file with the actual number
# sed -i "s|_TASK_NUM_|$TASK_NUM|g" "$SERVICE_DEFINITION_TEMPLATE"

# # Get the current version of the ECS service
# echo "Obtaining the current version of the ECS service..."
# CURRENT_SERVICE_VERSION=$(aws ecs describe-services --services "$SERVICE_NAME_REVISION" \
#                                                      --cluster "$ECS_CLUSTER" \
#                                                      --query 'services[0].taskDefinition' \
#                                                      --output text \
#                                                      --region us-east-1)
# echo "CURRENT_SERVICE_VERSION: $CURRENT_SERVICE_VERSION"

# # Update the ECS service with the new service definition
# if aws ecs update-service --cli-input-json file://"$SERVICE_DEFINITION_TEMPLATE" \
#                           --region us-east-1; then
#     echo "ECS service updated successfully to revision: $TASK_NUM"
#     # Wait for the ECS service to stabilize after the update
#     aws ecs wait services-stable --cluster "$ECS_CLUSTER" --services "$SERVICE_NAME_REVISION" --region us-east-1
#     echo "ECS service is stable."
# else
#     echo "Error: ECS service update failed."
#     exit 1
# fi
