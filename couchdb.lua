-- Copyright (C) 2010  Ministério da Cultura do Brasil
-- Copyright (C) 2010  Lincoln de Sousa <lincoln@comum.org>
-- Copyright (C) 2010  Thiago Silva <thiago@comum.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>

module("couchdb", package.seeall)
local json = require("json")
local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")

Session = {uri="http://localhost:5984"}

Database = {session=nil, name=nil}

Document = {id=nil, rev=nil, schema=nil}

function Session:new(uri)
   local o = {}
   setmetatable(o, self)
   self.__index = self
   if uri ~= nil then
      o.uri = uri
   end
   return o
end

function Database:new(session, name)
   local o = {}
   setmetatable(o, self)
   self.__index = self
   o.session = session
   o.name = name
   return o
end

function Document:new(schema)
   local o = {}
   setmetatable(o, self)
   self.__index = self
   self.schema = schema
   if schema.id ~= nil then
      o.id = schema.id
   end
   return o
end

local function _do_request(url, method, content)
   local t = {}
   local source = nil
   local headers = nil

   -- Converting lua object in content to json. If content is set, we should
   -- also set the Content-Type header
   if content ~= nil then
      local ct = json.encode(content)
      source = ltn12.source.string(ct)
      headers = {}
      headers['Content-Type'] = 'application/json'
      headers['Content-Length'] = #ct
   end

   local _, code, headers, human_readable_error = http.request{
      url=url,
      method=method,
      headers=headers,
      sink=ltn12.sink.table(t),
      source=source
   }

   -- Getting the body content from the ltn12 sink
   local body = table.concat(t)

   -- Handling all errors together
   if code > 299 then
      error(human_readable_error)
   else
      return json.decode(body)
   end
end

function Session:all_dbs()
   local result = {}
   for _, v in pairs(_do_request(self.uri .. "/_all_dbs", "GET")) do
      table.insert(result, Database:new(self, v))
   end
   return result
end

function Database:create()
   _do_request(self.session.uri .. "/" .. self.name, "PUT")
end

function Database:delete()
   return _do_request(self.session.uri .. "/" .. self.name, "DELETE")
end

function Database:put(doc)
   local result = nil
   if doc.id ~= nil then
      result = _do_request(
         string.format("%s/%s/%s", self.session.uri, self.name, doc.id),
         "PUT", doc.schema)
   else
      result = _do_request(
         string.format("%s/%s", self.session.uri, self.name), "POST",
         doc.schema)
   end
   doc.id = result.id
   doc.rev = result.rev
end

return _M
