-- SHT30/SHT31 NdoeMCU module.

local moduleName = "sht30"
local M = {}
_G[moduleName] = M

local function write_reg(id, dev_addr, reg_addr, data)
  i2c.start(id)
  if not i2c.address(id, dev_addr, i2c.TRANSMITTER) then
    print("No ACK on address: ", dev_addr)
    return nil
  end
  i2c.write(id, reg_addr)
  local c = i2c.write(id, data)
  i2c.stop(id)
  return c
end

local function read_data(id, dev_addr, n)
  i2c.start(id)
  if not i2c.address(id, dev_addr, i2c.RECEIVER) then
    print("No ACK on address:", dev_addr)
  --return nil
  end
  local c = i2c.read(id, n)
  i2c.stop(id)
  return c
end

local function reset(id, dev_addr)
  -- Reset into known state.
  write_reg(id, dev_addr, 0x30, 0xA2)
  tmr.delay(100 * 1000)
end

function M.sample(id, dev_addr)
  print("sht30 read on id:", id, " device address:", dev_addr)

  reset(id, dev_addr)

  -- Measurement High Repeatability with Clock Stretch Enabled
  --local write_count = write_reg(Ide, SHTAddr, 0x2c, 0x06)
  -- Measurement High Repeatability with Clock Stretch Disabled
  local write_count = write_reg(id, dev_addr, 0x24, 0x00)
  --print("read temp+rh write_count", write_count)

  if not write_count then
    print("read temp+rh write_count", write_count)
    return nil
  end

  tmr.delay(500 * 1000)

  -- returns a string so we have to convert to bytes.
  local data = read_data(id, dev_addr, 6)
  --print("Raw", string.byte(data, 1, 6))

  local temp = (string.byte(data, 1) * 256.0) + string.byte(data, 2)
  temp = ((temp * 175.0) / 65535.0) - 45.0

  local rh = (string.byte(data, 4) * 256.0) + string.byte(data, 5)
  rh = (rh * 100.0) / 65535.0

  print("Temperature:", temp, "Humidity%:", rh)

  return temp, rh
end

-- local SHTAddr = 0x45
-- local sda = 2 -- GPIO4
-- local scl = 1 -- GPIO5
-- print("sht30 setup", "id", 0, "SDA", sda, "SCL", scl)
-- local result = i2c.setup(0, sda, scl, i2c.SLOW)
-- print("setup result", result)
-- tmr.delay(500 * 1000)

-- temp, rh = M.sample(0, SHTAddr)
-- print(temp, rh)

return M
