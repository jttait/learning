package main

import (
	"os"
	"io"
	"log"
	"net/http"
)

func getRoot(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "hello from " + os.Getenv("SERVER_NAME") + "\n")
}

func main() {
	http.HandleFunc("/", getRoot)
	err := http.ListenAndServe(":3333", nil)
	if err != nil {
		log.Fatal(err)
	}
}
