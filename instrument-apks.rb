#!/usr/bin/env ruby

#~ --------------------------------------------------------------------------------------------------
#~ This script create a instrumented copy of each apk from the given directories.

#~ usage: ./instrument-apk <dataset-dir-1> ... <dataset-dir-n> <output-dir>. 
#~ This script instruments all apks in the given directories recursively. 
#~ <dataset-dir-k> can be a single file.
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

# project paths
$ownPath = File.expand_path(File.dirname($0))
$paths = { :dex2jar => "#{$ownPath}/tools/dex2jar/d2j-dex2jar.sh",
           :jar2dex => "#{$ownPath}/tools/dex2jar/d2j-jar2dex.sh",
           :apktool => "#{$ownPath}/tools/apktool.jar",
           :tmpDir => "#{$ownPath}/tmp",
           :emma => "#{$ownPath}/tools/emma.jar",
           :emmaRuntime => "#{$ownPath}/tools/emma-runtime.jar",
           :output => "#{$ownPath}/instr-dataset",
           :input => "#{$ownPath}/dataset",
           :keystore => "#{$ownPath}/config/androcoverage.keystore",
           :zipalign => "#{$ownPath}/tools/zipalign",
           :emmaAssets => "#{$ownPath}/tools/emma-assets",
           :dx => "#{$ownPath}/tools/dx.jar",
           :instrumentClass => "#{$ownPath}/tools/instrument-class/com",
           :aapt => "#{$ownPath}/tools/aapt" }

# definitions
def decompileManifest
  aapt d xmltree com.package.apk AndroidManifest.xml
end

def dex2class(inputFile, outputPath, outputDirName = "classes")
  `#{$paths[:dex2jar]} --output "#{outputPath}/#{outputDirName}.jar" "#{inputFile}" 2>&1`
  `unzip "#{outputPath}/#{outputDirName}.jar" -d "#{outputPath}/#{outputDirName}" 2>&1`
  FileUtils.rm_rf("#{outputPath}/#{outputDirName}.jar")
end

def dex2jar(inputFile, outputFile)
  `#{$paths[:dex2jar]} --output "#{outputFile}" "#{inputFile}" 2>&1`
end

def class2jar(inputPath, outputFile)
  `cd "#{inputPath}" && zip -r "#{outputFile}" * 2>&1`
end

def class2dex(inputPath, outputPath, keepOriginal = false)
  FileUtils.mv("#{outputPath}/classes.dex", "#{outputPath}/classes.dex.original") if keepOriginal
  `cd "#{inputPath}" && zip -r "#{outputPath}/classes.jar" * 2>&1`
  `#{$paths[:jar2dex]} --force --output "#{outputPath}/classes.dex" "#{outputPath}/classes.jar" 2>&1`
  FileUtils.rm("#{outputPath}/classes.jar")
end
  
def apk2dex(inputFile, outputPath, noRes = false)
  arg = ''
  arg = '--no-res' if noRes
  
  `java -jar "#{$paths[:apktool]}" --quiet d --no-src --keep-broken-res #{arg} "#{inputFile}" --output "#{outputPath}" 2>&1`
end

def dex2apk(inputPath, outputFile)
  `java -jar "#{$paths[:apktool]}" b "#{inputPath}" --output "#{outputFile}" 2>&1`
end

def instrClasses(inputPath, outputPath, coverfile)
  `java -cp "#{$paths[:emma]}" emma instr -d "#{outputPath}" -ip "#{inputPath}" -out "#{coverfile}" 2>&1`
end

def addEmmaJar(inputFile, outputFile)
  `java -jar "#{$paths[:dx]}" --dex --output="#{outputFile}" "#{inputFile}" "#{$paths[:emmaRuntime]}" 2>&1`
end

def instrumentManifest(apkTmpPath, packageName)
  # add the permission for accessing the sdcard if it does not exist
  manifest = IO.read("#{apkTmpPath}/AndroidManifest.xml")
  
  if manifest !~ /android\.permission\.WRITE_EXTERNAL_STORAGE/
    manifest.sub!(/(<manifest [^>]+>)/, "\\1\n" + '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>' + "\n")
  end
  
  # declare the instrumentation class
  manifest.sub!(/(<manifest [^>]+>)/, "\\1\n" + "<instrumentation\nandroid:name=\"com.zhauniarovich.bbtester.EmmaInstrumentation\"\nandroid:targetPackage=\"#{packageName}\" />" + "\n")
  
  File.open("#{apkTmpPath}/AndroidManifest.xml", 'w') { |file| file << manifest }
end

def instrumentApk(apkPath, output)
  apkName = File.basename(apkPath)
  apkTmpPath = "#{$paths[:tmpDir]}/#{apkName}.src"
  FileUtils.rm_rf(apkTmpPath) if File.exists? apkTmpPath
  
  print "  instrumenting #{apkName}\n"
  
  # get package name
  aaptResults = `"#{$paths[:aapt]}" d permissions "#{apkPath}" 2>&1`
  if aaptResults =~ /package: ([^\s]+)/
    packageName = $1
  else
    print "    package name unavailable\n"
    return
  end
  
  instrApkPath = "#{$paths[:output]}/#{packageName}"
  FileUtils.mkdir(instrApkPath) unless File.exists? instrApkPath
  
  # reverse manifest, instrument, save it recompiled then reverse the app without resources
  apkNewTmpFile = "#{$paths[:tmpDir]}/#{apkName}.tmp.apk"
  instrManifestFile = "#{$paths[:tmpDir]}/#{apkName}-AndroidManifest.xml"
  manifestFile = "#{apkTmpPath}/AndroidManifest.xml"
  
  apk2dex(apkPath, apkTmpPath)
  instrumentManifest(apkTmpPath, packageName)
  dex2apk(apkTmpPath, apkNewTmpFile)
  `unzip -p "#{apkNewTmpFile}" AndroidManifest.xml > "#{instrManifestFile}"`
  FileUtils.rm_rf([apkTmpPath, apkNewTmpFile])
  
  # reverse apk
  apk2dex(apkPath, apkTmpPath, true)
  
  # replace manifest with the encoded and instrumented one
  dexFile = "#{apkTmpPath}/classes.dex"
  jarFile = "#{apkTmpPath}/classes.jar"
  classPath = "#{apkTmpPath}/classes"
  
  FileUtils.rm(manifestFile)
  FileUtils.mv(instrManifestFile, manifestFile)
  
  dex2class(dexFile, apkTmpPath)
  FileUtils.rm(dexFile)

  # remove android-support libs from instrumentation
  supportLibs = false
  if File.exists? "#{classPath}/android"
    if File.exists? "#{classPath}/android/support"
      FileUtils.mv("#{classPath}/android/support", apkTmpPath)
      supportLibs = true
    end
  end
  
  # execute emma for classes instrumentation
  instrClasses(classPath, "#{apkTmpPath}/#{output}", "#{instrApkPath}/coverage.em")
  
  # rearange classe files for apk reconstruction
  instrFiles = Dir["#{apkTmpPath}/#{output}/**/*"]
  instrFiles.each do |instrFile|
    unless File.directory? instrFile
      FileUtils.mv(instrFile, instrFile.sub(output, 'classes'))
    end
  end
  FileUtils.mv("#{apkTmpPath}/support", "#{classPath}/android") if supportLibs
  
  # add bboxtester instrumentation class
  FileUtils.cp_r($paths[:instrumentClass], classPath)

  # merge apk code and emma code, then build dex
  class2jar(classPath, jarFile)
  addEmmaJar(jarFile, dexFile)  
  
  unless File.exists? dexFile
    print "    dx could not build the instrumented classes.dex, skipping the app\n"
    FileUtils.rm_rf([apkTmpPath, instrApkPath])
    return
  end
  
  # clean tmp classes files
  FileUtils.rm_rf(["#{apkTmpPath}/classes", "#{apkTmpPath}/#{output}", "#{apkTmpPath}/classes.jar"])
  
  # recompile
  instrApkFile = "#{instrApkPath}/#{apkName}"
  dex2apk(apkTmpPath, instrApkFile)
  
  # clean tmp
  FileUtils.rm_rf(apkTmpPath)
  
  # add Emma resources to the apk root
  FileUtils.cp_r(["#{$paths[:emmaAssets]}/emma_ant.properties",
                  "#{$paths[:emmaAssets]}/emma_default.properties",
                  "#{$paths[:emmaAssets]}/com"],
                  instrApkPath)
  `cd "#{instrApkPath}" && zip -m -r "#{instrApkFile}" emma_ant.properties emma_default.properties com 2>&1`
  
  # sign apk and zipalign
  `jarsigner -storepass android -keystore "#{$paths[:keystore]}" "#{instrApkFile}" androcoverage 2>&1`
  `#{$paths[:zipalign]} -v 4 "#{instrApkFile}" "#{instrApkPath}/tmp.apk"`
  FileUtils.mv("#{instrApkPath}/tmp.apk", instrApkFile )
end

#-----------------------------------------------------------------------

if ARGV.size < 2
  raise <<TEXT
  
  usage: ./instrument-apk <dataset-dir-1> ... <dataset-dir-n> <output-dir>. 
  This script instruments all apks in the given directories recursively. 
  <dataset-dir-k> can be a single file.
TEXT
end

files = []

output = ARGV.last
raise "\npath #{path} does not exists\n" unless File.exists? output
raise "\npath #{path} is not a directory\n" unless File.directory? output

ARGV[0..-2].each do |path|
  raise "\npath #{path} does not exists\n" unless File.exists? path
  
  if File.directory? path
    newFiles = Dir["#{path}/**/*.apk"]
    newFiles.push(*Dir["#{path}/**/*.APK"])
    files.push(*newFiles)
  else
    files << path
  end
end

files.sort!
files.uniq!

print "instrumenting #{files.size} files\n"

FileUtils.rm_rf($paths[:tmpDir]) if File.exists? $paths[:tmpDir]
FileUtils.mkdir $paths[:tmpDir]

files.each do |file|
  begin
    instrumentApk(file, output)
  rescue => error
    print "#{error} :\n  #{error.backtrace.join("\n  ")}\n"
  end
end

FileUtils.rm("classes-errors.zip") if File.exists? "classes-errors.zip"
