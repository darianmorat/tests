-- Example Lua program for theme testing
-- Covers tables, metatables, OOP-like patterns, coroutines, modules, JSON, and error handling.

local json = require("dkjson") -- Common JSON library for Lua (optional if installed)
local socket = require("socket") -- Simulate delays

-- ##############################
-- Interfaces and OOP Simulation
-- ##############################

---@class Storage
---@field store fun(self, key: string, value: any): boolean
---@field get fun(self, key: string): any
---@field delete fun(self, key: string): boolean

---@class MemoryStorage: Storage
local MemoryStorage = {}
MemoryStorage.__index = MemoryStorage

function MemoryStorage:new()
   return setmetatable({ data = {} }, self)
end

function MemoryStorage:store(key, value)
   self.data[key] = value
   return true
end

function MemoryStorage:get(key)
   return self.data[key]
end

function MemoryStorage:delete(key)
   if self.data[key] ~= nil then
      self.data[key] = nil
      return true
   end
   return false
end

-- ##############################
-- User Data Model
-- ##############################

---@class User
local User = {}
User.__index = User

function User:new(id, name, email)
   return setmetatable({
      id = id,
      name = name,
      email = email,
      created = os.date("!%Y-%m-%dT%H:%M:%SZ"),
   }, self)
end

-- ##############################
-- Server Simulation
-- ##############################

local Server = {}
Server.__index = Server

function Server:new(storage, port)
   return setmetatable({ storage = storage, port = port }, self)
end

function Server:create_user(name, email)
   local id = tostring(os.time() .. math.random(1000, 9999))
   local user = User:new(id, name, email)
   local key = "user:" .. id
   self.storage:store(key, user)
   return user
end

function Server:get_users()
   local users = {}
   for _, v in pairs(self.storage.data) do
      table.insert(users, v)
   end
   return users
end

-- ##############################
-- Error handling
-- ##############################

local function safe_call(fn, ...)
   local ok, result = pcall(fn, ...)
   if not ok then
      print("Error:", result)
      return nil
   end
   return result
end

-- ##############################
-- Coroutine worker pool
-- ##############################

local function worker(id, jobs, results)
   for job in jobs do
      socket.sleep(0.1) -- simulate work
      local result = string.format("Worker %d processed job %s", id, job)
      results[#results + 1] = result
      coroutine.yield()
   end
end

local function process_jobs(num_workers, job_data)
   local results = {}
   local coroutines = {}

   for i = 1, num_workers do
      coroutines[i] = coroutine.create(function()
         return worker(i, job_data, results)
      end)
   end

   for _, co in ipairs(coroutines) do
      while coroutine.status(co) ~= "dead" do
         coroutine.resume(co)
      end
   end

   return results
end

-- ##############################
-- Main
-- ##############################

math.randomseed(os.time())

local storage = MemoryStorage:new()
local server = Server:new(storage, 8080)

-- Create some users
server:create_user("Alice", "alice@example.com")
server:create_user("Bob", "bob@example.com")

-- Get users
local users = safe_call(function()
   return server:get_users()
end)
print("Users in storage:")
print(json.encode(users, { indent = true }))

-- Process jobs concurrently
print("\nProcessing jobs with coroutines:")
local results = process_jobs(3, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
for _, r in ipairs(results) do
   print(r)
end

-- Simulate health check
print("\nHealth check:")
print(json.encode({
   status = "healthy",
   timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
}, { indent = true }))
