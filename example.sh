#!/bin/bash

if ! [[ $_ != $0 ]]; then
	echo "This script must be sourced."
	exit -1
fi 

#clean up any preexisting generated files
find . ! -name 'example.sh' -type f -exec rm -rf {} +
#and servers
killall openssl

#create self signed key for root
mkdir root
cd root
openssl req -newkey rsa:2048 -nodes -keyout root.key -x509 -days 3650 -out root.crt -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=root.soquelsoft.com"
cd ..

#create intermediate csr
mkdir intermediate
cd intermediate
openssl req -new -newkey rsa:2048 -nodes -keyout intermediate.key -out intermediate.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=intermediate.soquelsoft.com"
openssl x509 -req -days 3600 -in intermediate.csr -CA ../root/root.crt -CAkey ../root/root.key -CAcreateserial -out ./intermediate.crt -sha256
cat ../root/root.crt intermediate.crt > intermediate.ca
cd ..


#create chained cert
mkdir chained
cd chained
openssl req -new -newkey rsa:2048 -nodes -keyout chained.key -out chained.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=chained.soquelsoft.com"
openssl x509 -req -days 3600 -in chained.csr -CA ../intermediate/intermediate.crt -CAkey ../intermediate/intermediate.key -CAcreateserial -out chained.crt -sha256
cd ..


#create client_intermediate csr
mkdir client_intermediate
cd client_intermediate
openssl req -new -newkey rsa:2048 -nodes -keyout client_intermediate.key -out client_intermediate.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=client_intermediate.soquelsoft.com"
openssl x509 -req -days 3600 -in client_intermediate.csr -CA ../root/root.crt -CAkey ../root/root.key -CAcreateserial -out ./client_intermediate.crt -sha256
cat ../root/root.crt client_intermediate.crt > client_intermediate.ca
cd ..


#create chained cert
mkdir client_chained
cd client_chained
openssl req -new -newkey rsa:2048 -nodes -keyout client_chained.key -out client_chained.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=client_chained.soquelsoft.com"
openssl x509 -req -days 3600 -in client_chained.csr -CA ../client_intermediate/client_intermediate.crt -CAkey ../client_intermediate/client_intermediate.key -CAcreateserial -out client_chained.crt -sha256
cd ..


#start server in bg, use intermediate cert, point to client_ca for client auth and require client auth up to 1 level deep
openssl s_server --accept 8443 --cert ./intermediate/intermediate.crt --key ./intermediate/intermediate.key -CAfile ./client_intermediate/client_intermediate.ca -Verify 1 > server_out &

#send a message verifying server idenity via intermediate.ca file, send up client cert
echo "Looking good Billy Ray!" | openssl s_client --connect localhost:8443 --CAfile ./intermediate/intermediate.ca --cert ./client_chained/client_chained.crt --key ./client_chained/client_chained.key

#kill the server
killall openssl 

#look to see if the srver go the message
if cat server_out | grep -q "Looking good Billy Ray!"; then
	#yay!
    echo -e "\nFeeling good Lewis! (Success)\n"
else
	#so sad
	echo -e "\nYOU'RE A DEAD MAN, VALENTINE! (Fail)\n"
fi


