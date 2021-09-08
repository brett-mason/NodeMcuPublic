-- MH-Z19 CO2 Sensor reading via PWM.

-- NOTE : pwm returns 400 during sensor startup.
-- TODO Convert a lua module.

if (_G["syslog"] == nil) then
  syslog = print
end

function sampleco2ppm(gpiopin, sampleCount, resultCallback)
  syslog("sampling pwm on pin", gpiopin, "sample count", sampleCount)

  local timeoutTimer = tmr.create()

  local function cleanup()
    gpio.trig(gpiopin, "none")
    timeoutTimer:stop()
    timeoutTimer:unregister()
  end

  timeoutTimer:alarm(
    sampleCount * 3 * 1000,
    tmr.ALARM_SINGLE,
    function()
      syslog("sampling timed out")
      cleanup()
      resultCallback(nil)
    end
  )

  -- use pin 1 as the input pulse width counter
  local pulse1 = 0
  local timelow, timehigh = 0, 0
  local results = {}

  gpio.mode(gpiopin, gpio.INT)

  local function calcppm(tl, th)
    --Cppm = 2000 * (Th - 2ms)/(Th + Tl - 4ms)
    -- co2_ppmscale = max value 2000,5000,etc
    ppm = co2_ppmscale * (th - co2_ppmscale) / (th + tl - 4000)
    return ppm
  end

  local function average(numbers)
    local sum = 0
    local len = table.getn(numbers)
    for i = 1, len do
      sum = sum + numbers[i]
    end
    return sum / len
  end

  local function pin1cb(level)
    local pulse2 = tmr.now()
    --print( level == gpio.HIGH  and "up  " or "down", pulse2 - pulse1 )
    if (pulse1 > 0) then
      if (level == gpio.HIGH) then
        timelow = pulse2 - pulse1
      else
        timehigh = pulse2 - pulse1
      end
    end

    if (timelow > 0 and timehigh > 0) then
      ppm = calcppm(timelow, timehigh)
      syslog("ppm result:", ppm, timelow, timehigh, table.getn(results))
      table.insert(results, ppm)
    end
    if (table.getn(results) >= sampleCount) then
      cleanup()
      resultCallback(average(results))
      return
    end

    --print('calcppm', calcppm( timelow, timehigh), table.getn(results))
    pulse1 = pulse2
    gpio.trig(gpiopin, level == gpio.HIGH and "down" or "up")
  end

  gpio.trig(gpiopin, "down", pin1cb)

  --print ("co2-pwm end")
end

function co2_sampler()
  syslog("sampling every 10 seconds, average of samples.")
  sampleco2ppm(
    2,
    5,
    function(co2)
      syslog("result", co2)
    end
  )
end

--tmr.alarm(0, 15*1000, tmr.ALARM_AUTO, co2_sampler)
--co2_sampler()
