#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the qnbcli container as the
# first step of the EYFN tutorial.  It creates and submits a
# configuration transaction to add qnb to the network previously
# setup in the BYFN tutorial.
#

CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="tolbachannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

# import utils
. scripts/utils.sh

echo
echo "========= Creating config transaction to add qnb to network =========== "
echo

echo "Installing jq"
apt-get -y update && apt-get -y install jq

# Fetch the config for the channel, writing it to config.json
fetchChannelConfig ${CHANNEL_NAME} config.json

# Modify the configuration to append the new org
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"QNBMSP":.[1]}}}}}' config.json ./channel-artifacts/qnb.json > modified_config.json
set +x

# Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to qnb_update_in_envelope.pb
createConfigUpdate ${CHANNEL_NAME} config.json modified_config.json qnb_update_in_envelope.pb

echo
echo "========= Config transaction to add qnb to network created ===== "
echo

echo "Signing config transaction"
echo
signConfigtxAsPeerOrg 1 qnb_update_in_envelope.pb

echo
echo "========= Submitting transaction from a different peer (peer0.hsbc) which also signs it ========= "
echo
setGlobals 0 2
set -x
peer channel update -f qnb_update_in_envelope.pb -c ${CHANNEL_NAME} -o orderer.tolba.com:7050 --tls --cafile ${ORDERER_CA}
set +x

echo
echo "========= Config transaction to add qnb to network submitted! =========== "
echo

exit 0
