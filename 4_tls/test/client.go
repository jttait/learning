package main

import (
	"crypto/tls"
	"crypto/x509"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

func createClient(filename string) *http.Client {
	cert, err := tls.LoadX509KeyPair("../generated_certs/"+filename+".crt", "../generated_certs/"+filename+".key")
	if err != nil {
		panic(err)
	}
	caCert, err := ioutil.ReadFile("../generated_certs/ca.crt")
	if err != nil {
		panic(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		RootCAs:      caCertPool,
	}
	transport := &http.Transport{
		TLSClientConfig: tlsConfig,
		MaxIdleConns:    10,
		IdleConnTimeout: 30 * time.Second,
	}
	return &http.Client{Transport: transport}
}

func makeCall(client *http.Client) (string, error) {
	payload := strings.NewReader("test payload")

	req, err := http.NewRequest("GET", "https://localhost:8443/", payload)
	if err != nil {
		return "", err
	}

	req.Header.Add("Content-Type", "text/plain")

	res, err := client.Do(req)
	if err != nil {
		return "", err
	}

	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}
