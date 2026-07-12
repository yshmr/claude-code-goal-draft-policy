package server

import "testing"

func TestGreeting(t *testing.T) {
	if Greeting("x") != "hello x" {
		t.Fatalf("unexpected greeting")
	}
}
