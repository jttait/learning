package main

import (
	"os"
	"io"
	"net/http"
	"log/slog"
	"log"
)

func main() {
	file, err := os.OpenFile("server.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatal(err)
	}
	multiWriter := io.MultiWriter(os.Stdout, file)
	handlerOptions := slog.HandlerOptions{}
	logger := slog.New(slog.NewJSONHandler(multiWriter, &handlerOptions))
	slog.SetDefault(logger)
	http.HandleFunc("/", getRoot)
	err = http.ListenAndServe(":3333", nil)
	if err != nil {
		log.Fatal(err)
	}
}

func getRoot(w http.ResponseWriter, r *http.Request) {
	slog.Info("request received to root",
		slog.String("Method", r.Method),
		slog.String("URL", r.URL.String()),
	)
	io.WriteString(w, "hello, world\n")
}
