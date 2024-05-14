/// 2>/dev/null ; /usr/bin/env go run "$0" "$@" ; exit $?

package main

import (
	"fmt"
	"net/smtp"
	"os"
	"strings"
)

type Smtp struct {
	Username string
	Password string
	Host     string
	Port     int
}

func send() {
	// Sender data.
	sender := Smtp{
		Username: os.Getenv("MAIL_QQ_USERNAME"),
		Password: os.Getenv("MAIL_QQ_PASSWORD"),
		Host:     "smtp.qq.com",
		Port:     587,
	}

	// Receiver email address.
	to := os.Getenv("MAIL_163_USERNAME")

	// Message.
	contents := os.Args[1:]
	contents = append(contents, "\n\nhttps://src.fedoraproject.org/rpms/kernel-headers")
	body := strings.Join(contents, "\n")

	msg := fmt.Sprintf(`From: %s <%s>
To: %s <%s>
Subject: %s

%s`, "Hello Notification", sender.Username, "ueaner", to, "Fedora kernel-headers updates available", body)

	// Authentication.
	auth := smtp.PlainAuth("", sender.Username, sender.Password, sender.Host)

	// Sending email.
	addr := fmt.Sprintf("%s:%d", sender.Host, sender.Port)
	err := smtp.SendMail(addr, auth, sender.Username, []string{to}, []byte(msg))
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("Email Sent Successfully!")
}

func main() {
	send()
}
