#!/bin/bash
ps aux | grep -E 'bin\/geth|_\/beacon-chain|_\/validator' | awk '{print $2}'  | xargs kill -9 $1
cd prysm
bazel build //cmd/prysmctl
bazel build //cmd/beacon-chain
bazel build //cmd/validator
cd ../
CHAINID=1331
PATH_TO_CONFIG=$PWD
PATH_TO_DATADIR=$PATH_TO_CONFIG/prysm-data
rm -rf $PATH_TO_DATADIR $PATH_TO_GETH
mkdir $PATH_TO_DATADIR

cd $PATH_TO_CONFIG/prysm
bazel run //cmd/beacon-chain -- \
    --datadir=$PATH_TO_DATADIR \
    --execution-endpoint="http://localhost:8552" \
	--min-sync-peers=0 \
	--force-clear-db \
	--interop-genesis-state=$PATH_TO_CONFIG/genesis.ssz \
	--interop-eth1data-votes \
	--bootstrap-node= \
	--chain-config-file=$PATH_TO_CONFIG/config.yml \
	--chain-id=$CHAINID \
	--accept-terms-of-use \
    --bootstrap-node="$PEER" \
	# --jwt-secret=$PATH_TO_CONFIG/jwtsecret.txt \
	# --suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
	--verbosity debug > $PATH_TO_CONFIG/beacon.log 2>&1 & 
