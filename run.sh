#!/bin/bash
ps aux | grep -E 'bin\/geth|_\/beacon-chain|_\/validator' | awk '{print $2}'  | xargs kill -9
cd prysm
bazel build //cmd/prysmctl
bazel build //cmd/beacon-chain
bazel build //cmd/validator
cd ../
CHAINID=1333

if [ -n "$1" ]; then 
	SUBDIR=/$1 
else
	SUBDIR=/v3 
fi

ROOT=$PWD
PATH_TO_CONFIG=$ROOT$SUBDIR
PATH_TO_DATADIR=$ROOT/prysm-data
rm -rf $PATH_TO_DATADIR
mkdir $PATH_TO_DATADIR
PEER=$(cat $PATH_TO_CONFIG/bootnode.txt)
cd $ROOT/prysm
bazel run //cmd/beacon-chain -- \
    --datadir=$PATH_TO_DATADIR \
	--interop-genesis-state=$PATH_TO_CONFIG/genesis.ssz \
	--chain-config-file=$PATH_TO_CONFIG/config.yml \
    --execution-endpoint="http://localhost:8552" \
	--min-sync-peers=0 \
	--force-clear-db \
	--bootstrap-node= \
	--interop-eth1data-votes \
	--accept-terms-of-use \
    --bootstrap-node "$PEER" \
	--jwt-secret=$ROOT/jwtsecret.txt \
	--verbosity debug
