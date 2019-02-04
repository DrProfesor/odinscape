package builder

import wb "shared:workbench"
using import "shared:workbench/logging"

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"

import    "shared:workbench/wbml"

ODINSCAPE_DIRECTORY :: "./src/";

components : [dynamic]string;

main :: proc() {
	run_preprocessor();
	run_code_generator();
}

}
