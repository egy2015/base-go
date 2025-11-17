package messaging

import (
	"fmt"
	// "log"

	amqp "github.com/rabbitmq/amqp091-go"
)

type RabbitMQ struct {
	Connection *amqp.Connection
	Channel    *amqp.Channel
}

func NewRabbitMQ(url string) (*RabbitMQ, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to open channel: %w", err)
	}

	return &RabbitMQ{
		Connection: conn,
		Channel:    ch,
	}, nil
}

func (rmq *RabbitMQ) DeclareExchange(name, kind string) error {
	return rmq.Channel.ExchangeDeclare(
		name,  // name
		kind,  // type
		true,  // durable
		false, // autoDelete
		false, // internal
		false, // nowait
		nil,   // arguments
	)
}

func (rmq *RabbitMQ) DeclareQueue(name string) (amqp.Queue, error) {
	return rmq.Channel.QueueDeclare(
		name,  // name
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
}

func (rmq *RabbitMQ) BindQueue(queueName, exchangeName, routingKey string) error {
	return rmq.Channel.QueueBind(
		queueName,    // queue name
		routingKey,   // routing key
		exchangeName, // exchange name
		false,        // no-wait
		nil,          // arguments
	)
}

func (rmq *RabbitMQ) PublishMessage(exchangeName, routingKey string, message []byte) error {
	return rmq.Channel.Publish(
		exchangeName, // exchange
		routingKey,   // routing key
		false,        // mandatory
		false,        // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        message,
		},
	)
}

func (rmq *RabbitMQ) Close() error {
	if rmq.Channel != nil {
		rmq.Channel.Close()
	}
	if rmq.Connection != nil {
		rmq.Connection.Close()
	}
	return nil
}

func (rmq *RabbitMQ) ConsumeMessages(queueName string) (<-chan amqp.Delivery, error) {
	return rmq.Channel.Consume(
		queueName, // queue
		"",        // consumer
		true,      // auto-ack
		false,     // exclusive
		false,     // no-local
		false,     // no-wait
		nil,       // args
	)
}
