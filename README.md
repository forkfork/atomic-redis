atomic-redis
============

Safely (in a multiprocess environment) and easily read and modify JSON structures in Redis keys.

Redis is a commonly used as a mini 'database' for caching, shared queues, and similar. It is generally fast & reliable for these tasks. Redis does not support nested data types.

Sometimes we want to group a few items in a single Redis value. Operations on this single value are atomic, however multiple clients updating multiple values in the same value will step on each others toes unless locking on the value.

atomic-redis is a simple tool for applying changes to a JSON value stored in Redis key atomically. This is achieved through the use of the EVAL command which will lock the database for a very short time in order to apply the operation. In some cases this is easier (and can be faster) than manually locking on the relevant Redis key.

Currently this is implemented for Lua clients. However it will be trivial to extend this to Javascript and other languages as most of the logic is found in the EVAL script.

Example
=======

redis = require 'redis'
atomic_redis = require './atomic_redis'

client = redis.connect('127.0.0.1', 6379)

-- set up a todo_lists object on the key "user:tim@tim.com" from above

user:set("todo_lists", {{name = "Work", items = {}}, {name = "Home", items = {}}})

-- set a key "password" to point to a value "hunter2" in the "user:tim@tim.com" key

user:set("password","hunter2")

-- Delete the element in todo_lists array which matches a key "name" and value "Home"

user("todo_lists"):match("name", "Home"):del()

How it works
============

Commands are turned into a reverse polish notation, passed through the eval call, and then executed by Redis. They are more like a diff rather than a full object update (although the full object is parsed and updated inside the Redis EVAL).

TODO
====

Add Tests
Pass through the SHA1 version of the Lua script rather than the full script (saves network traffic to Redis)
Node.js / NPM implementation
