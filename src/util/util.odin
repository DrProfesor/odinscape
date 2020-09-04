package util

import "core:fmt"

tprint :: proc(_args: ..any) -> string {
	return fmt.tprint(args=_args, sep="");
}