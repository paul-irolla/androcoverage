#!/usr/bin/env ruby
#~ --------------------------------------------------------------------------------------------------
#~ This script gives a broadcast order to stop all instrumentation. The instrumentation process will 
#~ write data in sdcard/<package-name>/coverage-<timestamp>.txt. This file is pulled in the 
#~ <instrumentation-directory>. Generate a coverage.txt report at last.
#~ Usage: ./stop-instrumentation <instrumentation-directory> <package-name> <device>. If <device> is 
#~ not set, the first one found is used. Use this script after quitting the application.
#~ --------------------------------------------------------------------------------------------------
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
#~ ---------------------------------------------------------------------------------------------------

require 'fileutils'

def usage
  raise <<TEXT
  
  Usage: ./stop-instrumentation <instrumentation-directory> <package-name> <device>. If <device> is 
  not set, the first one found is used. Use this script after quitting the application.
TEXT
end

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
    raise "\nNo device plugged, exiting the program" if count == 0
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
$emmaJar = "#{$ownPath}/tools/emma.jar"

device = ''

usage if ARGV.size != 2 && ARGV.size != 3

localDir = "#{ARGV[0]}/#{ARGV[1]}"
localCoverageFile = "#{localDir}/coverage.ec"

unless File.exists? localDir 
  print "\n#{localDir} does not exist.  "
  usage
end

unless File.exists? "#{localDir}/coverage.em" 
  print "\n#{localDir}/coverage.em does not exist.  "
  usage
end

if ARGV.size == 2
  device = getDevice
else
  device = ARGV[2]
end

`timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" -s #{device} shell am broadcast -a com.zhauniarovich.bbtester.finishtesting`
sleep 1

coverageFiles = `timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" -s #{device} shell ls /mnt/sdcard/#{ARGV[1]}/*.ec 2>&1`.chars.select(&:valid_encoding?).join.split("\n")
raise "\nNo coverage file found." if coverageFiles.empty? || coverageFiles[0] =~ /No such file or directory/

timestamps = coverageFiles.map do |file|
  $1.to_i if file =~ /([0-9]+)\.ec/
  0
end

maxIndex = 0
max = 0
for i in 0..timestamps.size-1
  if timestamps[i] > max
    max = timestamps[i]
    maxIndex = i
  end
end

FileUtils.rm(localCoverageFile) if File.exists? localCoverageFile
`timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" -s #{device} pull #{coverageFiles[maxIndex].strip} "#{localCoverageFile}" 2>&1`

FileUtils.rm("#{localDir}/coverage.txt") if File.exists? "#{localDir}/coverage.txt"
`cd "#{localDir}" && java -cp "#{$emmaJar}" emma report -r txt -in coverage.em -in coverage.ec 2>&1`

`timeout --preserve-status --signal=TERM --kill-after=5 10 "#{$adb}" -s #{device} shell rm -rf /mnt/sdcard/#{ARGV[1]}/`

