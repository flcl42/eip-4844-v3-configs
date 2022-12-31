#!/bin/bash
ps aux | grep -E 'g[e]th|_\/beacon-chain' | awk '{print $2}'  | xargs kill -9
if [[ "$1" == "stop" ]]; then exit; fi

if [ -n "$1" ]; then 
	SUBDIR=/$1 
else
	SUBDIR=/v3 
fi

ROOT=$PWD
PATH_TO_CONFIG=$ROOT$SUBDIR

# Build
cd prysm
bazel build //cmd/beacon-chain
cd ../
cd geth
make geth
cd ../


# Vars
PRYSM_DATA_DIR=$ROOT/prysm-data
rm -rf $PRYSM_DATA_DIR
mkdir -p $PRYSM_DATA_DIR

GETH_DATA_DIR=$ROOT/geth-data
# rm -rf $GETH_DATA_DIR
# mkdir -p $GETH_DATA_DIR

mkdir -p $PATH_TO_CONFIG/logs

CHAINID=$(cat $PATH_TO_CONFIG/prysm/config.yml | grep DEPOSIT_CHAIN_ID | sed 's/DEPOSIT_CHAIN_ID: //')
NETWORKID=$(cat $PATH_TO_CONFIG/prysm/config.yml | grep DEPOSIT_NETWORK_ID | sed 's/DEPOSIT_NETWORK_ID: //')
PEER=$(cat $PATH_TO_CONFIG/prysm/bootnode.txt)
GETH_PEER=$(cat $PATH_TO_CONFIG/geth/bootnode.txt)

# Run 

cd $ROOT/geth
./build/bin/geth --datadir $GETH_DATA_DIR init $PATH_TO_CONFIG/geth/genesis.json

./build/bin/geth --http \
	--datadir=$GETH_DATA_DIR \
	--bootnodes $GETH_PEER \
	--syncmode=full \
	--verbosity 5\
	--port 30305 \
	--networkid $NETWORKID \
    --authrpc.jwtsecret=$ROOT/jwtsecret.txt >> $PATH_TO_CONFIG/logs/geth.log 2>&1 &

cd ..
	
# cd $ROOT/prysm
# bazel run //cmd/beacon-chain -- \
#     --datadir=$PRYSM_DATA_DIR \
# 	--interop-genesis-state=$PATH_TO_CONFIG/prysm/genesis.ssz \
# 	--chain-config-file=$PATH_TO_CONFIG/prysm/config.yml \
#     --execution-endpoint="http://localhost:8551" \
# 	--min-sync-peers=0 \
# 	--force-clear-db \
# 	--bootstrap-node= \
# 	--interop-eth1data-votes \
# 	--accept-terms-of-use \
#     --bootstrap-node "$PEER" \
# 	--jwt-secret=$ROOT/jwtsecret.txt \
# 	--verbosity debug >> $PATH_TO_CONFIG/logs/prysm.log 2>&1 &

echo "Running now"