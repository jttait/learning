CERTS=generated_certs
CONFIGS=openssl_configs

mkdir -p generated_certs

# Private key for Certificate Authority (CA)
openssl genrsa -out $CERTS/ca.key 4096

# Certificate Authority (CA)
openssl req -new -x509 \
   -days 365 \
   -key $CERTS/ca.key \
   -out $CERTS/ca.crt \
   -config $CONFIGS/ca_config \
   -extensions v3_ca

# Private key for server
openssl genrsa -out $CERTS/server.key 4096

# Certificate Signing Request (CSR) for server
openssl req -new \
   -key $CERTS/server.key \
   -out $CERTS/server.csr \
   -config $CONFIGS/server_config \
   -extensions v3_req

# Sign server CSR using CA
openssl x509 -req \
   -in $CERTS/server.csr \
   -CA $CERTS/ca.crt \
   -CAkey $CERTS/ca.key \
   -out $CERTS/server.crt \
   -days 365 \
   -CAcreateserial \
   -extfile $CONFIGS/server_config \
   -extensions v3_req

# Server certificate bundle
cp $CERTS/server.crt $CERTS/certbundle.pem
cat $CERTS/ca.crt >> $CERTS/certbundle.pem

# Private key for self-signed client
openssl genrsa -out $CERTS/badclient.key 4096

# Certificate for self-signed client
openssl req -new -x509 \
   -days 365 \
   -key $CERTS/badclient.key \
   -out $CERTS/badclient.crt \
   -config $CONFIGS/badclient_config \
   -extensions v3_req

# Private key for client
openssl genrsa -out $CERTS/goodclient.key 4096

# CSR for client
openssl req -new \
   -key $CERTS/goodclient.key \
   -out $CERTS/goodclient.csr \
   -config $CONFIGS/goodclient_config \
   -extensions v3_req

# Sign client CSR using CA
openssl x509 -req \
   -in $CERTS/goodclient.csr \
   -CA $CERTS/ca.crt \
   -CAkey $CERTS/ca.key \
   -out $CERTS/goodclient.crt \
   -CAcreateserial \
   -days 365 \
   -extfile $CONFIGS/goodclient_config \
   -extensions v3_req

# Go test
cd test
go test
