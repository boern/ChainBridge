#!/usr/bin/env bash

set -eux

ACCT="0xff93B45308FD417dF303D6515aB04D9e89a750Ca"

ETHA_URL="http://localhost:8545"
ETHB_URL="http://localhost:8546"

ERC20_RESOURCE_ID="0x00000000000000000000000021605f71845f372A9ed84253d2D024B7B10999f4"
ERC721_RESOURCE_ID="0x000000000000000000000000d7E33e1bbf65dC001A0Eb1552613106CD7e40C31"

ETHA_BRIDGE="0x62877dDCd49aD22f5eDfc6ac108e9a4b5D2bD88B"
ETHA_ERC20="0x21605f71845f372A9ed84253d2D024B7B10999f4"
ETHA_ERC20HANDLER="0x3167776db165D8eA0f51790CA2bbf44Db5105ADF"
ETHA_ERC721="0xd7E33e1bbf65dC001A0Eb1552613106CD7e40C31"
ETHA_ERC721HANDLER="0x3f709398808af36ADBA86ACC617FeB7F5B7B193E"
ETHA_ERC721_ID="0x99"

ETHB_BRIDGE="0x62877dDCd49aD22f5eDfc6ac108e9a4b5D2bD88B"
ETHB_ERC20="0x21605f71845f372A9ed84253d2D024B7B10999f4"
ETHB_ERC20HANDLER="0x3167776db165D8eA0f51790CA2bbf44Db5105ADF"
ETHB_ERC721="0xd7E33e1bbf65dC001A0Eb1552613106CD7e40C31"
ETHB_ERC721HANDLER="0x3f709398808af36ADBA86ACC617FeB7F5B7B193E"
ETHB_ERC721_ID="0x100"

# deploy
cb-sol-cli --url $ETHA_URL deploy --all --relayers $ACCT --relayerThreshold 1 --chainId 0
cb-sol-cli --url $ETHB_URL deploy --all --relayers $ACCT --relayerThreshold 1 --chainId 1

# register resource
cb-sol-cli --url $ETHA_URL bridge register-resource --bridge $ETHA_BRIDGE --handler $ETHA_ERC20HANDLER --resourceId $ERC20_RESOURCE_ID --targetContract $ETHA_ERC20
cb-sol-cli --url $ETHB_URL bridge register-resource --bridge $ETHB_BRIDGE --handler $ETHB_ERC20HANDLER --resourceId $ERC20_RESOURCE_ID --targetContract $ETHB_ERC20

# set burn
cb-sol-cli --url $ETHA_URL bridge set-burn --bridge $ETHA_BRIDGE --handler $ETHA_ERC20HANDLER --tokenContract $ETHA_ERC20
cb-sol-cli --url $ETHB_URL bridge set-burn --bridge $ETHB_BRIDGE --handler $ETHB_ERC20HANDLER --tokenContract $ETHB_ERC20

# add-admint
cb-sol-cli --url $ETHA_URL erc20 add-minter --erc20Address $ETHA_ERC20 --minter $ACCT
cb-sol-cli --url $ETHB_URL erc20 add-minter --erc20Address $ETHB_ERC20 --minter $ACCT
cb-sol-cli --url $ETHA_URL erc20 add-minter --erc20Address $ETHB_ERC20 --minter $ETHA_ERC20HANDLER
cb-sol-cli --url $ETHB_URL erc20 add-minter --erc20Address $ETHB_ERC20 --minter $ETHB_ERC20HANDLER

# mint erc20
cb-sol-cli --url $ETHA_URL erc20 mint --amount 100000 --erc20Address $ETHA_ERC20
sleep 5
cb-sol-cli --url $ETHA_URL erc20 balance --address $ACCT

cb-sol-cli --url $ETHB_URL erc20 mint --amount 100000 --erc20Address $ETHB_ERC20
sleep 5
cb-sol-cli --url $ETHB_URL erc20 balance --address $ACCT

# approve erc20
cb-sol-cli --url $ETHA_URL erc20 approve --amount 10000 --recipient $ETHA_ERC20HANDLER
cb-sol-cli --url $ETHB_URL erc20 approve --amount 10000 --recipient $ETHB_ERC20HANDLER


# register resource
cb-sol-cli --url $ETHA_URL bridge register-resource --bridge $ETHA_BRIDGE --handler $ETHA_ERC721HANDLER --resourceId $ERC721_RESOURCE_ID --targetContract $ETHA_ERC721
cb-sol-cli --url $ETHB_URL bridge register-resource --bridge $ETHB_BRIDGE --handler $ETHB_ERC721HANDLER --resourceId $ERC721_RESOURCE_ID --targetContract $ETHB_ERC721

# set burn
cb-sol-cli --url $ETHA_URL bridge set-burn --bridge $ETHA_BRIDGE --handler $ETHA_ERC721HANDLER --tokenContract $ETHA_ERC721
cb-sol-cli --url $ETHB_URL bridge set-burn --bridge $ETHB_BRIDGE --handler $ETHB_ERC721HANDLER --tokenContract $ETHB_ERC721

# add-admint
cb-sol-cli --url $ETHA_URL erc721 add-minter --erc721Address $ETHA_ERC721 --minter $ACCT
cb-sol-cli --url $ETHB_URL erc721 add-minter --erc721Address $ETHB_ERC721 --minter $ACCT
cb-sol-cli --url $ETHA_URL erc721 add-minter --erc721Address $ETHB_ERC721 --minter $ETHA_ERC721HANDLER
cb-sol-cli --url $ETHB_URL erc721 add-minter --erc721Address $ETHB_ERC721 --minter $ETHB_ERC721HANDLER

# mint erc721
cb-sol-cli --url $ETHA_URL erc721 mint --id $ETHA_ERC721_ID --erc721Address $ETHA_ERC721
sleep 5
cb-sol-cli --url $ETHA_URL erc721 owner --id $ETHA_ERC721_ID

cb-sol-cli --url $ETHB_URL erc721 mint --id $ETHB_ERC721_ID --erc721Address $ETHB_ERC721
sleep 5
cb-sol-cli --url $ETHB_URL erc721 owner --id $ETHB_ERC721_ID 

# approve erc721
# cb-sol-cli --url $ETHA_URL erc721 approve --id $ETHA_ERC721_ID --recipient $ETHA_ERC721HANDLER
# cb-sol-cli --url $ETHB_URL erc721 approve --id $ETHB_ERC721_ID --recipient $ETHB_ERC721HANDLER
