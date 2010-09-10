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
local http = require("socket.http")
local ltn12 = require("ltn12")

-- Prototypes

local Session = {uri="http://localhost:5984"}

local Database = {session=nil, name=nil}

local Document = {id=nil, rev=nil, schema=nil}


local function delegate(parent)
   local obj = {}
   local mt = {}
   setmetatable(obj, mt)
   mt.__index = parent
   return obj
end


-- util

function select(tb, fun)
   local ret = {}
   for k,v in pairs(tb) do
      if (fun(v,k)) then
         ret[k] = v
      end
   end
   return ret
end

-- Local functions

local function _do_request(url, method, content)
   local t = {}
   local source = nil
   local headers = nil

   -- Converting lua object in content to json. If content is set, we should
   -- also set the Content-Type header
   if content then
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

-- Constructors

function create_session(uri)
   local obj = delegate(Session)
   obj.uri = uri or obj.uri
   return obj
end

function create_database(session,name)
   local obj = delegate(Database)
   obj.session, obj.name = session, name
   return obj
end

function create_document(schema)
   local obj = delegate(Document)
   if schema.id then
      obj.id = schema.id
      obj.schema = select(schema, function(v,k) return k ~= 'id' end)
   else
      obj.schema = schema
   end
   return obj
end


-- Session methods

function Session:all_dbs()
   local result = {}
   for _, v in pairs(_do_request(self.uri .. "/_all_dbs", "GET")) do
      table.insert(result, create_database(self, v))
   end
   return result
end

-- Database methods

function Database:create()
   _do_request(self.session.uri .. "/" .. self.name, "PUT")
end

function Database:delete()
   return _do_request(self.session.uri .. "/" .. self.name, "DELETE")
end

function Database:put(doc)
   local result = nil
   if doc.id then
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

function Database:delete_doc(doc)
   local uri = string.format(
      "%s/%s/%s?rev=%s", self.session.uri, self.name, doc.id, doc.rev)
   local result =_do_request(uri, "DELETE")
   doc.id = nil
   doc.rev = nil
   return result
end

function Database:all_docs()
   local uri = string.format("%s/%s/_all_docs", self.session.uri, self.name)
   return _do_request(uri, "GET")
end

-- Document methods

return _M
