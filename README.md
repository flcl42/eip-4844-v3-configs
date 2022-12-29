# Configs to run prysm + nethermind on EIP-4844 Devnets 

The configs are located in v3, v3-zulu, etc. directories, should work OK locally and as part of a docker compoose setup

## How to run

The script resets on restart and kills prysm and nethermind
To run or restart from scratch:
```
./run.sh <network name>
# examples:
./run.sh v3
./run.sh v3-zulu
```

To shutdown:
```
./run.sh stop
```
