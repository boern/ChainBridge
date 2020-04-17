package ethtest

import (
	"math/big"
	"testing"

	msg "github.com/ChainSafe/ChainBridge/message"
	utils "github.com/ChainSafe/ChainBridge/shared/ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func RegisterErc721Resource(t *testing.T, client *ethclient.Client, opts *bind.TransactOpts, handler common.Address, rId msg.ResourceId, addr common.Address) {
	err := utils.RegisterErc721Resource(client, opts, handler, rId, addr)
	if err != nil {
		t.Fatal(err)
	}
}

func DeployMintApproveErc721(t *testing.T, client *ethclient.Client, opts *bind.TransactOpts, handler common.Address, id *big.Int) common.Address {
	addr, err := utils.DeployMintApproveErc721(client, opts, handler, id)
	if err != nil {
		t.Fatal(err)
	}
	return addr
}

func IsOwner(t *testing.T, client *ethclient.Client, erc721Contract common.Address, tokenId *big.Int, expected common.Address) {
	addr, err := utils.OwnerOf(client, erc721Contract, tokenId)
	if err != nil {
		t.Fatal(err)
	}

	if addr != expected {
		t.Fatalf("address %s does not own %x, %s does", expected.Hex(), tokenId.Bytes(), addr.Hex())
	}
}