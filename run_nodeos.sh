#!/bin/sh

function get_priv_key {
   cat $1 | sed -n -e 's/Private key: //p'
}

function get_pub_key {
   cat $1 | sed -n -e 's/Public key: //p'
}

function activate_feature {
   curl --request POST \
      --url http://127.0.0.1:$1/v1/producer/schedule_protocol_feature_activations \
      -d "{\"protocol_features_to_activate\": [\"$2\"]}"
}

./run_postgre.sh

pkill nodeos
rm -rf ./data* ./protocol_features* ./eosio-wallet ./*.keys

pkill keosd
rm -rf ~/eosio-wallet/df*

keosd > keosd.log 2>&1 &

cleos wallet create -n df -f ./wallet.keys
WALLET_PASSWORD=$(cat ./wallet.keys)

#eosio private key
cleos wallet import -n df --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

cleos create key -f ./eosio.prods.keys
PRODS_KEY=$(get_priv_key ./eosio.prods.keys)
PRODS_PUB_KEY=$(get_pub_key ./eosio.prods.keys)
cleos wallet import -n df --private-key $PRODS_KEY

cleos create key -f ./eosio.prods2.keys
PRODS2_KEY=$(get_priv_key ./eosio.prods2.keys)
PRODS2_PUB_KEY=$(get_pub_key ./eosio.prods2.keys)
cleos wallet import -n df --private-key $PRODS2_KEY


cleos create key -f ./eosio.bpay.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.bpay.keys)
cleos create key -f ./eosio.msig.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.msig.keys)
cleos create key -f ./eosio.names.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.names.keys)
cleos create key -f ./eosio.ram.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.ram.keys)
cleos create key -f ./eosio.ramfee.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.ramfee.keys)
cleos create key -f ./eosio.saving.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.saving.keys)
cleos create key -f ./eosio.stake.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.stake.keys)
cleos create key -f ./eosio.token.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.token.keys)
cleos create key -f ./eosio.vpay.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.vpay.keys)
cleos create key -f ./eosio.rex.keys
cleos wallet import -n df --private-key $(get_priv_key ./eosio.rex.keys)

cleos wallet open -n df
cleos wallet unlock -n df --password $WALLET_PASSWORD

#generate genesis:
echo "generating genesis..."
cat ./genesis_template.json | sed -e "s/REPLACE_WITH_PRIVATE_KEY/$PRODS_PUB_KEY/g" > ./genesis.json

echo "generating config..."
cat ./gen_conf/config_template.ini | sed -e "s/PUB_KEY/$PRODS_PUB_KEY/g" | sed -e "s/PRIV_KEY/$PRODS_KEY/g" > ./gen_conf/config.ini
cat ./gen_conf/config_template.ini | sed -e "s/PUB_KEY/$PRODS2_PUB_KEY/g" | sed -e "s/PRIV_KEY/$PRODS2_KEY/g" > ./gen_conf2/config.ini

cat ./config_template.ini | sed -e "s/PUB_KEY/$PRODS_PUB_KEY/g" | sed -e "s/PRIV_KEY/$PRODS_KEY/g" > ./config.ini
cat ./config_template.ini | sed -e "s/PUB_KEY/$PRODS2_PUB_KEY/g" | sed -e "s/PRIV_KEY/$PRODS2_KEY/g" > ./conf2/config.ini

echo "creating new blockchain from genesis..."
nodeos --genesis-json ./genesis.json \
  --data-dir ./data1     \
  --protocol-features-dir ./protocol_features1 \
  --config-dir ./gen_conf \
  > nodeos_1.log 2>&1 &
nodeos --genesis-json ./genesis.json \
  --data-dir ./data2     \
  --protocol-features-dir ./protocol_features2 \
  --config-dir ./gen_conf \
  > nodeos_2.log 2>&1 &
nodeos --genesis-json ./genesis.json \
  --data-dir ./data3     \
  --protocol-features-dir ./protocol_features3 \
  --config-dir ./gen_conf \
  > nodeos_3.log 2>&1 &
nodeos --genesis-json ./genesis.json \
  --data-dir ./data4     \
  --protocol-features-dir ./protocol_features4 \
  --config-dir ./gen_conf2 \
  > nodeos_4.log 2>&1 &
sleep 3
pkill nodeos


echo "starting eosio"
nodeos -e -p eosio \
  --data-dir ./data1     \
  --protocol-features-dir ./protocol_features1 \
  --config-dir . \
  --contracts-console   \
  --disable-replay-opts \
  --http-server-address 0.0.0.0:8888 \
  --p2p-listen-endpoint 0.0.0.0:9876 \
  --p2p-peer-address localhost:9879 \
  -l ./logging.json \
  >> nodeos_1.log 2>&1 &
sleep 3


cleos create account eosio eosio.bpay $(get_pub_key eosio.bpay.keys) #-p eosio@active
cleos create account eosio eosio.msig $(get_pub_key eosio.msig.keys) #-p eosio@active
cleos create account eosio eosio.names $(get_pub_key eosio.names.keys) #-p eosio@active
cleos create account eosio eosio.ram $(get_pub_key eosio.ram.keys) #-p eosio@active
cleos create account eosio eosio.ramfee $(get_pub_key eosio.ramfee.keys) #-p eosio@active
cleos create account eosio eosio.saving $(get_pub_key eosio.saving.keys) #-p eosio@active
cleos create account eosio eosio.stake $(get_pub_key eosio.stake.keys) #-p eosio@active
cleos create account eosio eosio.token $(get_pub_key eosio.token.keys) #-p eosio@active
cleos create account eosio eosio.vpay $(get_pub_key eosio.vpay.keys) #-p eosio@active
cleos create account eosio eosio.rex $(get_pub_key eosio.rex.keys) #-p eosio@active

#PREACTIVATE_FEATURE
activate_feature 8888 "0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"

sleep 3

EOSIO_CONTRACTS_DIRECTORY="$HOME/Work/eosio.contracts/build/contracts"

cleos set contract eosio $EOSIO_CONTRACTS_DIRECTORY/eosio.boot/

sleep 5

#KV_DATABASE
cleos push action eosio activate '["825ee6288fb1373eab1b5187ec2f04f6eacb39cb3a97f356a07c91622dd61d16"]' -p eosio
#WTMSIG_BLOCK_SIGNATURES
cleos push action eosio activate '["299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707"]' -p eosio
sleep 5

cleos set contract eosio $EOSIO_CONTRACTS_DIRECTORY/eosio.system/
sleep 3
cleos set contract eosio.msig $EOSIO_CONTRACTS_DIRECTORY/eosio.msig/
sleep 3
cleos set contract eosio.token $EOSIO_CONTRACTS_DIRECTORY/eosio.token/
sleep 3

#10bln
cleos push action eosio.token create '[ "eosio", "10000000000.0000 SYS" ]' -p eosio.token
#1bln
cleos push action eosio.token issue '[ "eosio", "1000000000.0000 SYS", "memo" ]' -p eosio
cleos push action eosio init '["0", "4,SYS"]' -p eosio@active

cleos push action eosio setpriv '["eosio.msig", 1]' -p eosio
sleep 3

#100mm
cleos system newaccount eosio --transfer producer1 $PRODS_PUB_KEY --stake-net "100000000.0000 SYS" --stake-cpu "100000000.0000 SYS" --buy-ram-kbytes 8192
#100mm
cleos system newaccount eosio --transfer producer2 $PRODS2_PUB_KEY --stake-net "100000000.0000 SYS" --stake-cpu "100000000.0000 SYS" --buy-ram-kbytes 8192

sleep 3
cleos system regproducer producer1 $PRODS_PUB_KEY https://dimon1.io 840 -p producer1
cleos system regproducer producer2 $PRODS2_PUB_KEY https://dimon2.io 840 -p producer2

sleep 3

cleos system listproducers

cleos system voteproducer prods producer1 producer1 producer2
cleos system voteproducer prods producer2 producer1 producer2

cleos system listproducers

sleep 3

#resign eosio and other system accounts
cleos push action eosio updateauth '{"account": "eosio", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio.prods", "permission": "active"}}]}}' -p eosio@owner
cleos push action eosio updateauth '{"account": "eosio", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio.prods", "permission": "active"}}]}}' -p eosio@active

cleos push action eosio updateauth '{"account": "eosio.bpay", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.bpay@owner
cleos push action eosio updateauth '{"account": "eosio.bpay", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.bpay@active

cleos push action eosio updateauth '{"account": "eosio.msig", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.msig@owner
cleos push action eosio updateauth '{"account": "eosio.msig", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.msig@active

cleos push action eosio updateauth '{"account": "eosio.names", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.names@owner
cleos push action eosio updateauth '{"account": "eosio.names", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.names@active

cleos push action eosio updateauth '{"account": "eosio.ram", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.ram@owner
cleos push action eosio updateauth '{"account": "eosio.ram", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.ram@active

cleos push action eosio updateauth '{"account": "eosio.ramfee", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.ramfee@owner
cleos push action eosio updateauth '{"account": "eosio.ramfee", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.ramfee@active

cleos push action eosio updateauth '{"account": "eosio.saving", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.saving@owner
cleos push action eosio updateauth '{"account": "eosio.saving", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.saving@active

cleos push action eosio updateauth '{"account": "eosio.stake", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.stake@owner
cleos push action eosio updateauth '{"account": "eosio.stake", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.stake@active

cleos push action eosio updateauth '{"account": "eosio.token", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.token@owner
cleos push action eosio updateauth '{"account": "eosio.token", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.token@active

cleos push action eosio updateauth '{"account": "eosio.vpay", "permission": "owner", "parent": "", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.vpay@owner
cleos push action eosio updateauth '{"account": "eosio.vpay", "permission": "active", "parent": "owner", "auth": {"threshold": 1, "keys": [], "waits": [], "accounts": [{"weight": 1, "permission": {"actor": "eosio", "permission": "active"}}]}}' -p eosio.vpay@active

sleep 3

pkill nodeos

echo "starting producer1 instance 1"
nodeos -e -p producer1 \
  --data-dir ./data1     \
  --protocol-features-dir ./protocol_features1 \
  --config-dir . \
  --contracts-console   \
  --disable-replay-opts \
  --http-server-address 0.0.0.0:8888 \
  --p2p-listen-endpoint 0.0.0.0:9876 \
  --p2p-peer-address localhost:9879 \
  -l ./logging.json \
  >> nodeos_1.log 2>&1 &
sleep 3
echo "starting producer1 instance 2"
nodeos -e -p producer1 \
  --data-dir ./data2     \
  --protocol-features-dir ./protocol_features2 \
  --config-dir . \
  --contracts-console   \
  --disable-replay-opts \
  --http-server-address 0.0.0.0:8889 \
  --p2p-listen-endpoint 0.0.0.0:9877 \
  -l ./logging.json \
  >> nodeos_2.log 2>&1 &
sleep 3
echo "starting producer1 instance 3"
nodeos -e -p producer1 \
  --data-dir ./data3     \
  --protocol-features-dir ./protocol_features3 \
  --config-dir . \
  --contracts-console   \
  --disable-replay-opts \
  --http-server-address 0.0.0.0:8890 \
  --p2p-listen-endpoint 0.0.0.0:9878 \
  -l ./logging.json \
  >> nodeos_3.log 2>&1 &
sleep 3
echo "starting producer2"
nodeos -e -p producer2 \
  --data-dir ./data4     \
  --protocol-features-dir ./protocol_features4 \
  --config-dir ./conf2 \
  --contracts-console   \
  --disable-replay-opts \
  --http-server-address 0.0.0.0:8891 \
  --p2p-listen-endpoint 0.0.0.0:9879 \
  --p2p-peer-address localhost:9876 \
  --p2p-peer-address localhost:9877 \
  --p2p-peer-address localhost:9878 \
  > nodeos_4.log 2>&1 &