package parser

import "testing"

func TestParse(t *testing.T) {
	got := Parse("a=1, b=2")
	if got["a"] != "1" || got["b"] != "2" {
		t.Fatalf("unexpected result: %v", got)
	}
}
