
# AndroCoverage

The AndroCoverage Dataset is a dataset of Android applications for the evaluation of automated testing tools. 
It contains 100 applications from [F-Droid](https://f-droid.org/). The dataset comes with tools for instrumenting 
the applications, starting/stopping the instrumentation and gathering overall statistics. The tools can be 
easily integrated in an automated testing process. 

### Dependencies

Almost all dependencies are distributed with the project. Nonetheless the `unzip`, `jarsigner`, `timeout` and `adb` commands must be working and
the project requires the JDKv7. The adb program can be found in your linux distribution repositories (at least on Ubuntu) or from the 
[Android SDK](https://developer.android.com/studio/index.html#downloads).


### Usage

###### Instrumentation of the applications:

```bash
  cd andro-coverage # The AndroCoverage scripts can be invoked from anywhere 
  ./instrument-apks <apk-dir/file-1> <apk-dir/file-2> ... <apk-dir/file-n> <result-dir> # Generic
  ./instrument-apks dataset instr-dataset # Example
```

Each instrumented apk will be found in its `<result-dir>/<package-name>/` directory along with a `coverage.em` file which 
gather static analysis data for processing the code coverage.


###### Starting the code coverage analysis:

Once the application is installed in the phone or emulator, an instrumentation class needs to be launched.
The following script starts from the host. 

```bash
  ./start-instrumentation.rb <package-name>
```

The package name of the application is the directory name of the instrumented apk.
Now the application can be launched and tested. It does not matter if the application is restarted several times, all called 
classes, methods or code blocks will be taken into account for the analysis.

 
###### Stopping the code coverage analysis:  

```bash
  ./stop-instrumentation.rb <result-dir> <package-name>
```

The script sends a broadcast message to the instrumentation class for stopping the analysis and writes the results in a 
`sdcard/<package-name>/coverage-<timestamp>.ec` file. Dynamical results are then compared to statistical ones , `coverage.ec`, 
and a `coverage.txt` report is generated. 


###### Gathering the results:

```bash
  ./get-average-coverage.rb <result-dir> 
```

It prints the overall code coverage statistics of all instrumented applications in the given directory.


###### Notes:

  * The tool for instrumenting the applications uses [Emma](http://emma.sourceforge.net/), which is an outdated framework and it is not maintained anymore. 
  The instrumentation works on the applications of the AndroCoverage Dataset but will probably fail on new applications, 
  hence we do not recommend using it for another purpose.

  * All classes under the path `android.support.*` are removed from the analysis, therefore they do not count for in coverage results.
  As lots of applications embed these large libraries for a very limited usage, it artificially decreases their performances
  for motives unrelated to automatic testing.
  
  * The instrumented application have an "EmmaInstrumentation" class that is instantiated externally. This class is responsible for managing the 
  instrumentation start, stop and the save of the data. It is called from the `start-instrumentation.rb` script and will fail if it is called from another source. 
  It can happen naturally for any Black/Grey Box tools that try to start each visible activity.
  
  * Stop the instrumentation before the cleaning phase in your testing process. Any adb command that uninstalls/disables/kills the package, will terminate the 
  instrumentation process. In that case there will be no results.


###### Applications package name and version list:

com.drodin.tuxrider-v1.0.9
org.pyneo.maps-v1.0.10
seanfoy.wherering-v1.99.0
com.color.colornamer-v2.32
org.androidsoft.games.memory.tux-v1.3.1
fr.seeks-v1.2
com.alexkang.loopboard-v2.3
com.sweetiepiggy.everylocale-v1.0.8
org.vudroid-v1.4
org.scoutant.cc-v0.9
com.shurik.droidzebra-v1.5.1
jpf.android.diary-v1.0
bander.notepad-v1.06
se.tube42.drum.android-v0.2.2
com.zagayevskiy.pacman-v1.1
br.usp.ime.retrobreaker-v1.0.3
com.unwind.networkmonitor-v1.0
com.smorgasbork.hotdeath-v1.0.7
com.pjuu.droidotter-v0.3.1
fr.ubordeaux.math.paridroid-v2.7.5.1.3
com.ridgelineapps.resdicegame-v1.12
gg.mw.passera-v0.1.2
org.cry.otp-v1.5
com.yasfa.views-v3.0
buet.rafi.dictionary-v2.3
com.kai1973i-v1.04
me.hda.urlhda-v1.0
com.tum.yahtzee-v1.1
jp.ksksue.app.terminal-v1.1.7
com.chmod0.manpages-v1.51
edu.harvard.android.mmskeeper-v1.01
org.kaziprst.android.ndfilter-v1.2
fr.mobdev.goblim-v1.0
com.hobbyone.HashDroid-v3.1
org.tmurakam.presentationtimer-v1.2
uk.co.jarofgreen.JustADamnCompass-v1.1
info.staticfree.SuperGenPass-v3.0.0
com.pindroid-v3.1.0
org.tint-v1.1
org.androidsoft.games.memory.kids-v2.0.2
de.onyxbits.droidentify-v1.2
com.code.android.vibevault-v4.1
com.google.code.apps2org-v1.6.0
com.leocardz.multitouch.test-v2.2
org.diygenomics.pg-v1.0
in.ac.dtu.subtlenews-v1.0
com.zola.bmi-v3.0.0
com.dozingcatsoftware.asciicam-v1.1.5
com.ivanvolosyuk.sharetobrowser-v1.5
com.achep.acdisplay-v3.8.4
com.jeyries.quake2-v1.91
com.ebaschiera.triplecamel-v1.0.4
org.developfreedom.wordpowermadeeasy-v0.1.6
org.billthefarmer.melodeon-v1.05
fr.xtof54.scrabble-v1.2
org.olgsoft.apipepanic-v0.13
steele.gerry.dotty-v2
eu.domob.shopt-v1.0
me.anuraag.grader-v1.1
zame.GloomyDungeons.opensource.game-v2014.10.26.1200
org.billthefarmer.tuner-v1.08
com.flipcamera-v1.01
org.birthdayadapter-v1.17
com.alfray.timeriffic-v1.09.05
com.moonpi.swiftnotes-v3.1.3
se.tube42.kidsmem.android-v1.4
com.packetsender.android-v1.5
com.mattallen.loaned-v1.0.2
mobi.omegacentauri.PerApp-v1.02
ru.zxalexis.ugaday-v0.12
com.leinardi.kitchentimer-v1.1.6
ro.ui.pttdroid-v1.5.2
org.ndeftools.boilerplate-v1.3
fr.bellev.stdatmosphere-v1.0
cx.hell.android.pdfview-v0.4.0
me.tsukanov.counter-v16
ru.valle.btc-v2.5.0
net.sourceforge.opencamera-v1.27
aws.apps.usbDeviceEnumerator-v0.0.5
com.passcard-v1.0
ch.fixme.cowsay-v1.4
pl.nkg.geokrety-v0.7.5 beta
org.yabause.android-v0.9.11
com.zachrattner.pockettalk-v2.5
it.rgp.nyagua.pafcalc-v1.0
com.phikal.regex-v1.2
sony.hidden.servicemenu-v1.1
se.traffar.dot_race-v0.4
net.pejici.easydice-v1.8.0
starcom.snd-v1.0
com.gladis.tictactoe-v1.0
name.livitski.games.puzzle.android-v1.1
com.gabm.fancyplaces-v1.2.3
org.beide.droidgain-v1.0
org.yuttadhammo.BodhiTimer-v4.1.3
com.naman14.stools-v3.2
com.xenris.liquidwarsos-v1.42
com.kpz.pomodorotasks.activity-v1.5
ch.blinkenlights.battery-v1.81
eu.veldsoft.politrics-v1.0
