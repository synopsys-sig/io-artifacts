#!/bin/bash

# Copyright (c) 2021 Synopsys, Inc. All rights reserved worldwide.

run() {
    box_line "Synopsys Intelligent Security Scan" "Copyright 2016-2020 Synopsys, Inc. All rights reserved worldwide."
    allargs="${ARGS[@]}"
    
    config_file="io-manifest.yml"
    
    for i in "${ARGS[@]}"; do
        case "$i" in
        --stage=*) stage="${i#*=}" ;;
        --workflow.version=*) workflow_version="${i#*=}" ;;
        *) ;;
        esac
    done
	
    #validate stage
    validate_values "STAGE" "$stage"

    box_star "Current Stage is set to ${stage}"

    #method to generate synopsys-io.yml file
    generateYML "${ARGS[@]}"
    
    if [[ "${stage}" == "IO" ]]; then
        getIOPrescription "${ARGS[@]}"
    elif [[ "${stage}" == "WORKFLOW" ]]; then
        loadWorkflow "${ARGS[@]}"
    else
        exit_program "Invalid Stage"
    fi
}

function generateYML () {
    for i in "$@"; do
        case "$i" in
        --io.url=*) io_url="${i#*=}" ;;
        --io.token=*) io_token="${i#*=}" ;;
	--io.manifest.url=*) io_manifest_url="${i#*=}" ;;
        --release.type=*) release_type="${i#*=}" ;;
        --file.change.threshold=*) file_change_threshold="${i#*=}" ;;
        --sast.rescan.threshold=*) sast_rescan_threshold="${i#*=}" ;;
        --sca.rescan.threshold=*) sca_rescan_threshold="${i#*=}" ;;
        --workflow.url=*) workflow_url="${i#*=}" ;;
        --sensitive.package.pattern=*) sensitive_package="${i#*=}" ;;
        --asset.id=*) asset_id="${i#*=}" ;;
        --slack.channel.id=*) slack_channel_id="${i#*=}" ;;    #slack
        --slack.token=*) slack_token="${i#*=}" ;;
        --jira.project.name=*) jira_project_name="${i#*=}" ;;    #jira
        --jira.assignee=*) jira_assignee="${i#*=}" ;;
        --jira.api.url=*) jira_api_url="${i#*=}" ;;
        --jira.issues.query=*) jira_issues_query="${i#*=}" ;;
        --jira.username=*) jira_username="${i#*=}" ;;
        --jira.auth.token=*) jira_auth_token="${i#*=}" ;;
        --scm.type=*) scm_type="${i#*=}" ;;    #scm
        --scm.owner=*) scm_owner="${i#*=}" ;;
        --scm.repo.name=*) scm_repo_name="${i#*=}" ;;
        --scm.branch.name=*) scm_branch_name="${i#*=}" ;;
        --bitbucket.workspace=*) bitbucket_workspace="${i#*=}" ;;    #bitbucket
        --bitbucket.commit.id=*) bitbucket_commit_id="${i#*=}" ;;
        --bitbucket.username=*) bitbucket_username="${i#*=}" ;;
        --bitbucket.password=*) bitbucket_password="${i#*=}" ;;
        --github.owner.name=*) github_owner_name="${i#*=}" ;;         #github
        --github.repository.name=*) github_repo_name="${i#*=}" ;;
        --github.ref=*) github_ref="${i#*=}" ;;
        --github.commit.id=*) github_commit_id="${i#*=}" ;;
        --github.username=*) github_username="${i#*=}" ;;
        --github.token=*) github_access_token="${i#*=}" ;;
        --IS_SAST_ENABLED=*) is_sast_enabled="${i#*=}" ;;             #polaris
        --polaris.project.name=*) polaris_project_name="${i#*=}" ;;
        --polaris.url=*) polaris_server_url="${i#*=}" ;;
        --polaris.token=*) polaris_access_token="${i#*=}" ;;
        --IS_SCA_ENABLED=*) is_sca_enabled="${i#*=}" ;;                 #blackduck
        --blackduck.project.name=*) blackduck_project_name="${i#*=}" ;;
        --blackduck.url=*) blackduck_server_url="${i#*=}" ;;
        --blackduck.api.token=*) blackduck_access_token="${i#*=}" ;;
        --coverity.url=*) coverity_server_url="${i#*=}" ;;
        --coverity.username=*) coverity_username="${i#*=}" ;;
        --coverity.password=*) coverity_password="${i#*=}" ;;
        --persona=*) persona="${i#*=}" ;;
        *) ;;
        esac
    done
    
    validate_values "IO_SERVER_URL" "$io_url"
    validate_values "IO_SERVER_TOKEN" "$io_token"
    
    #checks if the synopsys-io.yml present
    is_synopsys_config_present

    asset_id_from_yml=$(ruby -r yaml -e 'puts YAML.load_file(ARGV[0])["application"]["assetId"]' $config_file)

    if [[ "${asset_id_from_yml}" == "<<ASSET_ID>>" ]]; then
        create_io_asset
    else
        asset_id=${asset_id_from_yml}
    fi
    
    if [ -z "$file_change_threshold" ]; then
        file_change_threshold=20
    fi
    
    if [ -z "$sast_rescan_threshold" ]; then
        sast_rescan_threshold=10
    fi
    
    if [ -z "$sca_rescan_threshold" ]; then
        sca_rescan_threshold=10
    fi

    synopsys_io_manifest=$(cat io-manifest.yml |
        sed " s~<<SLACK_CHANNEL_ID>>~$slack_channel_id~g; \
	    s~<<SLACK_TOKEN>>~$slack_token~g; \
	    s~<<JIRA_PROJECT_NAME>>~$jira_project_name~g; \
	    s~<<JIRA_ASSIGNEE>>~$jira_assignee~g; \
	    s~<<JIRA_API_URL>>~$jira_api_url~g; \
	    s~<<JIRA_ISSUES_QUERY>>~$jira_issues_query~g; \
	    s~<<JIRA_USERNAME>>~$jira_username~g; \
	    s~<<JIRA_AUTH_TOKEN>>~$jira_auth_token~g; \
	    s~<<BITBUCKET_COMMIT_ID>>~$bitbucket_commit_id~g; \
	    s~<<BITBUCKET_USERNAME>>~$bitbucket_username~g; \
	    s~<<BITBUCKET_PASSWORD>>~$bitbucket_password~g; \
	    s~<<GITHUB_OWNER_NAME>>~$github_owner_name~g; \
	    s~<<GITHUB_REPO_NAME>>~$github_repo_name~g; \
	    s~<<GITHUB_REF>>~$github_ref~g; \
	    s~<<GITHUB_COMMIT_ID>>~$github_commit_id~g; \
	    s~<<GITHUB_USERNAME>>~$github_username~g; \
	    s~<<GITHUB_ACCESS_TOKEN>>~$github_access_token~g; \
	    s~<<POLARIS_PROJECT_NAME>>~$polaris_project_name~g; \
	    s~<<POLARIS_SERVER_URL>>~$polaris_server_url~g; \
	    s~<<POLARIS_ACCESS_TOKEN>>~$polaris_access_token~g; \
	    s~<<BLACKDUCK_PROJECT_NAME>>~$blackduck_project_name~g; \
	    s~<<BLACKDUCK_SERVER_URL>>~$blackduck_server_url~g; \
	    s~<<BLACKDUCK_ACCESS_TOKEN>>~$blackduck_access_token~g; \
	    s~<<COVERITY_SERVER_URL>>~$coverity_server_url~g; \
	    s~<<COVERITY_USERNAME>>~$coverity_username~g; \
	    s~<<COVERITY_PASSWORD>>~$coverity_password~g; \
            s~<<IS_SAST_ENABLED>>~$is_sast_enabled~g; \
            s~<<IS_SCA_ENABLED>>~$is_sca_enabled~g; \
	    s~<<APP_ID>>~$asset_id~g; \
	    s~<<ASSET_ID>>~$asset_id~g; \
            s~<<RELEASE_TYPE>>~$release_type~g; \
	    s~<<SENSITIVE_PACKAGE_PATTERN>>~$sensitive_package~g; \
	    s~<<FILE_CHANGE_THRESHOLD>>~$file_change_threshold~g; \
	    s~<<SAST_RESCAN_THRESHOLD>>~$sast_rescan_threshold~g; \
	    s~<<SCA_RESCAN_THRESHOLD>>~$sca_rescan_threshold~g; \
	    s~<<SCM_TYPE>>~$scm_type~g; \
	    s~<<SCM_OWNER>>~$scm_owner~g; \
	    s~<<SCM_REPO_NAME>>~$scm_repo_name~g; \
	    s~<<SCM_BRANCH_NAME>>~$scm_branch_name~g")
    
    # apply the yml with the substituted value
    echo "$synopsys_io_manifest" >synopsys-io.yml

    echo "synopsys-io.yml generated"
}

function loadWorkflow() {
    #validates mandatory arguments for IO
    validate_values "WORKFLOW_SERVER_URL" "$workflow_url"
    
    #checks if WorkflowClient.jar is present
    is_workflow_client_jar_present
    
    asset_id_from_yml=$(ruby -r yaml -e 'puts YAML.load_file(ARGV[0])["application"]["assetId"]' synopsys-io.yml)
    curr_date=$(date +'%Y-%m-%d')
   
    scandate_json="{\"assetId\": \"${asset_id_from_yml}\",\"activities\":{"
    if [ "$is_sast_enabled" = true ] ; then
       scandate_json="$scandate_json\"sast\": {\"lastScanDate\": \"${curr_date}\"}"
    fi
    if [ "$is_sca_enabled" = true ] && [ "$is_sast_enabled" = true ] ; then
       scandate_json="$scandate_json,"
    fi
    if [ "$is_sca_enabled" = true ] ; then
       scandate_json="$scandate_json\"sca\": {\"lastScanDate\": \"${curr_date}\"}"
    fi
    scandate_json="$scandate_json}}"
    echo "$scandate_json" >scandate.json
    echo "$scandate_json"
	
    echo "updating last scan date for perfomed security activities"
    header='Authorization: Bearer '$io_token''
    scandateresponse=$(curl -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -H "${header}" -d @scandate.json ${io_url}/io/api/manifest/update/scandate)
    echo $scandateresponse
}

function getIOPrescription() {

    echo "Inside Prescription"
	
    #validates mandatory arguments for IO
    validate_values "IO_ASSET_ID" "$asset_id"
    validate_values "SCM_TYPE" "$scm_type"
    validate_values "SCM_OWNER" "$scm_owner"
    validate_values "REPOSITORY_NAME" "$scm_repo_name"
    validate_values "BRANCH_NAME" "$scm_branch_name"
    
    printf "IO Asset ID: ${asset_id}\n"
    printf "SCM TYPE: ${scm_type}\n"
    printf "Using the repository ${scm_repo_name} and branch ${scm_branch_name}. Action triggered by ${scm_owner}\n\n"
	
    #chosing API - if persona is set to "developer" then "/api/manifest/update/persona/developer" will be called
    #chosing API - if persona is empty then "/api/manifest/update" will be called
    if [[ -z $persona ]]; then
        API="update"
    else
        API="update/persona/$persona"
    fi

    header='Authorization: Bearer '$io_token''

    #Yaml to Json Conversion
    cat synopsys-io.yml
    echo $(ruby -ryaml -rjson -e "puts JSON.pretty_generate(YAML.safe_load(File.read('synopsys-io.yml')))") >data.json
    cat data.json
    echo "Getting Prescription"
    prescrip=$(curl -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -H "${header}" -d @data.json ${io_url}/io/api/manifest/${API})
    echo $prescrip
    echo $prescrip >result.json
}

function validate_values () {
    key=$1
    value=$2
    if [ -z "$value" ]; then
        exit_program "$key value is null"
    fi
}

function is_synopsys_config_present () {
    if [ ! -f "$config_file" ]; then
        printf "${config_file} file does not exist\n"
        printf "Downloading default ${config_file}\n"
        if [ -z "$io_manifest_url" ]; then
            wget https://raw.githubusercontent.com/synopsys-sig/io-artifacts/${workflow_version}/prescription.sh
        else
            wget "$io_manifest_url"
	fi
    fi
}

function is_workflow_client_jar_present () {
    if [ ! -f "WorkflowClient.jar" ]; then
        printf "WorkflowClient.jar file does not exist\n"
        printf "Downloading default WorkflowClient.jar\n"
        wget https://sigdevsecops.blob.core.windows.net/intelligence-orchestration/${workflow_version}/WorkflowClient.jar
    fi
}

function create_io_asset () {	
    validate_values "IO_SERVER_URL" "$io_url"
    validate_values "IO_SERVER_TOKEN" "$io_token"
    validate_values "IO_ASSET_ID" "$asset_id"

    onBoardingResponse=$(curl --location --request POST "$io_url/io/api/applications/update" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $io_token" \
    --data-raw '{
        "assetId": '\"$asset_id\"',
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

    echo $onBoardingResponse
}

function box_line () {
    arg1=$1
    arg2=$2
    len=$((${#arg2}+5))
    box_str="\n+"
    for i in $(seq $len); do box_str="$box_str-"; done;
    box_str="$box_str+\n| "$arg1" "$(printf '%*s' 33)" |\n"
    box_str="$box_str| "$arg2" "$(printf '%*s' 2)" |\n+"
    for i in $(seq $len); do box_str="$box_str-"; done;
    box_str="$box_str+\n\n"
    printf "$box_str"
}

function box_star () {
    str="$@"
    len=$((${#str}+4))
    box_str="\n\n"
    for i in $(seq $len); do box_str="$box_str*"; done;
    box_str="$box_str\n* "$str" *\n"
    for i in $(seq $len); do box_str="$box_str*"; done;
    box_str="$box_str\n\n"
    printf "$box_str"
}

function exit_program () {
    message=$1
    printf '\e[31m%s\e[0m\n' "$message"
    printf '\e[31m%s\e[0m\n' "Exited with error code 1"
    exit 1
}

ARGS=("$@")

run
