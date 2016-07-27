#!/usr/bin/env ruby
#~ -----------------------------------------------------------------------------------------------
#~ Parse all coverage.txt files recursively in the given directory then prints the average overall 
#~ app coverage rate.
#~ Usage: ./get-average-coverage <instrumentation-directory>. 
#~ -----------------------------------------------------------------------------------------------
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
#~ ------------------------------------------------------------------------------------------------

if ARGV.nil? || ARGV.empty?
  raise <<TEXT
  
  usage: ./get-average-coverage <instrumentation-directory>.
  Use this script after you got the coverage results on all your dataset.
TEXT
end

unless File.exists? ARGV[0]
  print "directory #{ARGV[0]} does not exist\n"
  exit 1
end

files = Dir["#{ARGV[0]}/**/coverage.txt"]

if files.empty?
  print "directory #{ARGV[0]} and its subdirectories do not contain any coverage.txt files\n"
  exit 1
end

#~ coverageRegex = /([0-9]+)\s+%\s+\([0-9\/]+\)!*\s+([0-9]+)\s+%\s+\([0-9\/]+\)!*\s+([0-9]+)\s+%\s+\([0-9\/]+\)!*\s+all\s+classes/
coverageRegex = /\(([0-9]+)\/([0-9]+)\)[^(]+\(([0-9]+)\/([0-9]+)\)[^(]+\(([0-9]+)\/([0-9]+)\)[^(]+all\s+classes/
classCoverage = 0
methodCoverage = 0
blockCoverage = 0

failedEntry = 0
filesSize = files.size

files.each do |file|
  coverageText = IO.read(file)
  
  if coverageText =~ coverageRegex
    if $1 == "0" || $3 == "0" || $5 == "0"
      print "#{File.basename(File.dirname(file))} coverage probably failed as no code have been covered. This entry is skipped\n"
      failedEntry += 1
      next
    end
    
    classCoverage += $1.to_i*100/$2.to_f
    methodCoverage += $3.to_i*100/$4.to_f
    blockCoverage += $5.to_i*100/$6.to_f
  else
    print "#{File.basename(File.dirname(file))} coverage probably failed as the coverage.txt does not contain any parsable data\n"
    failedEntry += 1
    next
  end
end

appNb = (filesSize-failedEntry).to_f
if appNb == 0
  print "all coverages have failed, exiting\n"
  exit 1 
end

print "---------------------------------------------------------------\n"
print "number of apps with valid coverage: #{appNb.to_i}\n"
print "average overall coverage rate:\n"
print "  class coverage #{(classCoverage/appNb).round(2)}%,"
print "  method coverage #{(methodCoverage/appNb).round(2)}%,"
print "  block coverage #{(blockCoverage/appNb).round(2)}%\n"
print "---------------------------------------------------------------\n"
