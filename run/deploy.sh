deploy() {
    if [ -f .env ]; then
        source .env
    else
        echo Error: .debug.env file not found.
    fi

    echo Deploying...

	NETWORK=$1
    CONTRACT=$2
    SCRIPT_PATH=$3
    
	RAW_RETURN_DATA=$(forge script $SCRIPT_PATH -f $NETWORK --json --silent --broadcast --verify -vvvv)

	RETURN_DATA=$(echo $RAW_RETURN_DATA | jq -r '.returns' 2> /dev/null)
	DEPLOYMENT=$(echo $RETURN_DATA | jq -r '.deployment.value')

    PROXY=$(echo $RETURN_DATA | jq -r '.proxy.value')
    IMPLEMENTATION=$(echo $RETURN_DATA | jq -r '.implementation.value')
    KIND=$(echo $RETURN_DATA | jq -r '.kind.value')

    if [ -z "$PROXY" ] && [ -z "$DEPLOYMENT" ] ; then
        exit 0
    fi

    if [ "$DEPLOYMENT" = "null" ] ; then
        saveDeploymentArtifact $NETWORK $CONTRACT $PROXY $IMPLEMENTATION $KIND
        echo Implementation deployed at address $IMPLEMENTATION
        echo The $KIND proxy deployed at address $PROXY
    else
        saveDeploymentArtifact $NETWORK $CONTRACT $DEPLOYMENT
        echo Contract deployed at address $DEPLOYMENT
    fi
}

saveDeploymentArtifact() {
    NETWORK=$1
    CONTRACT=$2
    ADDRESS_OR_PROXY=$3
    IMPL_ADDRESS=$4
    PROXY_TYPE=$5

    # constant
    DIR_PATH=./deployments/$NETWORK
    ADDRESSES_FILE=$DIR_PATH/$CONTRACT.json
    ABI=$(forge inspect $CONTRACT abi)
    METADATA=$(forge inspect $CONTRACT metadata)
    STORAGE=$(forge inspect $CONTRACT storage)

    # create directory if it doesn't exist
    if [ ! -d "$DIR_PATH" ]; then
        mkdir -p "$DIR_PATH"
        echo Directory created: $DIR_PATH
    fi

    # create template file if `addresses_file` already
    if [[ ! -e "$ADDRESSES_FILE" ]]; then
        if [ -n "$PROXY_ADDRESS" ]; then
            echo "{\"proxy\": \"$PROXY_ADDRESS\", \"kind\": \"$PROXY_TYPE\", \"implementations\": {}}" > "$ADDRESSES_FILE"
        else
            echo "{}" >"$ADDRESSES_FILE"
        fi
        echo File created: $ADDRESSES_FILE
    fi

    # if `impl_address` and `proxy_type` not null
    # then passing the artifact info to file
    if [ -n "$IMPL_ADDRESS" ] && [ -n "$PROXY_TYPE" ]; then
        result=$(cat "$ADDRESSES_FILE" | jq -r ".implementations += {\"$IMPL_ADDRESS\": {\"abi\": $ABI, \"metadata\": $METADATA, \"storageLayout\": $STORAGE}}")
    else
        result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"address\": \"$ADDRESS\", \"abi\": $ABI, \"metadata\": $METADATA, \"storageLayout\": $STORAGE}")
    fi

    printf %s "$result" >"$ADDRESSES_FILE"
}

deploy $1 $2 $3
