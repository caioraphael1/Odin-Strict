package log

import "base:runtime"
import "core:fmt"


Logger :: struct {
	procedure:    Logger_Proc,
	data:         rawptr,
	lowest_level: Level,
	options:      Options,
}

Logger_Proc :: #type proc(data: rawptr, level: Level, text: string, options: Options, location := #caller_location)

Level :: enum uint {
	Debug   = 0,
	Info    = 10,
	Warning = 20,
	Error   = 30,
	Fatal   = 40,
}

Option :: enum {
	Level,
	Date,
	Time,
	Short_File_Path,
	Long_File_Path,
	Line,
	Procedure,
	Terminal_Color,
	Thread_Id,
}

Options :: bit_set[Option]

Full_Timestamp_Opts :: Options{
	.Date,
	.Time,
}

Location_Header_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
	.Line,
	.Procedure,
}

Location_File_Opts :: Options{
	.Short_File_Path,
	.Long_File_Path,
}


log :: proc(logger: Logger, level: Level, args: ..any, sep := " ", location := #caller_location) {
	if logger.procedure == nil {
		return
	}
	if level < logger.lowest_level {
		return
	}
	runtime.TEMP_ALLOCATOR_TEMP_GUARD()
	str := fmt.tprint(..args, sep=sep)
	logger.procedure(logger.data, level, str, logger.options, location)
}

logf :: proc(logger: Logger, level: Level, fmt_str: string, args: ..any, location := #caller_location) {
	if logger.procedure == nil {
		return
	}
	if level < logger.lowest_level {
		return
	}
	runtime.TEMP_ALLOCATOR_TEMP_GUARD()
	str := fmt.tprintf(fmt_str, ..args)
	logger.procedure(logger.data, level, str, logger.options, location)
}
