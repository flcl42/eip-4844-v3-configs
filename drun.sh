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
NETHERMIND_PATH=${NETHERMIND_PATH:=$ROOT/nethermind}

# Build
# cd lodestar
# yarn lerna bootstrap
# yarn install
# yarn build
# cd ../
dotnet build $NETHERMIND_PATH/src/Nethermind/Nethermind.Runner/Nethermind.Runner.csproj

# Vars
LODESTAR_DATA_DIR=$ROOT/lodestar-data
rm -rf $LODESTAR_DATA_DIR
mkdir -p $LODESTAR_DATA_DIR

NETHERMIND_DATA_DIR=$ROOT/nethermind-data
rm -rf $NETHERMIND_DATA_DIR
mkdir -p $NETHERMIND_DATA_DIR

mkdir -p $PATH_TO_CONFIG/logs

CHAINID=$(cat $PATH_TO_CONFIG/prysm/config.yml | grep DEPOSIT_CHAIN_ID | sed 's/DEPOSIT_CHAIN_ID: //')
PEER=$(cat $PATH_TO_CONFIG/prysm/bootnode.txt)
EXECUTION_NODE_URL=http://localhost:8552
# Run 


$NETHERMIND_PATH/src/Nethermind/Nethermind.Runner/bin/Debug/net6.0/Nethermind.Runner \
	-c $PATH_TO_CONFIG/nethermind/config.json \
	--Init.ChainSpecPath $PATH_TO_CONFIG/nethermind/genesis.json \
	-dd $NETHERMIND_DATA_DIR \
  --Init.LogDirectory $PATH_TO_CONFIG/logs \
	--log TRACE > /dev/null 2>&1 &

curl --retry 10 --retry-connrefused --retry-delay 0 $EXECUTION_NODE_URL

docker run --rm --network host \
  -v $PATH_TO_CONFIG/prysm:/config \
  -v $LODESTAR_DATA_DIR:/data \
  -v $ROOT/jwtsecret.txt:/data/jwtsecret \
  g11tech/lodestar:eip4844-devnet3 \
  beacon \
  --paramsFile /config/config.yml \
  --genesisStateFile /config/genesis.ssz \
  --dataDir /data/lodestar \
  --jwt-secret /data/jwtsecret \
  --execution.urls $EXECUTION_NODE_URL \
  --network.connectToDiscv5Bootnodes \
  --logLevel debug \
  --bootnodes $PEER > $PATH_TO_CONFIG/logs/lodestar.log 2>&1 &

#echo "Running now"