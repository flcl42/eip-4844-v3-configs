#!/bin/bash
ps aux | grep -E 'Ru[n]ner|n[o]de' | awk '{print $2}'  | xargs kill -9
if [[ "$1" == "stop" ]]; then exit; fi

if [ -n "$1" ]; then
	SUBDIR=/$1
else
	SUBDIR=/v3
fi

ROOT=$PWD
PATH_TO_CONFIG=$ROOT$SUBDIR
NETHERMIND_PATH?=$ROOT/nethermind

# Build
cd lodestar
yarn lerna bootstrap
yarn install
yarn build
cd ../
dotnet build $NETHERMIND_PATH/src/Nethermind/Nethermind.Runner/Nethermind.Runner.csproj

# Vars
LODESTAR_DATA_DIR=$ROOT/lodestar-data
rm -rf $LODESTAR_DATA_DIR
mkdir -p $LODESTAR_DATA_DIR

NETHERMIND_DATA_DIR=$ROOT/nethermind-data
rm -rf $NETHERMIND_DATA_DIR
mkdir -p $NETHERMIND_DATA_DIR

mkdir -p $PATH_TO_CONFIG/logs

CHAINID=$(cat $PATH_TO_CONFIG/lodestar/config.yml | grep DEPOSIT_CHAIN_ID | sed 's/DEPOSIT_CHAIN_ID: //')
PEER=$(cat $PATH_TO_CONFIG/lodestar/bootnode.txt)
EXECUTION_NODE_URL=http://localhost:8552
INTEROP_GENESIS_TIME=
# Run 


$NETHERMIND_PATH/src/Nethermind/Nethermind.Runner/bin/Debug/net6.0/Nethermind.Runner \
	-c $PATH_TO_CONFIG/nethermind/config.json \
	--Init.ChainSpecPath $PATH_TO_CONFIG/nethermind/genesis.json \
	-dd $NETHERMIND_DATA_DIR \
    --Init.LogDirectory $PATH_TO_CONFIG/logs \
	--log TRACE > /dev/null 2>&1 &

# https://chainsafe.notion.site/chainsafe/Lodestar-flags-02406e481f664d84adb56c2c348e49aa
# --genesisTime "$INTEROP_GENESIS_TIME" \
cd $ROOT/lodestar
./lodestar minimal \
    --dataDir $LODESTAR_DATA_DIR \
	--paramsFile $PATH_TO_CONFIG/prysm/config.yml \
    --eth1 \
    --eth1.providerUrls "$EXECUTION_NODE_URL" \
    --execution.urls "$EXECUTION_NODE_URL" \
    --network.connectToDiscv5Bootnodes true \
    --bootnodes $PEER \
    --reset \
    --server http://localhost:3500 \
    --rest \
    --rest.address 0.0.0.0 \
    --rest.port 3500 \
    --rest.namespace "*" \
	--jwt-secret $ROOT/jwtsecret.txt \
	--logFileLevel debug \
	--logFile $PATH_TO_CONFIG/logs/lodestar.log &

echo "Running now"