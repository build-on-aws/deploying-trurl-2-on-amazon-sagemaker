#!/usr/bin/env bash

if (( $# != 2 )); then
  echo "Usage: ${0} <AMAZON_SAGEMAKER_EFS_ID> <AMAZON_SAGEMAKER_DOMAIN_ID>"
  exit 1
fi

EFS_ID="${1}"
DOMAIN_ID="${2}"
JMESPATH="MountTargets[*].MountTargetId"
DESCRIBE_MOUNT_TARGETS_COMMAND="aws efs describe-mount-targets --file-system-id '${EFS_ID}' --query '${JMESPATH}'"

# When you are creating Amazon SageMaker Studio Domain via AWS CloudFormation it creates by default a shared EFS
# filesystem for all the users. However, if you will delete that domain - EFS will stay there hanging. It is not a bad
# decision - as you may loose data, but still - it's annoying that you cannot override that behavior. It could be
# possible, if you could provide your own Amazon EFS filesystem, but there is no such a way at the moment.
#
# So we have to deal the hanging one differently. ;)

MOUNT_TARGETS=$(eval "${DESCRIBE_MOUNT_TARGETS_COMMAND}" | jq -r '.[]')

for MOUNT_TARGET in ${MOUNT_TARGETS}; do
    echo "DELETING MOUNT TARGET: ${MOUNT_TARGET}"
    aws efs delete-mount-target --mount-target-id "${MOUNT_TARGET}"
done

echo "WAITING FOR THE MOUNT TARGETS DELETION"

COUNT=$(eval "${DESCRIBE_MOUNT_TARGETS_COMMAND}" | jq length)
while (( COUNT > 0 )); do
    COUNT=$(eval "${DESCRIBE_MOUNT_TARGETS_COMMAND}" | jq length)
    sleep 1
done

echo "DELETING EFS: ${MOUNT_TARGET}"
aws efs delete-file-system --file-system-id "${EFS_ID}"

# The same mess happens with security groups! If you will use AWS CloudFormation it creates two groups for NFS inbound
# and outbound, but when deleting the domain - it does not delete those groups too, so we have to deal with hanging
# security groups as below.

JMESPATH="SecurityGroups[?Tags[?Key=='ManagedByAmazonSageMakerResource']|[?ends_with(Value, '${DOMAIN_ID}')]]"
SGS=$(aws ec2 describe-security-groups --query "${JMESPATH}" | jq -r '.[].GroupId')

# We perform the same cleaning operation *twice*, as those security groups are linked to each other.
# shellcheck disable=SC2034
for I in {1..2}; do
  for SG in ${SGS}; do
      JSON=$(aws ec2 describe-security-groups --group-id "${SG}" --query 'SecurityGroups[0].IpPermissions')
      if [[ "${JSON}" != '[]' ]]; then
          echo "DELETING INGRESS FOR SECURITY GROUP: ${SG}"
          INPUT_JSON="{ \"GroupId\": \"${SG}\", \"IpPermissions\": ${JSON} }"
          aws ec2 revoke-security-group-ingress --cli-input-json "${INPUT_JSON}" >/dev/null
      fi

      JSON=$(aws ec2 describe-security-groups --group-id "${SG}" --query 'SecurityGroups[0].IpPermissionsEgress')
      if [[ "${JSON}" != '[]' ]]; then
          echo "DELETING EGRESS FOR SECURITY GROUP: ${SG}"
          INPUT_JSON="{ \"GroupId\": \"${SG}\", \"IpPermissions\": ${JSON} }"
          aws ec2 revoke-security-group-egress --cli-input-json "${INPUT_JSON}" >/dev/null
      fi

      aws ec2 delete-security-group --group-id "${SG}"
      echo "DELETING SECURITY GROUP: ${SG}"
  done
done
