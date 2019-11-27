# TLS-Certs-Example

This is an example Bash script that shows the creation of a root cert (self-signed), intermediate certs, and chained certs for client and server.  
* These are used to configure a server and client with bidirectional authentication.
* The server is started, the client connects and sends some data which is subsequently verified as received by the server.

Cert generation and testing use OpenSSL.

## Usage
To use it, source example.sh.
# 

|Note|
|:---|
| The script *must* be sourced in order to run properly, e.g.: 
$ . example.sh
or
$ source example.sh
