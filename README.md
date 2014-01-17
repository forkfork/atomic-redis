atomic-redis
============

Safely (in a multiprocess environment) and easily read and modify JSON structures in Redis keys. Normally if two processes read a JSON value, and both update different values within that JSON object, when they write back to the Redis they will destroy the others change (unless they provide locking). This library avoids that issue.

This is achieved through the use of the EVAL command which will lock other evals for a very short time in order to apply the operation. In most cases this is easier (and faster) than manually locking on the relevant Redis key.

Currently this is implemented for Lua clients. However it will be trivial to extend this to Javascript and other languages as most of the logic is found in the EVAL script.

Example
=======

```
redis = require 'redis'
atomic_redis = require './atomic_redis'

client = redis.connect('127.0.0.1', 6379)

local user = atomic_redis(client, "KEYNAME")

-- set up a todo_lists object on the key "KEYNAME" from above

user:set("todo_lists", {{name = "Work", items = {}}, {name = "Home", items = {}}})

-- set a key "password" to point to a value "hunter2" in the "KEYNAME" key

user:set("password","hunter2")

-- Delete the element in todo_lists array which matches a key "name" and value "Home"

user("todo_lists"):match("name", "Home"):del()
```

How it works
============

Commands are turned into a reverse polish notation, passed through the eval call, and then executed by Redis. They are more like a diff rather than a full object update (although the full object is parsed and updated inside the Redis EVAL).

TODO
====

```
Add Tests
Pass through the SHA1 version of the Lua script rather than the full script (saves network traffic to Redis)
Node.js / NPM implementation
```
