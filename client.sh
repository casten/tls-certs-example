#!/bin/bash

if ! [[ $_ != $0 ]]; then
	echo "This script must be sourced."
	exit -1
fi 


#send a message verifying server idenity via intermediate.ca file, send up client cert
echo "Looking good Billy Ray!" | openssl s_client  --connect localhost:8443 --CAfile ./intermediate/intermediate.ca --cert ./client_chained/client_chained.crt --key ./client_chained/client_chained.key


#look to see if the srver go the message
if cat server_out | grep -q "Looking good Billy Ray!"; then
	#yay!
    echo -e "\nFeeling good Lewis! (Success)\n"
else
	#so sad
	echo -e "\nYOU'RE A DEAD MAN, VALENTINE! (Fail)\n"
fi
