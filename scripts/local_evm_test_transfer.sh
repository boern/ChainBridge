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

# transfer erc20 from ETHA to ETHB
cb-sol-cli --url $ETHA_URL erc20 deposit --amount 50 --dest 1 --recipient $ACCT --resourceId $ERC20_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHB_URL erc20 balance --address $ACCT

# transfer erc20 from ETHB to ETHA
cb-sol-cli --url $ETHB_URL erc20 deposit --amount 50 --dest 0 --recipient $ACCT --resourceId $ERC20_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHA_URL erc20 balance --address $ACCT

# approve erc721
cb-sol-cli --url $ETHA_URL erc721 approve --id $ETHA_ERC721_ID --recipient $ETHA_ERC721HANDLER
# transfer erc721 from ETHA to ETHB
cb-sol-cli --url $ETHA_URL erc721 deposit --id $ETHA_ERC721_ID --dest 1 --recipient $ACCT --resourceId $ERC721_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHB_URL erc721 owner --id $ETHA_ERC721_ID

# approve erc721
cb-sol-cli --url $ETHB_URL erc721 approve --id $ETHA_ERC721_ID --recipient $ETHB_ERC721HANDLER
# transfer erc721 back to ETHA
cb-sol-cli --url $ETHB_URL erc721 deposit --id $ETHA_ERC721_ID --dest 0 --recipient $ACCT --resourceId $ERC721_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHA_URL erc721 owner --id $ETHA_ERC721_ID

# approve erc721
cb-sol-cli --url $ETHB_URL erc721 approve --id $ETHB_ERC721_ID --recipient $ETHB_ERC721HANDLER
# transfer erc721 from ETHB to ETHA
cb-sol-cli --url $ETHB_URL erc721 deposit --id $ETHB_ERC721_ID --dest 0 --recipient $ACCT --resourceId $ERC721_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHA_URL erc721 owner --id $ETHB_ERC721_ID

# approve erc721
cb-sol-cli --url $ETHA_URL erc721 approve --id $ETHB_ERC721_ID --recipient $ETHA_ERC721HANDLER
# transfer erc721 back to ETHB
cb-sol-cli --url $ETHA_URL erc721 deposit --id $ETHB_ERC721_ID --dest 1 --recipient $ACCT --resourceId $ERC721_RESOURCE_ID
sleep 30
cb-sol-cli --url $ETHB_URL erc721 owner --id $ETHB_ERC721_ID

