#!/bin/bash
ps aux | grep -E 'Ru[n]ner|_\/beacon-chain' | awk '{print $2}'  | xargs kill -9
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
dotnet build $ROOT/nethermind/src/Nethermind/Nethermind.Runner/Nethermind.Runner.csproj

# Vars
PRYSM_DATA_DIR=$ROOT/prysm-data
rm -rf $PRYSM_DATA_DIR
mkdir $PRYSM_DATA_DIR

NETHERMIND_DATA_DIR=$ROOT/nethermind-data
rm -rf $NETHERMIND_DATA_DIR
mkdir $NETHERMIND_DATA_DIR

mkdir -p $PATH_TO_CONFIG/logs

CHAINID=$(cat $PATH_TO_CONFIG/prysm/config.yml | grep DEPOSIT_CHAIN_ID | sed 's/DEPOSIT_CHAIN_ID: //')
PEER=$(cat $PATH_TO_CONFIG/prysm/bootnode.txt)

# Run 
cd $ROOT/prysm
bazel run //cmd/beacon-chain -- \
    --datadir=$PRYSM_DATA_DIR \
	--interop-genesis-state=$PATH_TO_CONFIG/prysm/genesis.ssz \
	--chain-config-file=$PATH_TO_CONFIG/prysm/config.yml \
    --execution-endpoint="http://localhost:8552" \
	--min-sync-peers=0 \
	--force-clear-db \
	--bootstrap-node= \
	--interop-eth1data-votes \
	--accept-terms-of-use \
    --bootstrap-node "$PEER" \
	--jwt-secret=$ROOT/jwtsecret.txt \
	--verbosity debug >> $PATH_TO_CONFIG/logs/prysm.log 2>&1 &


$ROOT/nethermind/src/Nethermind/Nethermind.Runner/bin/Debug/net6.0/Nethermind.Runner \
	-c $PATH_TO_CONFIG/nethermind/config.json \
	--Init.ChainSpecPath $PATH_TO_CONFIG/nethermind/genesis.json \
	-dd $NETHERMIND_DATA_DIR \
    --Init.LogDirectory $PATH_TO_CONFIG/logs \
	--log TRACE > /dev/null 2>&1 &

echo "Running now"