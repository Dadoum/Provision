module provision.utils.loghelper;

import std.format;
import std.stdio;
import std.string;
import std.path;

bool lineStart = true;

string[] priority = [
    "", "DEFAUT", "VERBEUX", "DEBUG", "INFO", "AVERT", "ERR", "FATAL", "SILENCE"
];

void log(Args...)(string format, Args args, LogPriority prio = LogPriority.info,
        string file = __FILE__, string func = __FUNCTION__)
{
	debug { } else
	{
		if (prio == LogPriority.débug)
		{
			return;
		}
	}
	
    auto text = std.format.format(format, args);
    if (lineStart)
    {
        writef("[%s] [%s:%s] %s >> ", getHour(), baseName(file), resume(func),
                priority[cast(int) prio]);
    }
    write(text);
    
    lineStart = text[$ - 1] == '\n';
    stdout.flush();
}

void logln(Args...)(string format, Args args, LogPriority prio = LogPriority.info,
        string file = __FILE__, string func = __FUNCTION__)
{
    log!Args(format ~ "\n", args, prio = prio, file = file, func = func);
}

string resume(string str)
{
    if (str.length >= 20)
    {
        auto splits = str.split('.');
        if (splits.length > 2)
        {
            return resume(splits[$ - 2 .. $].join('.'));
        }
        return str[0 .. 8] ~ "..." ~ str[$ - 8 .. $];
    }
    return str;
}

string getHour()
{
    import std.datetime;
    import std.datetime.timezone;
    import std.array : appender;

    auto w = appender!string();
    SysTime today = Clock.currTime();
    formattedWrite!"%02d:%02d:%02d.%02d"(w, today.hour(), today.minute(),
            today.second(), cast(int) today.fracSecs().total!"msecs" / 10);
    return w.data;
}

enum LogPriority
{
    inconnu,
    défaut,
    verbeux,
    débug,
    info,
    avert,
    err,
    fatal,
    silence,
}
