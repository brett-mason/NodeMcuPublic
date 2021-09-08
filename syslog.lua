local config = require("settings")

print("syslog config:", "host: ", config.syslog.host, "port: ", config.syslog.port, "appname: ", config.appName)

function syslog(...)
  -- TODO: append hostname / mac / ip
  -- TODO: Dont let DNS cause rest to fail.
  -- sequence / date?

  local ip = config.syslog.host
  local port = config.syslog.port
  local appName = config.appName

  local messageBuilder = {}
  table.insert(messageBuilder, "mac:" .. wifi.sta.getmac() .. ": ")
  table.insert(messageBuilder, "appName: " .. appName .. ": ")
  for i, v in ipairs(arg) do
    table.insert(messageBuilder, tostring(v))
  end
  table.insert(messageBuilder, "\n")
  local message = table.concat(messageBuilder, " ")
  messageBuilder = nil

  print("syslog: ", message)

  -- FIXME: If doing this, syslog needs a callback to stop race condition for networking. Only for DNS case.
  -- Could also implement a dns cache.
  -- net.dns.resolve(
  --   config.syslog.host,
  --   function(sk, ip)
  --     print("DNS result:", host, ip)
  --     if (ip == nil) then
  --       -- FIXME call back gets called twice.
  --       print("DNS fail! ", host)
  --       return
  --     end
  -- end
  -- )

  if wifi.sta.status() ~= wifi.STA_GOTIP then
    print("Wifi is not up, not sending syslog")
    return
  end

  local udpSocket = net.createUDPSocket()
  udpSocket:send(port, ip, message)
  udpSocket:close()
end
