## foundry-template-3coor

# Install dependencies

forge install <git-name/repo-name> --no-git

# Common script

forge compile
forge test
forge clean

# Deploy script

forge script script/<script contract>:<contract name> --rpc-url $<rpc-constant-env> --json deployment/<contract name>.json --broadcast --verify -vvvv


