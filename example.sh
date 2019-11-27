#!/bin/bash

if ! [[ $_ != $0 ]]; then
	echo "This script must be sourced."
	exit -1
fi 

#clean up any preexisting generated files
find . ! -name '*.sh' ! -name '.git' ! -name '.' ! -name '..' ! -name '*.cnf' -type f,d -exec rm -rf {} +
#and servers
killall openssl -q

#create self signed key for root
mkdir root
cd root
openssl req -newkey rsa:2048 -nodes -keyout root.key -x509 -days 3650 -out root.crt -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=root.soquelsoft.com" \
            -config ../ca.cnf

cd ..

#create intermediate csr
mkdir intermediate
cd intermediate
openssl req -new -newkey rsa:2048 -nodes -keyout intermediate.key -out intermediate.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=intermediate.soquelsoft.com" \
            -config ../ca.cnf 

openssl x509 -req -days 3600 -in intermediate.csr -CA ../root/root.crt -CAkey ../root/root.key -CAcreateserial -out ./intermediate.crt -sha256 \
			 -extfile ../ca_ext.cnf -extensions v3_ca

cat ../root/root.crt intermediate.crt  > intermediate.ca
cd ..


#create chained cert
mkdir chained
cd chained
openssl req -new -newkey rsa:2048 -nodes -keyout chained.key -out chained.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=chained.soquelsoft.com"
openssl x509 -req -days 3600 -in chained.csr -CA ../intermediate/intermediate.crt -CAkey ../intermediate/intermediate.key -CAcreateserial -out chained.crt -sha256 \
			 -extfile ../server_ext.cnf -extensions v3_req

cd ..


#create client_intermediate csr
mkdir client_intermediate
cd client_intermediate
openssl req -new -newkey rsa:2048 -nodes -keyout client_intermediate.key -out client_intermediate.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=client_intermediate.soquelsoft.com" \
            -config ../ca.cnf

openssl x509 -req -days 3600 -in client_intermediate.csr -CA ../root/root.crt -CAkey ../root/root.key -CAcreateserial -out ./client_intermediate.crt -sha256 \
			 -extfile ../ca_ext.cnf -extensions v3_ca

cat client_intermediate.crt ../root/root.crt > client_intermediate.ca
cd ..


#create chained cert
mkdir client_chained
cd client_chained
openssl req -new -newkey rsa:2048 -nodes -keyout client_chained.key -out client_chained.csr -subj "/C=US/ST=California/L=Soquel/O=SoquelSoft/OU=dev/CN=client_chained.soquelsoft.com" 
openssl x509 -req -days 3600 -in client_chained.csr -CA ../client_intermediate/client_intermediate.crt -CAkey ../client_intermediate/client_intermediate.key -CAcreateserial -out client_chained.crt -sha256 \
		-extfile ../client_ext.cnf -extensions v3_req

cd ..


#start server in bg, use chained cert, point to client_ca for client auth and require client auth up to 2 level deep
openssl s_server --accept 8443 --cert ./chained/chained.crt --key ./chained/chained.key -debug -CAfile ./client_intermediate/client_intermediate.ca -Verify 5 > server_out &

#You may comment this out and run in a separate terminal in order to debug output from each side more easily
bash client.sh
