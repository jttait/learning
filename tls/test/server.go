package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"net/http"
)

func welcomeHandler(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "hello, world")
}

func startServer() {
	TLS_CERT_FILE := "../generated_certs/certbundle.pem"
	TLS_KEY_FILE := "../generated_certs/server.key"
	CA_CERT_FILE := "../generated_certs/ca.crt"

	serverTLSCert, err := tls.LoadX509KeyPair(TLS_CERT_FILE, TLS_KEY_FILE)
	if err != nil {
		panic(err)
	}

	caCertPEM, err := ioutil.ReadFile(CA_CERT_FILE)
	if err != nil {
		panic(err)
	}

	certPool := x509.NewCertPool()

	ok := certPool.AppendCertsFromPEM(caCertPEM)
	if !ok {
		panic("Invalid cert in a CA PEM")
	}

	tlsConfig := &tls.Config{
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    certPool,
		Certificates: []tls.Certificate{serverTLSCert},
	}

	server := http.Server{
		Addr:      ":8443",
		Handler:   http.HandlerFunc(welcomeHandler),
		TLSConfig: tlsConfig,
	}

	defer server.Close()

	server.ListenAndServeTLS("", "")
}
