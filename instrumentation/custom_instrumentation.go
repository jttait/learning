package main

import (
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/metric"
)

var (
	tracer = otel.Tracer("rolldice")
	meter = otel.Meter("rolldice")
	rollCount metric.Int64Counter
)

func init() {
	var err error
	rollCount, err = meter.Int64Counter("dice.rolls",
		metric.WithDescription("The number of rolls by value"),
		metric.WithUnit("{roll}"),
	)
	if err != nil {
		panic(err)
	}
}

