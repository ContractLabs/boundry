deploy() {
	NETWORK=$1
    CONTRACT=$2

    #config script run
	RAW_RETURN_DATA=$(forge script script/Deploy.s.sol -f $NETWORK -vvvv --json --silent --broadcast --verify)
	RETURN_DATA=$(echo $RAW_RETURN_DATA | jq -r '.returns' 2> /dev/null)
	deployment=$(echo $RETURN_DATA | jq -r '.deployment.value')

    if [ "$deployment" = "null" ] ; then
        proxy=$(echo $RETURN_DATA | jq -r '.proxy.value')
        implementation=$(echo $RETURN_DATA | jq -r '.implementation.value')
        kind=$(echo $RETURN_DATA | jq -r '.kind.value')
        saveProxyContract $NETWORK $CONTRACT $proxy $implementation $kind

        echo "\nImplementation deployed at address $implementation"
        echo "\nThe $kind proxy deployed at address $proxy"
    else
        saveContract $NETWORK $CONTRACT $deployment
        echo "\nContract deployed at address $deployment"
    fi
}

saveContract() {
	NETWORK=$1
	CONTRACT=$2
	ADDRESS=$3

    DIR_PATH=./deployments/$NETWORK
	ADDRESSES_FILE=$DIR_PATH/$CONTRACT.json

    if [ ! -d "$DIR_PATH" ]; then
        mkdir -p "$DIR_PATH"
        echo "Directory created: $DIR_PATH"
    fi

    if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{}" >"$ADDRESSES_FILE"
        echo "File created: $ADDRESSES_FILE"
	fi

    ABI=$(forge inspect $CONTRACT abi)
    METADATA=$(forge inspect $CONTRACT metadata)
    STORAGE=$(forge inspect $CONTRACT storage)
	# create an empty json if it does not exist
	
	result=$(cat "$ADDRESSES_FILE" | jq -r ". + {\"address\": \"$ADDRESS\", \"abi\": $ABI, \"metadata\": $METADATA, \"storageLayout\": $STORAGE}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

saveProxyContract() {
    NETWORK=$1
	CONTRACT=$2
    PROXY_ADDRESS=$3
	IMPL_ADDRESS=$4
    PROXY_TYPE=$5

    DIR_PATH=./deployments/$NETWORK
	ADDRESSES_FILE=$DIR_PATH/$CONTRACT.json

    if [ ! -d "$DIR_PATH" ]; then
        mkdir -p "$DIR_PATH"
        echo "Directory created: $DIR_PATH"
    fi

    if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{\"proxy\": \"$PROXY_ADDRESS\",  \"kind\": \"$PROXY_TYPE\", \"implementations\": {}}" >"$ADDRESSES_FILE"
        echo "File created: $ADDRESSES_FILE"
	fi

    ABI=$(forge inspect $CONTRACT abi)
    METADATA=$(forge inspect $CONTRACT metadata)
    STORAGE=$(forge inspect $CONTRACT storage)

	result=$(cat "$ADDRESSES_FILE" | jq -r ".implementations += {\"$IMPL_ADDRESS\": {\"abi\": $ABI, \"metadata\": $METADATA, \"storageLayout\": $STORAGE}}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

deploy $1 $2
