#!/bin/bash

# Copyright (c) 2021 Synopsys, Inc. All rights reserved worldwide.

for i in "$@"; do
    case "$i" in
    --io.url=*) ioUrl="${i#*=}" ;;
    --io.token=*) ioToken="${i#*=}" ;;
    --asset.id=*) assetId="${i#*=}" ;;
    --workflow.version=*) workflow_version="${i#*=}" ;;
    --manifest.type=*) manifest_type="${i#*=}" ;;
    --calculator.meta.path=*) metaPath="${i#*=}" ;;
    --tpi.path=*) tpiPath="${i#*=}" ;;
    *) ;;
    esac
done

if [ -z "$workflow_version" ]; then
    workflow_version="2021.10.0"
fi

if [ -z "$manifest_type" ]; then
    manifest_type="yml"
fi
	
if [[ "$manifest_type" == "json" ]]; then
    config_file="io-manifest.json"
elif [[ "$manifest_type" == "yml" ]]; then
    config_file="io-manifest.yml"
fi

printf "IO Manifest Type: ${manifest_type}\n"

tpidata=$(cat $tpiPath | sed " s~<<ASSET_ID>>~$assetId~g")

onBoardingResponse=$(curl --location --request POST "$ioUrl/io/api/applications/update" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ioToken" \
--data-raw "$tpidata");

if [ "$onBoardingResponse" = "TPI Data created/updated successfully" ] ; then
    metadata=$(cat $metaPath)
	
    calculatorResponse=$(curl --location --request POST "$ioUrl/io/api/calculator/update" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $ioToken" \
    --data-raw "$metadata");
	
    if [ "$calculatorResponse" != "Updated Successfully" ] ; then
        echo $calculatorResponse;
        exit 1;
    fi
	
    if [ ! -f "${config_file}" ]; then
        printf "${config_file} file does not exist\n"
        printf "Downloading default ${config_file}\n"
        wget "https://raw.githubusercontent.com/synopsys-sig/io-artifacts/${workflow_version}/${config_file}"
    fi

    workflow=$(cat ${config_file} | sed "s~<<ASSET_ID>>~$assetId~g; s~<<APP_ID>>~$assetId~g")
    # apply the yml with the substituted value
    echo "$workflow" >${config_file}

    printf "IO ASSET ID: ${assetId}\n"
    printf "INFO: ${config_file} is generated. Please update the source code management details in it and add the file to the root of the project.\n"
else
    echo $onBoardingResponse;
    exit 1;
fi
