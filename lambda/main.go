package main

import (
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(event events.ConfigEvent) {

	msg := fmt.Sprintf("AWS Config rule name: %s", event.ConfigRuleName)
	log.Println(msg)
}

func main() {
	lambda.Start(handler)
}
