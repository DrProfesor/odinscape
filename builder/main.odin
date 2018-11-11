package builder

import wb "shared:workbench"
logln :: wb.logln;

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"

import    "shared:workbench/wbml"

ODINSCAPE_DIRECTORY :: "./src/";

main :: proc() {
	run_code_generator();
}

}
