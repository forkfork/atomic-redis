redis = require 'redis'
atomic_redis = require './atomic_redis'

client = redis.connect('127.0.0.1', 6379)

local user = atomic_redis(client, "user:tim@tim.com")

-- set a key "password" to point to a value "hunter2" in the "user:tim@tim.com" key

user:set("password","hunter2")

-- set up a todo_lists object on the key "user:tim@tim.com" from above

user:set("todo_lists", {{name = "Work", items = {}}, {name = "Home", items = {}}})

-- Delete the element in todo_lists array which matches a key "name" and value "Home"

user("todo_lists"):match("name", "Home"):del()
