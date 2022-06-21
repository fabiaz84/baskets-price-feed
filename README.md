# baskets-price-feed

## Enable bSTBL as Collateral localy

### On Linux/Mac

1. run: 

    `curl -L https://foundry.paradigm.xyz | bash`

    `foundryup`

    `forge build`

2. Get fork URL (e.g. from alchemy https://eth-mainnet.alchemyapi.io/v2/xxxxxxxxxxx)   

3. run anvil

    `anvil --fork-url https://eth-mainnet.alchemyapi.io/v2/xxxxxxxxxxx`

4. Select one of the listed private keys and run the following in a second terminal:

    `forge script ./src/scripts/enableBstbl.s.sol:bSTBLScript --fork-url http://localhost:8545  --private-key <SELECTED_PRIVATE_KEY> --broadcast`