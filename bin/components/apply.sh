#!/usr/bin/env bash

COMPONENT=$1
ENV=$2
FOLDER=./components/$COMPONENT
FILE=$FOLDER/component.yaml
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$FILE" ]; then
    echo "File $FILE does not exist"
    exit 1
fi

source "${SCRIPT_DIR}/../colors.sh"
DISABLED=$(yq '.metadata.disabled' < "$FILE")
CRD=$(yq '.files.crd // "crd.yaml"' < "$FILE")

if [ "$DISABLED" = "true" ]; then
    warning "Component $COMPONENT is disabled"
    exit 0
fi

title "Applying component $COMPONENT"
cd $FOLDER/$ENV
subTitle "CRDs"
kubectl create -f ../base/${CRD}
subTitle "Kustomize build"
kustomize build -o computed.yaml
subTitle "Applying"
kubectl apply -f computed.yaml
echo ""