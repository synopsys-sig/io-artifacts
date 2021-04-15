#!/bin/sh

# Copyright (c) 2021 Synopsys, Inc. All rights reserved worldwide.

for i in "$@"; do
    case "$i" in
    --io.url=*) ioUrl="${i#*=}" ;;
    --io.token=*) ioToken="${i#*=}" ;;
    --asset.id=*) assetId="${i#*=}" ;;
    --calculator.meta.path=*) metaPath="${i#*=}" ;;
    *) ;;
    esac
done

onBoardingResponse=$(curl --location --request POST "$ioUrl/io/api/applications/update" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $ioToken" \
--data-raw '{
    "assetId": '\"$assetId\"',
    "assetType": "Application",
    "applicationType": "Financial",
    "applicationName": "Test app 1",
    "applicationBuildName": "test-build",
    "soxFinancial": true,
    "ppi": true,
    "mnpi": true,
    "infoClass": "Restricted",
    "customerFacing": true,
    "externallyFacing": true,
    "assetTier": "Tier 01",
    "fairLending": true
}');

if [ "$onBoardingResponse" = "TPI Data created/updated successfully" ] ; then
    metadata=`cat $metaPath`
	
    calculatorResponse=$(curl --location --request POST "$ioUrl/io/api/calculator/update" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $ioToken" \
    --data-raw "$metadata");
	
    if [ "$calculatorResponse" != "Updated Successfully" ] ; then
        echo $calculatorResponse;
        exit 1;
    fi
	
    wget https://sigdevsecops.blob.core.windows.net/intelligence-orchestration/2021.01/io-manifest.yml
    workflow=$(cat io-manifest.yml | sed " s~<<ASSET_ID>>~$assetId~g; s~<<APP_ID>>~$assetId~g")
    # apply the yml with the substituted value
    echo "$workflow" >io-manifest.yml

    echo "IO ASSET ID: $assetId"
    echo "INFO: io-manifest.yml is generated. Please update the source code management details in it and add the file to the root of the project."
else
    echo $onBoardingResponse;
    exit 1;
fi
