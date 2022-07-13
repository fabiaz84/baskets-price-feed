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

5. After the script has completed successfully, run the following commands in the second terminal:

    `cast rpc anvil_impersonateAccount 0xFC69e0a5823E2AfCBEb8a35d33588360F1496a00`

    ```
    cast send 0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8 \
    --from 0xFC69e0a5823E2AfCBEb8a35d33588360F1496a00 \
    "_supportMarket(address)(uint)" \
    0xAe120F0df055428E45b264E7794A18c54a2a3fAF \
    ```

    ```
    cast send 0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8 \
    --from 0xFC69e0a5823E2AfCBEb8a35d33588360F1496a00 \
    "_setCollateralFactor(address,uint)(uint)" \
    0xAe120F0df055428E45b264E7794A18c54a2a3fAF \
    500000000000000000 \
    ```  

    ```  
    cast send 0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8 \
    --from 0xFC69e0a5823E2AfCBEb8a35d33588360F1496a00 \
    "_setIMFFactor(address,uint)(uint)" \
    0xAe120F0df055428E45b264E7794A18c54a2a3fAF \
    40000000000000000 \
    ```  

    ```  
    cast rpc anvil_impersonateAccount 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266  
    cast send 0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8 \
    --from 0xFC69e0a5823E2AfCBEb8a35d33588360F1496a00 \
    "_setReserveFactor(uint)(uint)" \
    500000000000000000 \ 
    ```     

## Tests

1. run:

    `forge test --match-contract bSTBLTest --fork-url https://eth-mainnet.alchemyapi.io/v2/xxxxxxxxxxx -vv --use 0.8.1`