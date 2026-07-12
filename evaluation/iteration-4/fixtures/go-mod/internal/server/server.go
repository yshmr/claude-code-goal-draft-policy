package server

import "fmt"

// Greeting returns the banner shown on connect.
func Greeting(name string) string {
	return fmt.Sprintf("hello %s", name)
}
