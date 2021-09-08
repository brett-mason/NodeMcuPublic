function domoticz_send(idx, nvalue, svalue, callback)
  local messageBuilder = {}
  table.insert(
    messageBuilder,
    string.format("http://%s:%s/json.htm?type=command&param=udevice&idx=%s", domo_host, domo_port, idx)
  )

  if (nvalue) then
    table.insert(messageBuilder, "&nvalue=" .. nvalue)
  end
  if (svalue) then
    table.insert(messageBuilder, "&svalue=" .. svalue)
  end

  local url = table.concat(messageBuilder, "")
  messageBuilder = nil

  print("Http url: ", url)
  http.get(
    url,
    nil,
    function(code, data)
      print("Http: code: ", code)
      print("Http: data: ", data)

      -- always callback to continue
      callback()
    end
  )
end

function domoticz_send_temp(idx, temperature, callback)
  local temp_svalue = string.format("%.3f", temperature)
  domoticz_send(idx, 0, temp_svalue, callback)
end

function domoticz_send_temp_humidity(idx, temperature, humidity, callback)
  local temp_svalue = string.format("%.3f;%.3f;0", temperature, humidity)
  domoticz_send(idx, 0, temp_svalue, callback)
end

function domoticz_send_co2(idx, co2ppm, callback)
  domoticz_send(domo_co2_dev_idx, co2ppm, nil, callback)
end
