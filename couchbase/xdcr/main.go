package main

import (
	"log"
	"time"
	"flag"

	"github.com/couchbase/gocb/v2"
)

func main() {
	clusterNumberFlag := flag.Int("cluster", 1, "Cluster - 1 or 2")
	operationFlag := flag.Stirng("operation", "check", "Operation - upsert or check or remove")
	idFlag := flag.String("id", "", "Document ID")
	valueFlag := flag.String("value", "", "Document value")
	flag.Parse()
	if *operationFlag == "upsert" {
		upsert(*clusterNumberFlag, *idFlag, *valueFlag)
	} else if *operationFlag == "check" {
		check(*clusterNumberFlag, *idFlag, *valueFlag)
	} else if *operationFlag == "remove" {
		remove(*clusterNumberFlag, *idFlag)
	}
}

type User struct {
	Name string
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

func check(clusterNumber int, id string, name string) {
	collection := connectToClusterAndReturnCollection(clusterNumber)
	getResult, err := collection.Get(id, nil)
	if err != nil {
		log.Fatal(err)
	}
	var inUser User
	err = getResult.Content(&inUser)
	if err != nil {
		log.Fatal(err)
	}
	if name != inUser.Name {
		log.Fatal("Document check failed!")
	}
}

func upsert(clusterNumber int, id string, name string) {
	collection := connectToClusterAndReturnCollection(clusterNumber)
	_, err := collection.Upsert(id, User{Name: name}, nil)
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
	err = bucket.WaitUntilReady(5 * time.Second, nil)
	if err != nil {
		log.Fatal(err)
	}
	return bucket.Scope("_default").Collection("_default")
}
