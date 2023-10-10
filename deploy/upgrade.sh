upgrade() {
    NETWORK=$1
    CONTRACT=$2

    DIR_PATH=./deployments/$NETWORK
	ADDRESSES_FILE=$DIR_PATH/$CONTRACT.json

    latestStorage=$(jq '.implementations | to_entries | map(.value.storageLayout) | last' $ADDRESSES_FILE)
    upcomingStorage=$(forge inspect $CONTRACT storage)
    
    if [ ! -d "./temp" ]; then
        mkdir -p "./temp"
        echo "Directory created: ./temp"
    fi

    echo "$latestStorage" > "./temp/latest.json"
    echo "$upcomingStorage" > "./temp/upcoming.json"

    echo "Diff between latest and upcoming storage"
    diff --color -u ./temp/latest.json ./temp/upcoming.json
    echo "\n"
    read  -n 1 -p "Confirm to upgrade (y/n): " selection
    echo "\n"
    
    if [ "$selection" = "y" ]; then
        rm -rf ./temp
        echo "Upgrading..."
        RAW_RETURN_DATA=$(forge script script/Upgrade.s.sol -f $NETWORK -vvvv --json --silent --broadcast --verify)
        RETURN_DATA=$(echo $RAW_RETURN_DATA | jq -r '.returns' 2> /dev/null)
        proxy=$(echo $RETURN_DATA | jq -r '.proxy.value')
        implementation=$(echo $RETURN_DATA | jq -r '.implementation.value')
        saveProxyContract $NETWORK $CONTRACT $proxy $implementation
        echo "\nProxy address: $proxy"
        echo "\nNew implementation deployed at address: $implementation"
    else
        echo "The upgrade contract process was refused."
    fi
}

saveProxyContract() {
    NETWORK=$1
	CONTRACT=$2
    PROXY_ADDRESS=$3
	IMPL_ADDRESS=$4

    DIR_PATH=./deployments/$NETWORK
	ADDRESSES_FILE=$DIR_PATH/$CONTRACT.json

    if [ ! -d "$DIR_PATH" ]; then
        mkdir -p "$DIR_PATH"
        echo "Directory created: $DIR_PATH"
    fi

    if [[ ! -e $ADDRESSES_FILE ]]; then
		echo "{\"proxy\": \"$PROXY_ADDRESS\", \"implementations\": {}}" >"$ADDRESSES_FILE"
        echo "File created: $ADDRESSES_FILE"
	fi

    ABI=$(forge inspect $CONTRACT abi)
    METADATA=$(forge inspect $CONTRACT metadata)
    STORAGE=$(forge inspect $CONTRACT storage)

	result=$(cat "$ADDRESSES_FILE" | jq -r ".implementations += {\"$IMPL_ADDRESS\": {\"abi\": $ABI, \"metadata\": $METADATA, \"storageLayout\": $STORAGE}}")
	printf %s "$result" >"$ADDRESSES_FILE"
}

upgrade $1 $2
