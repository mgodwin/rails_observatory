Redis lua scripts can be challenging to debug, you can't print debugging statements


# Debugging Redis Lua Scripts
There's no native print/debugging support in redis lua scripts,
so in order to debug them, you can either rely on the `return` value
or use the redis lua debugger.

https://redis.io/docs/latest/develop/programmability/lua-debugging/#breakpoints

Since our docker container runs redis, we can't just use the redis-cli with our scripts, we need to
copy them into the container first.

There is a bin/debug-redis-script helper script that will help you with this.


## Other tips

You can use redis.debug(...) to print information when in a debugging session.

You can place redis.breakpoint() in your script to pause execution during the debugger.

Use the `help` command to see what you can do in the debugger.