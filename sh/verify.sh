source .env
forge verify-contract \
    --chain-id $(cast chain-id --rpc-url $MUMBAI) \
    --watch \
    --etherscan-api-key $POLYGONSCAN_API_KEY \
    --compiler-version v0.8.19 \
    0x61a984337058068b925f29ed43adc8382262d9e9 \
    src/example/CounterUpgradeable.sol:CounterUpgradeable