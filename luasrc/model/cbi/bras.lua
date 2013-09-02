--[[
   LuCI-app-Bras
   Maintainer: xcy <xuchunyang56@gmail.com>
]]--
-- TODO: 调整提示信息

require("luci.tools.webadmin")

m = Map("bras", translate("Bras Connection"))

s = m:section(TypedSection, "bras")
s.anonymous = true

un = s:option(Value, "username", translate("Username"))
un.default=luci.util.exec("uci get bras.@bras[0].username")

pw = s:option(Value, "password", translate("Password"))
pw.password = true
pw.default=luci.util.exec("uci get bras.@bras[0].password")

local pid = luci.util.exec("/usr/bin/pgrep xl2tpd")
local pppd_pid = luci.util.exec("/usr/bin/pgrep pppd")
local message = luci.http.formvalue("message")

function bras_process_status()
   local status = "xl2tpd is not running now and "

   if pid ~= "" then
      status = "xl2tpd is running with the PID " .. pid .. "and "
   else
      status = 'Error xl2tpd is not running, Bras failed!'
   end
   if nixio.fs.access("/etc/rc.d/60bras") then
      status = status .. "it's enabled on the startup"
   else
      status = status .. "it's disabled on the startup"
   end

   if pppd_pid ~= "" then
      status = "Connected to Bras!"
   else
      status = "pppd is not running, Bras failed! "
   end
   local status = { status=status, message=message }
   local table = { pid=status }
   return table
end

t = m:section(Table, bras_process_status())
t.anonymous = true

t:option(DummyValue, "status", translate("Bras status"))

if message then
   t:option(DummyValue, "message", translate("Bras start message"))
end

if pid == "" then
   start = t:option(Button, "_start", translate("Start"))
   start.inputstyle = "apply"
   function start.write(self, section)
      message = luci.util.exec("/etc/init.d/bras start 2>&1")
      luci.util.exec("sleep 2")
      luci.http.redirect(
         luci.dispatcher.build_url("admin", "services", "bras") .. "?message=" .. message
      )
   end
else
   stop = t:option(Button, "_stop", translate("Stop"))
   stop.inputstyle = "reset"
   function stop.write(self, section)
      luci.util.exec("/etc/init.d/bras stop")
      luci.util.exec("sleep 2")
      luci.http.redirect(
         luci.dispatcher.build_url("admin", "services", "bras")
      )
   end
end

if nixio.fs.access("/etc/rc.d/S60bras") then
   disable = t:option(Button, "_disable", translate("Disable from startup"))
   disable.inputstyle = "remove"
   function disable.write(self, section)
      luci.util.exec("/etc/init.d/bras disable")
      luci.util.exec("sleep 1")
      luci.http.redirect(
         luci.dispatcher.build_url("admin", "services", "bras")
      )
   end
else
   enable = t:option(Button, "_enable", translate("Enable on startup"))
   enable.inputstyle = "apply"
   function enable.write(self, section)
      luci.util.exec("/etc/init.d/bras enable")
      luci.util.exec("sleep 1")
      luci.http.redirect(
         luci.dispatcher.build_url("admin", "services", "bras")
      )
   end
end

return m
