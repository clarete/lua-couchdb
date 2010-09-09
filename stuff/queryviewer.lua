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

local gtk = require("gtk")
local gtksourceview = require("gtksourceview")
local json = require("json")
local http = require("socket.http")
local ltn12 = require("ltn12")

Application = {
   window=nil,
   dbentry=nil,
   inputbuff=nil,
   outputbuff=nil,
}

function Application:new()
   -- Setting some default values for our window
   self.window = gtk.window_new(gtk.GTK_WINDOW_TOPLEVEL)
   self.window:set_default_size(640, 480)
   self.window:set_position(gtk.GTK_WIN_POS_CENTER_ALWAYS)
   self.window:set_border_width(12)
   self.window:connect('delete-event', gtk.main_quit)
   self.window:set_title("CouchDB Query Viewer")

   -- Adding the main box of our window
   local paned = gtk.vpaned_new()
   self.window:add(paned)

   -- The entry that will hold the database uri
   self.dbentry = gtk.entry_new()
   local label = gtk.label_new('Database uri: ')
   local hbox = gtk.hbox_new(false, 0)
   hbox:pack_start(label, false, false, 0)
   hbox:pack_start(self.dbentry, true, true, 0)

   -- Creating the first sourceview and configure its language, creating a
   -- buffer and setting its lang
   local lang_manager = gtksourceview.language_manager_get_default()
   local lang = lang_manager:get_language('js')
   self.inputbuff = gtksourceview.buffer_new_with_language(lang)
   local inputtview = gtksourceview.view_new_with_buffer(self.inputbuff)
   swin = gtk.scrolled_window_new(nil, nil)
   swin:add(inputtview)
   swin:set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
   swin:set_shadow_type(gtk.SHADOW_IN)

   -- Creating the 'execute' button
   local exec_button = gtk.button_new_with_mnemonic("_Execute")
   exec_button:connect('clicked', function () self:execute() end)
   local bbox = gtk.hbox_new(false, 0)
   bbox:pack_end(exec_button, false, false, 0)

   -- Time to create the output buffer
   self.outputbuff = gtksourceview.buffer_new_with_language(lang)
   local outputtview = gtksourceview.view_new_with_buffer(self.outputbuff)
   swin2 = gtk.scrolled_window_new(nil, nil)
   swin2:add(outputtview)
   swin2:set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
   swin2:set_shadow_type(gtk.SHADOW_IN)

   -- Packing first source view and button box and then adding it to the first
   -- slot of the main horizontal pane
   local fbox = gtk.vbox_new(false, 0)
   fbox:pack_start(hbox, false, false, 4)
   fbox:pack_start(swin, true, true, 0)
   fbox:pack_start(bbox, false, false, 4)
   paned:add1(fbox)
   paned:add2(swin2)

   return self
end

function Application:execute()
   -- Doing all this work to get text from the input buffer
   local selection_bound = self.inputbuff:get_mark("selection_bound")
   local insert = self.inputbuff:get_mark("insert")
   local siter = gtk.new("GtkTextIter")
   local eiter = gtk.new("GtkTextIter")
   self.inputbuff:get_iter_at_mark(siter, selection_bound)
   self.inputbuff:get_iter_at_mark(eiter, insert)
   data = self.inputbuff:get_text(siter, eiter, false)

   -- Getting the database url
   local url = self.dbentry:get_text()

   -- Preparing everything to be sent in the request
   local t = {}
   local encoded = json.encode({map=data})
   local source = ltn12.source.string(encoded)
   local headers = {}
   headers['Content-Type'] = 'application/json'
   headers['Content-Length'] = #encoded

   -- Finally, sending the request
   local _, code, headers, error = http.request{
      url=url,
      method="POST",
      headers=headers,
      sink=ltn12.sink.table(t),
      source=source
   }

   local body = table.concat(t)
   self.outputbuff:set_text(body, #body)
end

local app = Application:new()
app.window:show_all()
gtk.main()
