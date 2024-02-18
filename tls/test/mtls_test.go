package main

import (
	"testing"
)

func TestShouldAuthenticateClientSignedBySameCA(t *testing.T) {
	go startServer()
	client := createClient("goodclient")
	result, _ := makeCall(client)
	want := "hello, world"
	if result != want {
		t.Fatalf("Got: %v. Want: %v.\n", result, want)
	}
}

func TestShouldNotAuthenticateSelfSignedClient(t *testing.T) {
	go startServer()
	client := createClient("badclient")
	_, err := makeCall(client)
	if err == nil {
		t.Fatal("Got: nil. Want: error.\n")
	}
}
