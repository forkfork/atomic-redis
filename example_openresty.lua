redis = require 'resty.redis'
atomic_redis = require './atomic_redis'

local client = redis:new()

client:connect('127.0.0.1', 6379)

local user = atomic_redis(client, "user:tim@tim.com")

user:set("todo_lists", {{name = "Work", items = {}}, {name = "Home", items = {}}})
user:set("password","hunter2")

ngx.say("Before Deletion:",client:get("user:tim@tim.com"),"<br>")

user("todo_lists"):match("name", "Home"):del()

ngx.say("Mid Deletion:",client:get("user:tim@tim.com"),"<br>")

user("todo_lists"):del()

ngx.say("Result:",client:get("user:tim@tim.com"))

-- OUTPUT
--
-- Before Deletion:{"password":"hunter2","groups":"50","todo_lists":[{"name":"Work","items":{}},{"name":"Home","items":{}}]}
-- Mid Deletion:{"password":"hunter2","groups":"50","todo_lists":[{"name":"Work","items":{}}]}
-- Result:{"password":"hunter2","groups":"50"}
