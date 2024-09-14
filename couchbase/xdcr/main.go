package main

import (
	"flag"
	"log"
	"time"

	"github.com/couchbase/gocb/v2"
)

func main() {
	clusterNumberFlag := flag.Int("cluster", 1, "Cluster - 1 or 2")
	operationFlag := flag.String("operation", "check", "Operation - upsert or check or remove")
	idFlag := flag.String("id", "", "Document ID")
	contentFlag := flag.String("value", "", "Document content")
	flag.Parse()
	if *operationFlag == "upsert" {
		upsert(*clusterNumberFlag, *idFlag, *contentFlag)
	} else if *operationFlag == "check" {
		check(*clusterNumberFlag, *idFlag, *contentFlag)
	} else if *operationFlag == "remove" {
		remove(*clusterNumberFlag, *idFlag)
	}
}

type Document struct {
	Content string
}

func remove(clusterNumber int, id string) {
	collection := connectToClusterAndReturnCollection(clusterNumber)
	_, err := collection.Remove(id, &gocb.RemoveOptions{
		Timeout: 100 * time.Millisecond,
	})
	if err != nil {
		log.Fatal(err)
	}
	time.Sleep(5 * time.Second)
}

func check(clusterNumber int, id string, content string) {
	collection := connectToClusterAndReturnCollection(clusterNumber)
	getResult, err := collection.Get(id, nil)
	if err != nil {
		log.Fatal(err)
	}
	var inDocument Document
	err = getResult.Content(&inDocument)
	if err != nil {
		log.Fatal(err)
	}
	if content != inDocument.Content {
		log.Fatal("Document check failed!")
	}
}

func upsert(clusterNumber int, id string, content string) {
	collection := connectToClusterAndReturnCollection(clusterNumber)
	_, err := collection.Upsert(id, Document{Content: content}, nil)
	if err != nil {
		log.Fatal(err)
	}
	time.Sleep(5 * time.Second)
}

func connectToClusterAndReturnCollection(clusterNumber int) *gocb.Collection {
	connectionString := "localhost"
	if clusterNumber == 2 {
		connectionString = "localhost:11211"
	}
	cluster, err := gocb.Connect("couchbase://"+connectionString, gocb.ClusterOptions{
		Authenticator: gocb.PasswordAuthenticator{
			Username: "Administrator",
			Password: "password",
		},
	})
	if err != nil {
		log.Fatal(err)
	}
	bucket := cluster.Bucket("test")
	err = bucket.WaitUntilReady(5*time.Second, nil)
	if err != nil {
		log.Fatal(err)
	}
	return bucket.Scope("_default").Collection("_default")
}
