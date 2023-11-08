#!/usr/bin/env bash

CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

if (( $# != 1 )); then
  echo "Usage: ${0} <STREAMLIT_PY_FILE>"
  exit 1
fi

CURRENT_DATE=$(date +"%Y-%m-%d %T")
SCRIPT=$1

# Run the Streamlit app and save the output to "temp.txt"
echo "Getting the URL to view your Streamlit app in the browser."
streamlit run "${SCRIPT}" > temp.txt &
sleep 5

# Extract the last four digits of the port number from the Network URL.
PORT=$(grep "Network URL" temp.txt | awk -F':' '{print $NF}' | awk '{print $1}' | tail -c 5)
echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Port Number: ${PORT}"

# Get SageMaker Studio Domain information.
DOMAIN_ID=$(jq .DomainId /opt/ml/metadata/resource-metadata.json || exit 1)
RESOURCE_NAME=$(jq .ResourceName /opt/ml/metadata/resource-metadata.json || exit 1)
RESOURCE_ARN=$(jq .ResourceArn /opt/ml/metadata/resource-metadata.json || exit 1)

# Remove quotes from string.
DOMAIN_ID=$(sed -e 's/^"//' -e 's/"$//' <<< "$DOMAIN_ID")
RESOURCE_NAME=$(sed -e 's/^"//' -e 's/"$//' <<< "$RESOURCE_NAME")
RESOURCE_ARN=$(sed -e 's/^"//' -e 's/"$//' <<< "$RESOURCE_ARN")
# shellcheck disable=SC2207
RESOURCE_ARN_ARRAY=($(echo "$RESOURCE_ARN" | tr ':' '\n'))

# Get SageMaker Studio Domain region.
REGION="${RESOURCE_ARN_ARRAY[3]}"

# Check if it's Collaborative Space.
SPACE_NAME=$(jq .SpaceName /opt/ml/metadata/resource-metadata.json || exit 1)

# If it's not a collaborative space.
if [ -z "${SPACE_NAME}" ] || [ "${SPACE_NAME}" == "null" ] ;
then
    # If it's a user-profile access.
    echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Domain Id ${DOMAIN_ID}"
    STUDIO_URL="https://${DOMAIN_ID}.studio.${REGION}.sagemaker.aws"
else
    # It is a collaborative space.
    SEM=true
    SPACE_ID=

    # Check if Space Id was previously configured.
    if [ -f /tmp/space-metadata.json ]; then
        SAVED_SPACE_ID=$(jq .SpaceId /tmp/space-metadata.json || exit 1)
        SAVED_SPACE_ID=$(sed -e 's/^"//' -e 's/"$//' <<< "$SAVED_SPACE_ID")

        if [ -z "${SAVED_SPACE_ID}" ] || [ "${SAVED_SPACE_ID}" == "null" ]; then
            ASK_INPUT=true
        else
            ASK_INPUT=false
        fi
    else
        ASK_INPUT=true
    fi

    # If Space Id is not available, ask for it.
    while [[ $SPACE_ID = "" ]] ; do
        # If Space Id already configured, skip the ask.
        if [ "$ASK_INPUT" = true ]; then
            echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Please insert the Space Id from your url. e.g. https://${GREEN}<SPACE_ID>${NC}.studio.${REGION}.sagemaker.aws/jupyter/default/lab"
            read -r SPACE_ID
            SEM=true
        else
            SPACE_ID=$SAVED_SPACE_ID
        fi

        if [ -n "${SPACE_ID}" ] && ! [ "${SPACE_ID}" == "null" ] ;
        then
            while $SEM; do
                echo "${SPACE_ID}"
                read -r -p "Should this be used as Space Id? (y/N) " yn
                case $yn in
                    [Yy]* )
                        echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Domain Id ${DOMAIN_ID}"
                        echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Space Id ${SPACE_ID}"

                        jq -n --arg space_id "${SPACE_ID}" '{"SpaceId":$space_id}' > /tmp/space-metadata.json

                        STUDIO_URL="https://${SPACE_ID}.studio.${REGION}.sagemaker.aws"

                        SEM=false
                        ;;
                    [Nn]* )
                        SPACE_ID=
                        ASK_INPUT=true
                        SEM=false
                        ;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        fi
    done
fi

echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Amazon SageMaker Studio URL: ${STUDIO_URL}"

link="${STUDIO_URL}/jupyter/${RESOURCE_NAME}/proxy/${PORT}/"

echo -e "${CYAN}${CURRENT_DATE}: [INFO]:${NC} Starting Streamlit App:"
echo -e "${CYAN}${CURRENT_DATE}: [INFO]: ${GREEN}${link}${NC}"

exit 0
