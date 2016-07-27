#!/usr/bin/env ruby
#~ ------------------------------------------------------------------------------------------------------------
#~ This script starts a debugger waiting for the targeted app to launch, then it collects the instrumentation data.
#~ The app can quit and be restarted several times, the instrumentation data will merge until
#~ ./stop-instrumentation is called. 
#~ Usage: ./start-instrumentation <package-name> <device>. If <device> is not set, the first one found is used.
#~ Use this script between the installation and the launch the targeted application.
#~ ------------------------------------------------------------------------------------------------------------
#~ Copyright (C) 2016  Paul Irolla

#~ This program is free software: you can redistribute it and/or modify
#~ it under the terms of the GNU General Public License as published by
#~ the Free Software Foundation, either version 3 of the License, or
#~ (at your option) any later version.

#~ This program is distributed in the hope that it will be useful,
#~ but WITHOUT ANY WARRANTY; without even the implied warranty of
#~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#~ GNU General Public License for more details.

#~ You should have received a copy of the GNU General Public License
#~ along with this program.  If not, see <http://www.gnu.org/licenses/>.
#~ ------------------------------------------------------------------------------------------------------------

def getDevice()
  count = 3
  devices = []
  
  loop do
    devices = `timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" devices 2>&1`.chars.select(&:valid_encoding?).join.scan(/^([0-9a-z]+)\s+device/).map! { |match| match[0] }
    
    if devices.empty?
      system("\"#{$adb}\" kill-server && \"#{$adb}\" start-server")
      sleep 1
    else
      break
    end
    
    count -= 1
    raise 'No device plugged, exiting the program' if count == 0
  end
  
  return devices[0]
end

$ownPath = File.expand_path(File.dirname($0))

configMap = {}
configArray = IO.read("#{$ownPath}/config/paths.txt").split("\n").map do |line| 
  keyValue = line.split(':')
  unless keyValue.empty? || keyValue.size != 2
    keyValue[1].sub!(/ #.*/, '')
    configMap[keyValue[0]] = keyValue[1]
  end
end

$adb = configMap['adb']

device = ''

if ARGV.size != 1 && ARGV.size != 2
  raise <<TEXT
  
  usage: ./start-instrumentation <package-name> <device>. If <device> is not set, the first one found is used.
  Use this script between the installation and the launch the targeted application.
TEXT
end

if ARGV.size == 1
  device = getDevice
else
  device = ARGV[1]
end

Thread.fork do
  `timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" -s #{device} shell am instrument -w -r -e coverage true #{ARGV[0]}/com.zhauniarovich.bbtester.EmmaInstrumentation`
end
