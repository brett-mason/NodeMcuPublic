-- watch dog

if (_G["syslog"] == nil) then
  syslog = print
end

local function dsleep_internal(dsleep_time)
  print("Going to deep sleep for ", (dsleep_time / 1000 / 1000), " seconds")

  if rtctime and rtctime.get() == 0 then
    print "Using rtctime.dsleep()"
    rtctime.dsleep(dsleep_time)
  else
    print "Using node.dsleep()"
    node.dsleep(dsleep_time)
  end
end

function init_watchdog(timeout)
  local watchDogTimer = tmr.create()
  watchDogTimer:alarm(
    timeout,
    tmr.ALARM_SINGLE,
    function()
      print("Update timed out")
      print("Watchdog timer hit. Going to deep sleep for ", (timeout / 1000), " seconds")
      node.dsleep(timeout)
    end
  )
  syslog("Watch dog registered for ", (timeout / 1000), " seconds")
end

-- dsleep after giving the user warning to cancel.
function delayed_dsleep(delay_time, dsleep_time)
  syslog("Entering dsleep in  ", (delay_time / 1000), " seconds, init_timer.stop() to cancel")

  -- global so we can cancel it interactively.
  init_timer = tmr.create()
  init_timer:alarm(
    delay_time,
    tmr.ALARM_SINGLE,
    function()
      dsleep_internal(dsleep_time)
    end
  )
end
