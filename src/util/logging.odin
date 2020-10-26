package util

import "core:log"
import "core:os"
import "core:strings"
import "core:time"
import "core:fmt"
import rt "core:runtime"

import "shared:wb/logging"

logs: [dynamic]Log_Entry;

logger: log.Logger;

Log_Entry :: struct {
	message: string,
	severity: log.Level,
	location: rt.Source_Code_Location,
}

init_logging :: proc() {
	data := new(log.File_Console_Logger_Data);
	data.file_handle = os.INVALID_HANDLE;
	data.ident = "";
	logger = log.Logger{cast(log.Logger_Proc) logger_proc, data, log.Level.Debug, log.Default_Console_Logger_Opts};
}

log_info :: proc(args: ..any, loc := #caller_location) {
	// context.logger = logger;
	// log.info(args);
	logging.logln(args=args, location=loc);
}

log_debug :: proc(args: ..any, loc := #caller_location) {
	// context.logger = logger;
	// log.debug(args);	
}

log_warn :: proc(args: ..any, loc := #caller_location) {
	// context.logger = logger;
	// log.warn(args);
}

log_error :: proc(args: ..any, loc := #caller_location) {
	// context.logger = logger;
	// log.error(args);
}


// function taken from core:file_console_logger
logger_proc :: proc(logger_data: rawptr, level: log.Level, text: string, options: log.Options, location := #caller_location) {
	log.file_console_logger_proc(logger_data, level, text, options, location);
	// TODO pass allocator to string clone
	append(&logs, Log_Entry{ strings.clone(text), level, location });
}