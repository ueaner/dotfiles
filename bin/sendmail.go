/// 2>/dev/null ; /usr/bin/env go run "$0" "$@" ; exit $?

package main

import (
	"bufio"
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
	subject := ""
	body := ""

	switch args := len(os.Args); args {
	case 1:
		panic("No subject parameter.")
	case 2:
		subject = os.Args[1]
		var err error
		body, err = getMailBodyFromStdio()
		if err != nil {
			panic(err)
		}
	default:
		subject = os.Args[1]
		body = strings.Join(os.Args[2:], "\n")
	}

	msg := fmt.Sprintf(`From: %s <%s>
To: %s <%s>
Subject: %s

%s`, "Hello Notification", sender.Username, "ueaner", to, subject, body)

	// Authentication.
	auth := smtp.PlainAuth("", sender.Username, sender.Password, sender.Host)

	// Sending email.
	addr := fmt.Sprintf("%s:%d", sender.Host, sender.Port)
	err := smtp.SendMail(addr, auth, sender.Username, []string{to}, []byte(msg))
	if err != nil {
		panic(err)
	}
	fmt.Println("Email Sent Successfully!")
}

func getMailBodyFromStdio() (body string, err error) {
	contents := []string{}
	// 验证 stdio 的状态，确认是否有 heredoc 格式的 body 参数内容
	info, err := os.Stdin.Stat()
	if err != nil {
		return
	}

	// No input from stdin.
	if info.Mode()&os.ModeCharDevice != 0 {
		return
	}

	// 从标准输入读取内容
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		contents = append(contents, line)
		// fmt.Println("Received:", line)
	}
	if err = scanner.Err(); err != nil {
		// fmt.Fprintln(os.Stderr, "Error reading input:", err)
		return
	}

	body = strings.Join(contents, "\n")
	return
}

// sendmail.go <subject> <body>
func main() {
	send()
}
