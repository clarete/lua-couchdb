-- Copyright (C) 2010  Lincoln de Sousa <lincoln@comum.org>
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

function Session:new(uri)
   local o = {}
   setmetatable(o, self)
   self.__index = self
   if uri ~= nil then
      o.uri = uri
   end
   return o
end

local function _do_request(url, method)
   local t = {}
   local _, code, headers, human_readable_error = http.request{
      url=url,
      method=method,
      sink=ltn12.sink.table(t)
   }

   -- Getting the body content from the ltn12 sink
   local body = t[1]

   -- Handling all errors together
   if code > 299 then
      error({message=human_readable_error})
   else
      return json.decode(body)
   end
end

function Session:all_dbs()
   return _do_request(self.uri .. "/_all_dbs", "GET")
end

function Session:create_database(name)
   return _do_request(self.uri .. "/" .. name, "PUT")
end

return _M
