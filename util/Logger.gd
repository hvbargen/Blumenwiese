extends Reference

# Declare member variables here. Examples:
enum Level { DEBUG, INFO, WARN, ERROR, OFF }

export var level = Level.WARN
export var name: String

func _init(logger_name: String, log_level=null):
	self.name = logger_name
	if log_level != null:
		level = log_level
	

func debug(fmt: String, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	print(_format(Level.DEBUG, fmt, arg1, arg2, arg3, arg4, arg5))

func info(fmt: String, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	print(_format(Level.INFO, fmt, arg1, arg2, arg3, arg4, arg5))

func warn(fmt: String, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	push_warning(_format(Level.WARN, fmt, arg1, arg2, arg3, arg4, arg5))

func error(fmt: String, arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	push_error(_format(Level.ERROR, fmt, arg1, arg2, arg3, arg4, arg5))

func _format(lvl, fmt: String, arg1, arg2=null, arg3=null, arg4=null, arg5=null):
	if level <= lvl:
		var argv = PoolStringArray()
		if arg1 != null:
			argv.push_back(arg1 as String)
		if arg2 != null:
			argv.push_back(arg2 as String)
		if arg3 != null:
			argv.push_back(arg3 as String)
		if arg4 != null:
			argv.push_back(arg4 as String)
		if arg5 != null:
			argv.push_back(arg5 as String)
		var msg: String
		if len(argv) > 0:
			# prints(fmt, len(argv), argv)
			# FIXME: Does not work with Color: msg = fmt % argv
			msg = fmt + " " + argv.join(", ")
		else:
			msg = fmt
		return Level.keys()[level] + " (" + self.name + "): " + msg
	
