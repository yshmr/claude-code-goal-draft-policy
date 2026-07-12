package parser

import "strings"

// Parse splits a comma-separated key=value list into a map.
func Parse(s string) map[string]string {
	out := map[string]string{}
	for _, pair := range strings.Split(s, ",") {
		if k, v, ok := strings.Cut(strings.TrimSpace(pair), "="); ok {
			out[k] = v
		}
	}
	return out
}
