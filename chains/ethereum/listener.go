// Copyright 2020 ChainSafe Systems
// SPDX-License-Identifier: LGPL-3.0-only

package ethereum

import (
	"fmt"
	"math/big"
	"time"

	"github.com/ChainSafe/ChainBridge/bindings/Bridge"
	centrifugeHandler "github.com/ChainSafe/ChainBridge/bindings/CentrifugeAssetHandler"
	erc20Handler "github.com/ChainSafe/ChainBridge/bindings/ERC20Handler"
	erc721Handler "github.com/ChainSafe/ChainBridge/bindings/ERC721Handler"
	"github.com/ChainSafe/ChainBridge/blockstore"
	"github.com/ChainSafe/ChainBridge/chains"
	msg "github.com/ChainSafe/ChainBridge/message"
	utils "github.com/ChainSafe/ChainBridge/shared/ethereum"
	"github.com/ChainSafe/log15"
	eth "github.com/ethereum/go-ethereum"
	ethcommon "github.com/ethereum/go-ethereum/common"
	ethtypes "github.com/ethereum/go-ethereum/core/types"
)

var BlockRetryInterval = time.Second * 2

type Subscription struct {
	signature utils.EventSig
	handler   evtHandlerFn
}

type ActiveSubscription struct {
	ch  <-chan ethtypes.Log
	sub eth.Subscription
}

type Listener struct {
	cfg                    Config
	conn                   *Connection
	subscriptions          map[utils.EventSig]*Subscription
	router                 chains.Router
	bridgeContract         *Bridge.Bridge // instance of bound bridge contract
	erc20HandlerContract   *erc20Handler.ERC20Handler
	erc721HandlerContract  *erc721Handler.ERC721Handler
	genericHandlerContract *centrifugeHandler.CentrifugeAssetHandler
	log                    log15.Logger
	blockstore             blockstore.Blockstorer
}

func NewListener(conn *Connection, cfg *Config, log log15.Logger, bs blockstore.Blockstorer) *Listener {
	return &Listener{
		cfg:           *cfg,
		conn:          conn,
		subscriptions: make(map[utils.EventSig]*Subscription),
		log:           log,
		blockstore:    bs,
	}
}

func (l *Listener) SetContracts(bridge *Bridge.Bridge, erc20Handler *erc20Handler.ERC20Handler, erc721Handler *erc721Handler.ERC721Handler, genericHandler *centrifugeHandler.CentrifugeAssetHandler) {
	l.bridgeContract = bridge
	l.erc20HandlerContract = erc20Handler
	l.erc721HandlerContract = erc721Handler
	l.genericHandlerContract = genericHandler
}

func (l *Listener) SetRouter(r chains.Router) {
	l.router = r
}

// Start registers all subscriptions provided by the config
func (l *Listener) Start() error {
	l.log.Debug("Starting listener...")

	go func() {
		err := l.pollBlocks()
		if err != nil {
			l.log.Error("Polling blocks failed", "err", err)
		}
	}()

	return nil
}

//pollBlocks continously check the blocks for subscription logs, and sends messages to the router if logs are encountered
// stops where there are no subscriptions, and sleeps if we are at the current block
func (l *Listener) pollBlocks() error {
	l.log.Debug("Polling Blocks...")
	var latestBlock = l.cfg.startBlock
	for {
		currBlock, err := l.conn.conn.BlockByNumber(l.conn.ctx, nil)
		if err != nil {
			return fmt.Errorf("unable to get latest block: %s", err)
		}
		if currBlock.Number().Cmp(latestBlock) < 0 {
			time.Sleep(BlockRetryInterval)
			continue
		}

		err = l.getDepositEventsForBlock(latestBlock)
		if err != nil {
			return err
		}

		err = l.blockstore.StoreBlock(latestBlock)
		if err != nil {
			return err
		}
		latestBlock.Add(latestBlock, big.NewInt(1))
	}
}

func (l *Listener) getDepositEventsForBlock(latestBlock *big.Int) error {
	query := buildQuery(l.cfg.bridgeContract, utils.Deposit, latestBlock, latestBlock)

	logs, err := l.conn.conn.FilterLogs(l.conn.ctx, query)
	if err != nil {
		return fmt.Errorf("unable to Filter Logs: %s", err)
	}

	for _, log := range logs {
		var m msg.Message
		addr := ethcommon.BytesToAddress(log.Topics[2].Bytes())
		destId := msg.ChainId(log.Topics[1].Big().Uint64())
		nonce := msg.Nonce(log.Topics[3].Big().Uint64())

		if addr == l.cfg.erc20HandlerContract {
			m = l.handleErc20DepositedEvent(destId, nonce)
		} else {
			l.log.Error("Event has unrecognized handler", "handler", addr)
		}

		err = l.router.Send(m)
		if err != nil {
			l.log.Error("subscription error: failed to route message", "err", err)
		}
	}

	return nil
}

// buildQuery constructs a query for the bridgeContract by hashing sig to get the event topic
func buildQuery(contract ethcommon.Address, sig utils.EventSig, startBlock *big.Int, endBlock *big.Int) eth.FilterQuery {
	query := eth.FilterQuery{
		FromBlock: startBlock,
		ToBlock:   endBlock,
		Addresses: []ethcommon.Address{contract},
		Topics: [][]ethcommon.Hash{
			{sig.GetTopic()},
		},
	}
	return query
}

// Stop cancels all subscriptions. Must be called before Connection.Stop().
func (l *Listener) Stop() error {
	for sig := range l.subscriptions {
		delete(l.subscriptions, sig)
	}
	return nil
}
