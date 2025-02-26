#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "File $1 does not exist"
    exit 1
fi

FILE=$1
FILE_DIR=$(dirname "$FILE")
FILE_BASENAME=$(basename ${FILE})
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
NAMESPACE=$(yq '.metadata.namespace // "components"' < "$FILE")
DISABLED=$(yq '.metadata.disabled' < "$FILE")
NAME=$(yq '.metadata.name' < "$FILE")
REPO=$(yq '.helm.repo' < "$FILE")
REPO_URL=$(yq '.helm.repo-url' < "$FILE")
CHART=$(yq '.helm.chart' < "$FILE")
VERSION=$(yq '.helm.version' < "$FILE")
CRD_VERSION=$(yq '.helm.crd-version' < "$FILE")
CRD_CHART=$(yq '.helm.crd-chart' < "$FILE")
HAS_RESOLVES=$(yq '.helm.post-init.resolves' < "$FILE" | grep -c '^-')
HAS_RENAMES=$(yq '.helm.post-init.renames' < "$FILE" | grep -c '^-')
HAS_CONCATS=$(yq '.helm.post-init.concats' < "$FILE" | grep -c '^-')
AWK_SCRIPT="${SCRIPT_DIR}/split_yaml.awk"

source "${SCRIPT_DIR}/../colors.sh"

if [ "$DISABLED" = "true" ]; then
    warning "Component $NAME is disabled"
    echo ""
    exit 0
fi

main() {
    title "Initializing component $NAME"
    cd ./components/$NAME 
    mkdir -p "default"
    mkdir -p "base"
    _get_component_repo "$REPO" "$REPO_URL" "$NAME"

    _clean_base_directory

    if [ "$CRD_CHART" != "null" ]; then
        subTitle "Get CRD chart templates"
        _get_component_defaults "crd-" "$CRD_CHART" "$CRD_VERSION"
        _get_component_templates_with_crds ${NAMESPACE} "crd-" "$NAME" "$CRD_CHART" "$CRD_VERSION" "crd"
    fi

    if [ "$CHART" != "null" ]; then
        subTitle "Get chart templates"
        _get_component_defaults "" "$CHART" "$VERSION"
        if [ "$CRD_CHART" != "null" ]; then
            _get_component_templates ${NAMESPACE} "" "$NAME" "$CHART" "$VERSION" "tmp"
        else
            _get_component_templates_with_crds ${NAMESPACE} "" "$NAME" "$CHART" "$VERSION" "tmp"
        fi
        
        awk -f "$AWK_SCRIPT" "./base/tmp.yaml" && rm "./base/tmp.yaml"
    fi

    if [ "$HAS_RESOLVES" -gt 0 ]; then
        subTitle "Processing resolves"
        for i in $(seq 0 $(($HAS_RESOLVES - 1))); do
            RESOLVES=$(yq ".helm.post-init.resolves[$i]" < "./$FILE_BASENAME")
            echo "-> Resolving ${RESOLVES}"
            for file in ./base/${RESOLVES}; do
                URL=$(grep -o 'http[s]\?://[^ ]*yaml' "$file" | head -n 1)
                curl -s "$URL" >> "$file"
            done
        done
    fi

    if [ "$HAS_CONCATS" -gt 0 ]; then
        subTitle "Processing concats"
        for i in $(seq 0 $(($HAS_CONCATS - 1))); do
            FOLDER=$(yq ".helm.post-init.concats[$i].folder" < "./$FILE_BASENAME")
            INCLUDES=$(yq ".helm.post-init.concats[$i].includes // \"*.yaml\"" < "./$FILE_BASENAME")
            OUTPUT=$(yq ".helm.post-init.concats[$i].output" < "./$FILE_BASENAME")
            PAST_FOLDER=$(pwd)
            echo "-> Concatenating files from ${FOLDER} into ${OUTPUT}"
            cd ./base/${FOLDER}
            for file in ./${INCLUDES}; do
                cat "$file" >> "../${OUTPUT}"
            done
            cd ../
            rm -rf ${FOLDER}
            cd ${PAST_FOLDER}
        done
    fi

    if [ "$HAS_RENAMES" -gt 0 ]; then
        subTitle "Processing renames"
        for i in $(seq 0 $(($HAS_RENAMES - 1))); do
            ORIGINAL=$(yq ".helm.post-init.renames[$i].original" < "./$FILE_BASENAME")
            RENAMED=$(yq ".helm.post-init.renames[$i].renamed" < "./$FILE_BASENAME")
            if [ -f "./base/$ORIGINAL" ]; then
                mv "./base/$ORIGINAL" "./base/$RENAMED"
                echo "-> Renamed $ORIGINAL to $RENAMED"
            fi
        done
    fi
    echo ${normal}
}

# Function to clean the base directory
_clean_base_directory() {
    subTitle "Cleaning base directory"
    if [ ! -d "./base" ]; then
        warning "Base directory does not exist"
        return
    fi

    # Always keep the kustomization.yaml file
    local keep_files=("kustomization.yaml")
    
    # Check if .files.keep array exists and add those files to the keep list
    local keep_count=$(yq '.files.keep | length // 0' < "$FILE_BASENAME")
    if [ "$keep_count" -gt 0 ]; then
        for i in $(seq 0 $(($keep_count - 1))); do
            local file_to_keep=$(yq ".files.keep[$i]" < "$FILE_BASENAME")
            if [ "$file_to_keep" != "null" ]; then
                keep_files+=("$file_to_keep")
                echo "-> Will keep $file_to_keep"
            fi
        done
    fi
    
    # Create a temporary find exclude pattern
    local exclude_pattern=""
    for file in "${keep_files[@]}"; do
        exclude_pattern="${exclude_pattern} -not -name \"$file\""
    done
    
    # Find and remove files that are not in the keep list
    local cmd="find ./base -type f ${exclude_pattern} -exec rm -f {} \;"
    echo "-> Removing files from base directory except: ${keep_files[*]}"
    eval $cmd
    echo "-> Base directory cleaned"
}

_get_component_repo() {
    if [ -z "$1" ]; then
        warning "No Helm repo defined for $3"
        exit 0
    fi
    subTitle "Installing $1 Helm repo"
    if helm repo list | grep -q "^$1[[:space:]]"; then
        echo "-> $1 repo already installed"
    else
        helm repo add "$1" "$2" > /dev/null
    fi
    helm repo update > /dev/null
}

_get_component_defaults() {
    if [ -f "./default/${1}values.yaml" ]; then
        echo "-> Default values already generated"
    else
        echo "-> Get default values"
        helm show values --version "$3" "$2" > "./default/${1}values.yaml"
    fi
}

_get_component_templates() {
    echo "-> Get templates"
    helm template "$3" \
        -f "./default/${2}values.yaml" \
        -n $1 \
        --version "$5" \
        "$4" > "./base/$6.yaml"
}

_get_component_templates_with_crds() {
    echo "-> Get templates with CRD"
    helm template "$3" \
        -f "./default/$2values.yaml" \
        -n $1 \
        --include-crds \
        --version "$5" \
        "$4" > "./base/$6.yaml"
}

main
