# Use: ./dcup.sh lodestar-nethermind v3 -d

if [ -n "$1" ]; then
	POSTFIX=$1
else
	POSTFIX=lodestar-nethermind
fi

if [ -n "$2" ]; then
	DEVNET=$2
else
	DEVNET=v3
fi

BOOTNODE=$(cat ./$DEVNET/prysm/bootnode.txt)
BOOTNODE=$BOOTNODE DEVNET=$DEVNET docker compose -f docker-compose-$POSTFIX.yml up $3