
+++
title = "Building Mobile Nebula"
date = 2021-01-30T00:00:00.000Z
template = "html_content/raw.html"
summary = """
This post is going to be cheating a bit. I want to start working on adding DNS
resolver configuratio..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/01/30/building-mobile-nebula.html"
raw = """
<p>This post is going to be cheating a bit. I want to start working on adding DNS
resolver configuration to the <a href="https://github.com/DefinedNet/mobile_nebula">mobile nebula</a> app (if you don’t
know nebula, <a href="https://slack.engineering/introducing-nebula-the-open-source-global-overlay-network-from-slack/">check it out</a>, it’s well worth knowing about), but I also
need to write a blog post for this week, so I’m combining the two exercises.
This post will essentially be my notes from my progress on today’s task.</p>

<p>(Protip: listen to <a href="https://youtu.be/SMJ7pxqk5d4?t=220">this</a> while following along to achieve the proper
open-source programming aesthetic.)</p>

<p>The current mobile nebula app works very well, but it is lacking one major
feature: the ability to specify custom DNS resolvers. This is important because
I want to be able to access resources on my nebula network by their hostname,
not their IP. Android does everything in its power to make DNS configuration
impossible, and essentially the only way to actually accomplish this is by
specifying the DNS resolvers within the app. I go into more details about why
Android is broken <a href="https://github.com/DefinedNet/mobile_nebula/issues/9">here</a>.</p>

<h2 id="setup">Setup</h2>

<p>Before I can make changes to the app I need to make sure I can correctly build
it in the first place, so that’s the major task for today. The first step to
doing so is to install the project’s dependencies. As described in the
<a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> README, the dependencies are:</p>

<ul>
  <li><a href="https://flutter.dev/docs/get-started/install"><code class="language-plaintext highlighter-rouge">flutter</code></a></li>
  <li><a href="https://godoc.org/golang.org/x/mobile/cmd/gomobile"><code class="language-plaintext highlighter-rouge">gomobile</code></a></li>
  <li><a href="https://developer.android.com/studio"><code class="language-plaintext highlighter-rouge">android-studio</code></a></li>
  <li><a href="https://developer.android.com/studio/projects/install-ndk">Enable NDK</a></li>
</ul>

<p>It should be noted that as of writing I haven’t used any of these tools ever,
and have only done a small amount of android programming, probably 7 or 8 years
ago, so I’m going to have to walk the line between figuring out problems on the
fly and not having to completely learning these entire ecosystems; there’s only
so many hours in a weekend, after all.</p>

<p>I’m running <a href="https://archlinux.org/">Archlinux</a> so I install android-studio and flutter by
doing:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-Sy</span> android-studio flutter
</code></pre></div></div>

<p>And I install <code class="language-plaintext highlighter-rouge">gomobile</code>, according to its <a href="https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile">documentation</a> via:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>go get golang.org/x/mobile/cmd/gomobile
gomobile init
</code></pre></div></div>

<p>Now I startup android-studio and go through the setup wizard for it. I choose
standard setup because customized setup doesn’t actually offer any interesting
options. Next android-studio spends approximately two lifetimes downloading
dependencies while my eyesight goes blurry because I’m drinking my coffee too
fast.</p>

<p>It’s annoying that I need to install these dependencies, especially
android-studio, in order to build this project. A future goal of mine is to nix
this whole thing up, and make a build pipeline where you can provide a full
nebula configuration file and it outputs a custom APK file for that specific
config; zero configuration required at runtime. This will be useful for
lazy/non-technical users who want to be part of the nebula network.</p>

<p>Once android-studio starts up I’m not quite done yet: there’s still the NDK
which must be enabled. The instructions given by the link in
<a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a>’s README explain doing this pretty well, but it’s
important to install the specific version indicated in the mobile_nebula repo
(<code class="language-plaintext highlighter-rouge">21.0.6113669</code> at time of writing). Only another 1GB of dependency downloading
to go….</p>

<p>While waiting for the NDK to download I run <code class="language-plaintext highlighter-rouge">flutter doctor</code> to make sure
flutter is working, and it gives me some permissions errors. <a href="https://www.rockyourcode.com/how-to-get-flutter-and-android-working-on-arch-linux/">This blog
post</a> gives some tips on setting up, and after running the
following…</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">sudo </span>groupadd flutterusers
<span class="nb">sudo </span>gpasswd <span class="nt">-a</span> <span class="nv">$USER</span> flutterusers
<span class="nb">sudo chown</span> <span class="nt">-R</span> :flutterusers /opt/flutter
<span class="nb">sudo chmod</span> <span class="nt">-R</span> g+w /opt/flutter/
newgrp flutterusers
</code></pre></div></div>

<p>… I’m able to run <code class="language-plaintext highlighter-rouge">flutter doctor</code>. It gives the following output:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>[✓] Flutter (Channel stable, 1.22.6, on Linux, locale en_US.UTF-8)
 
[!] Android toolchain - develop for Android devices (Android SDK version 30.0.3)
    ✗ Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses
[!] Android Studio
    ✗ Flutter plugin not installed; this adds Flutter specific functionality.
    ✗ Dart plugin not installed; this adds Dart specific functionality.
[!] Connected device
    ! No devices available

! Doctor found issues in 3 categories.
</code></pre></div></div>

<p>The first issue is easily solved as per the instructions given. The second is
solved by finding the plugin manager in android-studio and installing the
flutter plugin (which installs the dart plugin as a dependency, we call that a
twofer).</p>

<p>After installing the plugin the doctor command still complains about not finding
the plugins, but the above mentioned blog post indicates to me that this is
expected. It’s comforting to know that the problems indicated by the doctor may
or may not be real problems.</p>

<p>The <a href="https://www.rockyourcode.com/how-to-get-flutter-and-android-working-on-arch-linux/">blog post</a> also indicates that I need <code class="language-plaintext highlighter-rouge">openjdk-8</code> installed,
so I do:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-S</span> jdk8-openjdk
</code></pre></div></div>

<p>And use the <code class="language-plaintext highlighter-rouge">archlinux-java</code> command to confirm that that is indeed the default
version for my shell. The <a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> helpfully expects an
<code class="language-plaintext highlighter-rouge">env.sh</code> file to exist in the root, so if openjdk-8 wasn’t already the default I
could make it so within that file.</p>

<h2 id="build">Build</h2>

<p>At this point I think I’m ready to try actually building an APK. Thoughts and
prayers required. I run the following in a terminal, since for some reason the
<code class="language-plaintext highlighter-rouge">Build &gt; Flutter &gt; Build APK</code> dropdown button in android-studio did nothing.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk
</code></pre></div></div>

<p>It takes quite a while to run, but in the end it errors with:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make: 'mobileNebula.aar' is up to date.
cp: cannot create regular file '../android/app/src/main/libs/mobileNebula.aar': No such file or directory

FAILURE: Build failed with an exception.

* Where:
Build file '/tmp/src/mobile_nebula/android/app/build.gradle' line: 95

* What went wrong:
A problem occurred evaluating project ':app'.
&gt; Process 'command './gen-artifacts.sh'' finished with non-zero exit value 1

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 1s
Running Gradle task 'bundleRelease'...
Running Gradle task 'bundleRelease'... Done                         1.7s
Gradle task bundleRelease failed with exit code 1
</code></pre></div></div>

<p>I narrow down the problem to the <code class="language-plaintext highlighter-rouge">./gen-artifacts.sh</code> script in the repo’s root,
which takes in either <code class="language-plaintext highlighter-rouge">android</code> or <code class="language-plaintext highlighter-rouge">ios</code> as an argument. Running it directly
as <code class="language-plaintext highlighter-rouge">./gen-artifacts.sh android</code> results in the same error:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make: <span class="s1">'mobileNebula.aar'</span> is up to date.
<span class="nb">cp</span>: cannot create regular file <span class="s1">'../android/app/src/main/libs/mobileNebula.aar'</span>: No such file or directory
</code></pre></div></div>

<p>So now I gotta figure out wtf that <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> file is. The first thing I
note is that not only is that file not there, but the <code class="language-plaintext highlighter-rouge">libs</code> directory it’s
supposed to be present in is also not there. So I suspect that there’s a missing
build step somewhere.</p>

<p>I search for the string <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> within the project using
<a href="https://github.com/ggreer/the_silver_searcher">ag</a> and find that it’s built by <code class="language-plaintext highlighter-rouge">nebula/Makefile</code> as follows:</p>

<div class="language-make highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nl">mobileNebula.aar</span><span class="o">:</span> <span class="nf">*.go</span>
\tgomobile <span class="nb">bind</span> <span class="nt">-trimpath</span> <span class="nt">-v</span> <span class="nt">--target</span><span class="o">=</span>android
</code></pre></div></div>

<p>So that file is made by <code class="language-plaintext highlighter-rouge">gomobile</code>, good to know! Additionally the file is
actually there in the <code class="language-plaintext highlighter-rouge">nebula</code> directory, so I suspect there’s just a missing
build step to move it into <code class="language-plaintext highlighter-rouge">android/app/src/main/libs</code>. Via some more <code class="language-plaintext highlighter-rouge">ag</code>-ing I
find that the code which is supposed to move the <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> file is in
the <code class="language-plaintext highlighter-rouge">gen-artifacts.sh</code> script, but that script doesn’t create the <code class="language-plaintext highlighter-rouge">libs</code> folder
as it ought to. I apply the following diff:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>diff <span class="nt">--git</span> a/gen-artifacts.sh b/gen-artifacts.sh
index 601ed7b..4f73b4c 100755
<span class="nt">---</span> a/gen-artifacts.sh
\u002B\u002B\u002B b/gen-artifacts.sh
@@ <span class="nt">-16</span>,7 +16,7 @@ <span class="k">if</span> <span class="o">[</span> <span class="s2">"</span><span class="nv">$1</span><span class="s2">"</span> <span class="o">=</span> <span class="s2">"ios"</span> <span class="o">]</span><span class="p">;</span> <span class="k">then
 elif</span> <span class="o">[</span> <span class="s2">"</span><span class="nv">$1</span><span class="s2">"</span> <span class="o">=</span> <span class="s2">"android"</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span>
   <span class="c"># Build nebula for android</span>
   make mobileNebula.aar
-  <span class="nb">rm</span> <span class="nt">-rf</span> ../android/app/src/main/libs/mobileNebula.aar
+  <span class="nb">mkdir</span> <span class="nt">-p</span> ../android/app/src/main/libs
   <span class="nb">cp </span>mobileNebula.aar ../android/app/src/main/libs/mobileNebula.aar

 <span class="k">else</span>
</code></pre></div></div>

<p>(The <code class="language-plaintext highlighter-rouge">rm -rf</code> isn’t necessary, since a) that file is about to be overwritten by
the subsequent <code class="language-plaintext highlighter-rouge">cp</code> whether or not it’s there, and b) it’s just deleting a
single file so the <code class="language-plaintext highlighter-rouge">-rf</code> is an unnecessary risk).</p>

<p>At this point I re-run <code class="language-plaintext highlighter-rouge">flutter build apk</code> and receive a new error. Progress!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>A problem occurred evaluating root project 'android'.
&gt; A problem occurred configuring project ':app'.
   &gt; Removing unused resources requires unused code shrinking to be turned on. See http://d.android.com/r/tools/shrink-resources.html for more information.
</code></pre></div></div>

<p>I recall that in the original <a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> README it mentions
to run the <code class="language-plaintext highlighter-rouge">flutter build</code> command with the <code class="language-plaintext highlighter-rouge">--no-shrink</code> option, so I try:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk <span class="nt">--no-shrink</span>
</code></pre></div></div>

<p>Finally we really get somewhere. The command takes a very long time to run as it
downloads yet more dependencies (mostly android SDK stuff from the looks of it),
but unfortunately still errors out:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Execution failed for task ':app:processReleaseResources'.
&gt; Could not resolve all files for configuration ':app:releaseRuntimeClasspath'.
   &gt; Failed to transform mobileNebula-.aar (:mobileNebula:) to match attributes {artifactType=android-compiled-dependencies-resources, org.gradle.status=integration}.
      &gt; Execution failed for AarResourcesCompilerTransform: /home/mediocregopher/.gradle/caches/transforms-2/files-2.1/735fc805916d942f5311063c106e7363/jetified-mobileNebula.
         &gt; /home/mediocregopher/.gradle/caches/transforms-2/files-2.1/735fc805916d942f5311063c106e7363/jetified-mobileNebula/AndroidManifest.xml
</code></pre></div></div>

<p>Time for more <code class="language-plaintext highlighter-rouge">ag</code>-ing. I find the file <code class="language-plaintext highlighter-rouge">android/app/build.gradle</code>, which has
the following block:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>    implementation (name:'mobileNebula', ext:'aar') {
        exec {
            workingDir '../../'
            environment("ANDROID_NDK_HOME", android.ndkDirectory)
            environment("ANDROID_HOME", android.sdkDirectory)
            commandLine './gen-artifacts.sh', 'android'
        }
    }
</code></pre></div></div>

<p>I never set up the <code class="language-plaintext highlighter-rouge">ANDROID_HOME</code> or <code class="language-plaintext highlighter-rouge">ANDROID_NDK_HOME</code> environment variables,
and I suppose that if I’m running the flutter command outside of android-studio
there wouldn’t be a way for flutter to know those values, so I try setting them
within my <code class="language-plaintext highlighter-rouge">env.sh</code>:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">export </span><span class="nv">ANDROID_HOME</span><span class="o">=</span>~/Android/Sdk
<span class="nb">export </span><span class="nv">ANDROID_NDK_HOME</span><span class="o">=</span>~/Android/Sdk/ndk/21.0.6113669
</code></pre></div></div>

<p>Re-running the build command still results in the same error. But it occurs to
me that I probably had built the <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> without those set
previously, so maybe it was built with the wrong NDK version or something. I
tried deleting <code class="language-plaintext highlighter-rouge">nebula/mobileNebula.aar</code> and try building again. This time…
new errors! Lots of them! Big ones and small ones!</p>

<p>At this point I’m a bit fed up, and want to try a completely fresh build. I back
up my modified <code class="language-plaintext highlighter-rouge">env.sh</code> and <code class="language-plaintext highlighter-rouge">gen-artifacts.sh</code> files, delete the <code class="language-plaintext highlighter-rouge">mobile_nebula</code>
repo, re-clone it, reinstall those files, and try building again. This time just
a single error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Execution failed for task ':app:lintVitalRelease'.
&gt; Could not resolve all artifacts for configuration ':app:debugRuntimeClasspath'.
   &gt; Failed to transform libs.jar to match attributes {artifactType=processed-jar, org.gradle.libraryelements=jar, org.gradle.usage=java-runtime}.
      &gt; Execution failed for JetifyTransform: /tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar.
         &gt; Failed to transform '/tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar' using Jetifier. Reason: FileNotFoundException, message: /tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar (No such file or directory). (Run with --stacktrace for more details.)
           Please file a bug at http://issuetracker.google.com/issues/new?component=460323.
</code></pre></div></div>

<p>So that’s cool, apparently there’s a bug with flutter and I should file a
support ticket? Well, probably not. It seems that while
<code class="language-plaintext highlighter-rouge">build/app/intermediates/flutter/debug/libs.jar</code> indeed doesn’t exist in the
repo, <code class="language-plaintext highlighter-rouge">build/app/intermediates/flutter/release/libs.jar</code> <em>does</em>, so this appears
to possibly be an issue in declaring which build environment is being used.</p>

<p>After some googling I found <a href="https://github.com/flutter/flutter/issues/58247">this flutter issue</a> related to the
error. Tldr: gradle’s not playing nicely with flutter. Downgrading could help,
but apparently building with the <code class="language-plaintext highlighter-rouge">--debug</code> flag also works. I don’t want to
build a release version anyway, so this sits fine with me. I run…</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk <span class="nt">--no-shrink</span> <span class="nt">--debug</span>
</code></pre></div></div>

<p>And would you look at that, I got a result!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>✓ Built build/app/outputs/flutter-apk/app-debug.apk.
</code></pre></div></div>

<h2 id="install">Install</h2>

<p>Building was probably the hard part, but I’m not totally out of the woods yet.
Theoretically I could email this apk to my phone or something, but I’d like
something with a faster turnover time; I need <code class="language-plaintext highlighter-rouge">adb</code>.</p>

<p>I install <code class="language-plaintext highlighter-rouge">adb</code> via the <code class="language-plaintext highlighter-rouge">android-tools</code> package:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-S</span> android-tools
</code></pre></div></div>

<p>Before <code class="language-plaintext highlighter-rouge">adb</code> will work, however, I need to turn on USB debugging on my phone,
which I do by following <a href="https://www.droidviews.com/how-to-enable-developer-optionsusb-debugging-mode-on-devices-with-android-4-2-jelly-bean/">this article</a>. Once connected I confirm
that <code class="language-plaintext highlighter-rouge">adb</code> can talk to my phone by doing:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb devices
</code></pre></div></div>

<p>And then, finally, I can install the apk:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb install build/app/outputs/flutter-apk/app-debug.apk
</code></pre></div></div>

<p>NOT SO FAST! MORE ERRORS!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb: failed to install build/app/outputs/flutter-apk/app-debug.apk: Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Package net.defined.mobile_nebula signatures do not match previously installed version; ignoring!]
</code></pre></div></div>

<p>I’m guessing this is because I already have the real nebula app installed. I
uninstall it and try again.</p>

<p>AND IT WORKS!!! FUCK YEAH!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Performing Streamed Install
Success
</code></pre></div></div>

<p>I can open the nebula app on my phone and it works… fine. There’s some
pre-existing networks already installed, which isn’t the case for the Play Store
version as far as I can remember, so I suspect those are only there in the
debugging build. Unfortunately the presence of these test networks causes the
app the throw a bunch of errors because it can’t contact those networks. Oh well.</p>

<p>The presence of those test networks, in a way, is actually a good thing, as it
means there’s probably already a starting point for what I want to do: building
a per-device nebula app with a config preloaded into it.</p>

<h2 id="further-steps">Further Steps</h2>

<p>Beyond continuing on towards my actual goal of adding DNS resolvers to this app,
there’s a couple of other paths I could potentially go down at this point.</p>

<ul>
  <li>
    <p>As mentioned, nixify the whole thing. I’m 99% sure the android-studio GUI
isn’t actually needed at all, and I only used it for installing the CMake and
NDK plugins because I didn’t bother to look up how to do it on the CLI.</p>
  </li>
  <li>
    <p>Figuring out how to do a proper release build would be great, just for my own
education. Based on the <a href="https://github.com/flutter/flutter/issues/58247">flutter issue</a> it’s possible that all
that’s needed is to downgrade gradle, but maybe that’s not so easy.</p>
  </li>
  <li>
    <p>Get an android emulator working so that I don’t have to install to my phone
everytime I want to test the app out. I’m not sure if that will also work for
the VPN aspect of the app, but it will at least help me iterate on UI changes
faster.</p>
  </li>
</ul>

<p>But at this point I’m done for the day, I’ll continue on this project some other
time.</p>"""

+++
<p>This post is going to be cheating a bit. I want to start working on adding DNS
resolver configuration to the <a href="https://github.com/DefinedNet/mobile_nebula">mobile nebula</a> app (if you don’t
know nebula, <a href="https://slack.engineering/introducing-nebula-the-open-source-global-overlay-network-from-slack/">check it out</a>, it’s well worth knowing about), but I also
need to write a blog post for this week, so I’m combining the two exercises.
This post will essentially be my notes from my progress on today’s task.</p>

<p>(Protip: listen to <a href="https://youtu.be/SMJ7pxqk5d4?t=220">this</a> while following along to achieve the proper
open-source programming aesthetic.)</p>

<p>The current mobile nebula app works very well, but it is lacking one major
feature: the ability to specify custom DNS resolvers. This is important because
I want to be able to access resources on my nebula network by their hostname,
not their IP. Android does everything in its power to make DNS configuration
impossible, and essentially the only way to actually accomplish this is by
specifying the DNS resolvers within the app. I go into more details about why
Android is broken <a href="https://github.com/DefinedNet/mobile_nebula/issues/9">here</a>.</p>

<h2 id="setup">Setup</h2>

<p>Before I can make changes to the app I need to make sure I can correctly build
it in the first place, so that’s the major task for today. The first step to
doing so is to install the project’s dependencies. As described in the
<a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> README, the dependencies are:</p>

<ul>
  <li><a href="https://flutter.dev/docs/get-started/install"><code class="language-plaintext highlighter-rouge">flutter</code></a></li>
  <li><a href="https://godoc.org/golang.org/x/mobile/cmd/gomobile"><code class="language-plaintext highlighter-rouge">gomobile</code></a></li>
  <li><a href="https://developer.android.com/studio"><code class="language-plaintext highlighter-rouge">android-studio</code></a></li>
  <li><a href="https://developer.android.com/studio/projects/install-ndk">Enable NDK</a></li>
</ul>

<p>It should be noted that as of writing I haven’t used any of these tools ever,
and have only done a small amount of android programming, probably 7 or 8 years
ago, so I’m going to have to walk the line between figuring out problems on the
fly and not having to completely learning these entire ecosystems; there’s only
so many hours in a weekend, after all.</p>

<p>I’m running <a href="https://archlinux.org/">Archlinux</a> so I install android-studio and flutter by
doing:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-Sy</span> android-studio flutter
</code></pre></div></div>

<p>And I install <code class="language-plaintext highlighter-rouge">gomobile</code>, according to its <a href="https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile">documentation</a> via:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>go get golang.org/x/mobile/cmd/gomobile
gomobile init
</code></pre></div></div>

<p>Now I startup android-studio and go through the setup wizard for it. I choose
standard setup because customized setup doesn’t actually offer any interesting
options. Next android-studio spends approximately two lifetimes downloading
dependencies while my eyesight goes blurry because I’m drinking my coffee too
fast.</p>

<p>It’s annoying that I need to install these dependencies, especially
android-studio, in order to build this project. A future goal of mine is to nix
this whole thing up, and make a build pipeline where you can provide a full
nebula configuration file and it outputs a custom APK file for that specific
config; zero configuration required at runtime. This will be useful for
lazy/non-technical users who want to be part of the nebula network.</p>

<p>Once android-studio starts up I’m not quite done yet: there’s still the NDK
which must be enabled. The instructions given by the link in
<a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a>’s README explain doing this pretty well, but it’s
important to install the specific version indicated in the mobile_nebula repo
(<code class="language-plaintext highlighter-rouge">21.0.6113669</code> at time of writing). Only another 1GB of dependency downloading
to go….</p>

<p>While waiting for the NDK to download I run <code class="language-plaintext highlighter-rouge">flutter doctor</code> to make sure
flutter is working, and it gives me some permissions errors. <a href="https://www.rockyourcode.com/how-to-get-flutter-and-android-working-on-arch-linux/">This blog
post</a> gives some tips on setting up, and after running the
following…</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">sudo </span>groupadd flutterusers
<span class="nb">sudo </span>gpasswd <span class="nt">-a</span> <span class="nv">$USER</span> flutterusers
<span class="nb">sudo chown</span> <span class="nt">-R</span> :flutterusers /opt/flutter
<span class="nb">sudo chmod</span> <span class="nt">-R</span> g+w /opt/flutter/
newgrp flutterusers
</code></pre></div></div>

<p>… I’m able to run <code class="language-plaintext highlighter-rouge">flutter doctor</code>. It gives the following output:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>[✓] Flutter (Channel stable, 1.22.6, on Linux, locale en_US.UTF-8)
 
[!] Android toolchain - develop for Android devices (Android SDK version 30.0.3)
    ✗ Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses
[!] Android Studio
    ✗ Flutter plugin not installed; this adds Flutter specific functionality.
    ✗ Dart plugin not installed; this adds Dart specific functionality.
[!] Connected device
    ! No devices available

! Doctor found issues in 3 categories.
</code></pre></div></div>

<p>The first issue is easily solved as per the instructions given. The second is
solved by finding the plugin manager in android-studio and installing the
flutter plugin (which installs the dart plugin as a dependency, we call that a
twofer).</p>

<p>After installing the plugin the doctor command still complains about not finding
the plugins, but the above mentioned blog post indicates to me that this is
expected. It’s comforting to know that the problems indicated by the doctor may
or may not be real problems.</p>

<p>The <a href="https://www.rockyourcode.com/how-to-get-flutter-and-android-working-on-arch-linux/">blog post</a> also indicates that I need <code class="language-plaintext highlighter-rouge">openjdk-8</code> installed,
so I do:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-S</span> jdk8-openjdk
</code></pre></div></div>

<p>And use the <code class="language-plaintext highlighter-rouge">archlinux-java</code> command to confirm that that is indeed the default
version for my shell. The <a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> helpfully expects an
<code class="language-plaintext highlighter-rouge">env.sh</code> file to exist in the root, so if openjdk-8 wasn’t already the default I
could make it so within that file.</p>

<h2 id="build">Build</h2>

<p>At this point I think I’m ready to try actually building an APK. Thoughts and
prayers required. I run the following in a terminal, since for some reason the
<code class="language-plaintext highlighter-rouge">Build &gt; Flutter &gt; Build APK</code> dropdown button in android-studio did nothing.</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk
</code></pre></div></div>

<p>It takes quite a while to run, but in the end it errors with:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make: 'mobileNebula.aar' is up to date.
cp: cannot create regular file '../android/app/src/main/libs/mobileNebula.aar': No such file or directory

FAILURE: Build failed with an exception.

* Where:
Build file '/tmp/src/mobile_nebula/android/app/build.gradle' line: 95

* What went wrong:
A problem occurred evaluating project ':app'.
&gt; Process 'command './gen-artifacts.sh'' finished with non-zero exit value 1

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 1s
Running Gradle task 'bundleRelease'...
Running Gradle task 'bundleRelease'... Done                         1.7s
Gradle task bundleRelease failed with exit code 1
</code></pre></div></div>

<p>I narrow down the problem to the <code class="language-plaintext highlighter-rouge">./gen-artifacts.sh</code> script in the repo’s root,
which takes in either <code class="language-plaintext highlighter-rouge">android</code> or <code class="language-plaintext highlighter-rouge">ios</code> as an argument. Running it directly
as <code class="language-plaintext highlighter-rouge">./gen-artifacts.sh android</code> results in the same error:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>make: <span class="s1">'mobileNebula.aar'</span> is up to date.
<span class="nb">cp</span>: cannot create regular file <span class="s1">'../android/app/src/main/libs/mobileNebula.aar'</span>: No such file or directory
</code></pre></div></div>

<p>So now I gotta figure out wtf that <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> file is. The first thing I
note is that not only is that file not there, but the <code class="language-plaintext highlighter-rouge">libs</code> directory it’s
supposed to be present in is also not there. So I suspect that there’s a missing
build step somewhere.</p>

<p>I search for the string <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> within the project using
<a href="https://github.com/ggreer/the_silver_searcher">ag</a> and find that it’s built by <code class="language-plaintext highlighter-rouge">nebula/Makefile</code> as follows:</p>

<div class="language-make highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nl">mobileNebula.aar</span><span class="o">:</span> <span class="nf">*.go</span>
	gomobile <span class="nb">bind</span> <span class="nt">-trimpath</span> <span class="nt">-v</span> <span class="nt">--target</span><span class="o">=</span>android
</code></pre></div></div>

<p>So that file is made by <code class="language-plaintext highlighter-rouge">gomobile</code>, good to know! Additionally the file is
actually there in the <code class="language-plaintext highlighter-rouge">nebula</code> directory, so I suspect there’s just a missing
build step to move it into <code class="language-plaintext highlighter-rouge">android/app/src/main/libs</code>. Via some more <code class="language-plaintext highlighter-rouge">ag</code>-ing I
find that the code which is supposed to move the <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> file is in
the <code class="language-plaintext highlighter-rouge">gen-artifacts.sh</code> script, but that script doesn’t create the <code class="language-plaintext highlighter-rouge">libs</code> folder
as it ought to. I apply the following diff:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>diff <span class="nt">--git</span> a/gen-artifacts.sh b/gen-artifacts.sh
index 601ed7b..4f73b4c 100755
<span class="nt">---</span> a/gen-artifacts.sh
\u002B\u002B\u002B b/gen-artifacts.sh
@@ <span class="nt">-16</span>,7 +16,7 @@ <span class="k">if</span> <span class="o">[</span> <span class="s2">"</span><span class="nv">$1</span><span class="s2">"</span> <span class="o">=</span> <span class="s2">"ios"</span> <span class="o">]</span><span class="p">;</span> <span class="k">then
 elif</span> <span class="o">[</span> <span class="s2">"</span><span class="nv">$1</span><span class="s2">"</span> <span class="o">=</span> <span class="s2">"android"</span> <span class="o">]</span><span class="p">;</span> <span class="k">then</span>
   <span class="c"># Build nebula for android</span>
   make mobileNebula.aar
-  <span class="nb">rm</span> <span class="nt">-rf</span> ../android/app/src/main/libs/mobileNebula.aar
+  <span class="nb">mkdir</span> <span class="nt">-p</span> ../android/app/src/main/libs
   <span class="nb">cp </span>mobileNebula.aar ../android/app/src/main/libs/mobileNebula.aar

 <span class="k">else</span>
</code></pre></div></div>

<p>(The <code class="language-plaintext highlighter-rouge">rm -rf</code> isn’t necessary, since a) that file is about to be overwritten by
the subsequent <code class="language-plaintext highlighter-rouge">cp</code> whether or not it’s there, and b) it’s just deleting a
single file so the <code class="language-plaintext highlighter-rouge">-rf</code> is an unnecessary risk).</p>

<p>At this point I re-run <code class="language-plaintext highlighter-rouge">flutter build apk</code> and receive a new error. Progress!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>A problem occurred evaluating root project 'android'.
&gt; A problem occurred configuring project ':app'.
   &gt; Removing unused resources requires unused code shrinking to be turned on. See http://d.android.com/r/tools/shrink-resources.html for more information.
</code></pre></div></div>

<p>I recall that in the original <a href="https://github.com/DefinedNet/mobile_nebula">mobile_nebula</a> README it mentions
to run the <code class="language-plaintext highlighter-rouge">flutter build</code> command with the <code class="language-plaintext highlighter-rouge">--no-shrink</code> option, so I try:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk <span class="nt">--no-shrink</span>
</code></pre></div></div>

<p>Finally we really get somewhere. The command takes a very long time to run as it
downloads yet more dependencies (mostly android SDK stuff from the looks of it),
but unfortunately still errors out:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Execution failed for task ':app:processReleaseResources'.
&gt; Could not resolve all files for configuration ':app:releaseRuntimeClasspath'.
   &gt; Failed to transform mobileNebula-.aar (:mobileNebula:) to match attributes {artifactType=android-compiled-dependencies-resources, org.gradle.status=integration}.
      &gt; Execution failed for AarResourcesCompilerTransform: /home/mediocregopher/.gradle/caches/transforms-2/files-2.1/735fc805916d942f5311063c106e7363/jetified-mobileNebula.
         &gt; /home/mediocregopher/.gradle/caches/transforms-2/files-2.1/735fc805916d942f5311063c106e7363/jetified-mobileNebula/AndroidManifest.xml
</code></pre></div></div>

<p>Time for more <code class="language-plaintext highlighter-rouge">ag</code>-ing. I find the file <code class="language-plaintext highlighter-rouge">android/app/build.gradle</code>, which has
the following block:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>    implementation (name:'mobileNebula', ext:'aar') {
        exec {
            workingDir '../../'
            environment("ANDROID_NDK_HOME", android.ndkDirectory)
            environment("ANDROID_HOME", android.sdkDirectory)
            commandLine './gen-artifacts.sh', 'android'
        }
    }
</code></pre></div></div>

<p>I never set up the <code class="language-plaintext highlighter-rouge">ANDROID_HOME</code> or <code class="language-plaintext highlighter-rouge">ANDROID_NDK_HOME</code> environment variables,
and I suppose that if I’m running the flutter command outside of android-studio
there wouldn’t be a way for flutter to know those values, so I try setting them
within my <code class="language-plaintext highlighter-rouge">env.sh</code>:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">export </span><span class="nv">ANDROID_HOME</span><span class="o">=</span>~/Android/Sdk
<span class="nb">export </span><span class="nv">ANDROID_NDK_HOME</span><span class="o">=</span>~/Android/Sdk/ndk/21.0.6113669
</code></pre></div></div>

<p>Re-running the build command still results in the same error. But it occurs to
me that I probably had built the <code class="language-plaintext highlighter-rouge">mobileNebula.aar</code> without those set
previously, so maybe it was built with the wrong NDK version or something. I
tried deleting <code class="language-plaintext highlighter-rouge">nebula/mobileNebula.aar</code> and try building again. This time…
new errors! Lots of them! Big ones and small ones!</p>

<p>At this point I’m a bit fed up, and want to try a completely fresh build. I back
up my modified <code class="language-plaintext highlighter-rouge">env.sh</code> and <code class="language-plaintext highlighter-rouge">gen-artifacts.sh</code> files, delete the <code class="language-plaintext highlighter-rouge">mobile_nebula</code>
repo, re-clone it, reinstall those files, and try building again. This time just
a single error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Execution failed for task ':app:lintVitalRelease'.
&gt; Could not resolve all artifacts for configuration ':app:debugRuntimeClasspath'.
   &gt; Failed to transform libs.jar to match attributes {artifactType=processed-jar, org.gradle.libraryelements=jar, org.gradle.usage=java-runtime}.
      &gt; Execution failed for JetifyTransform: /tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar.
         &gt; Failed to transform '/tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar' using Jetifier. Reason: FileNotFoundException, message: /tmp/src/mobile_nebula/build/app/intermediates/flutter/debug/libs.jar (No such file or directory). (Run with --stacktrace for more details.)
           Please file a bug at http://issuetracker.google.com/issues/new?component=460323.
</code></pre></div></div>

<p>So that’s cool, apparently there’s a bug with flutter and I should file a
support ticket? Well, probably not. It seems that while
<code class="language-plaintext highlighter-rouge">build/app/intermediates/flutter/debug/libs.jar</code> indeed doesn’t exist in the
repo, <code class="language-plaintext highlighter-rouge">build/app/intermediates/flutter/release/libs.jar</code> <em>does</em>, so this appears
to possibly be an issue in declaring which build environment is being used.</p>

<p>After some googling I found <a href="https://github.com/flutter/flutter/issues/58247">this flutter issue</a> related to the
error. Tldr: gradle’s not playing nicely with flutter. Downgrading could help,
but apparently building with the <code class="language-plaintext highlighter-rouge">--debug</code> flag also works. I don’t want to
build a release version anyway, so this sits fine with me. I run…</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flutter build apk <span class="nt">--no-shrink</span> <span class="nt">--debug</span>
</code></pre></div></div>

<p>And would you look at that, I got a result!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>✓ Built build/app/outputs/flutter-apk/app-debug.apk.
</code></pre></div></div>

<h2 id="install">Install</h2>

<p>Building was probably the hard part, but I’m not totally out of the woods yet.
Theoretically I could email this apk to my phone or something, but I’d like
something with a faster turnover time; I need <code class="language-plaintext highlighter-rouge">adb</code>.</p>

<p>I install <code class="language-plaintext highlighter-rouge">adb</code> via the <code class="language-plaintext highlighter-rouge">android-tools</code> package:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>yay <span class="nt">-S</span> android-tools
</code></pre></div></div>

<p>Before <code class="language-plaintext highlighter-rouge">adb</code> will work, however, I need to turn on USB debugging on my phone,
which I do by following <a href="https://www.droidviews.com/how-to-enable-developer-optionsusb-debugging-mode-on-devices-with-android-4-2-jelly-bean/">this article</a>. Once connected I confirm
that <code class="language-plaintext highlighter-rouge">adb</code> can talk to my phone by doing:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb devices
</code></pre></div></div>

<p>And then, finally, I can install the apk:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb install build/app/outputs/flutter-apk/app-debug.apk
</code></pre></div></div>

<p>NOT SO FAST! MORE ERRORS!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>adb: failed to install build/app/outputs/flutter-apk/app-debug.apk: Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Package net.defined.mobile_nebula signatures do not match previously installed version; ignoring!]
</code></pre></div></div>

<p>I’m guessing this is because I already have the real nebula app installed. I
uninstall it and try again.</p>

<p>AND IT WORKS!!! FUCK YEAH!</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Performing Streamed Install
Success
</code></pre></div></div>

<p>I can open the nebula app on my phone and it works… fine. There’s some
pre-existing networks already installed, which isn’t the case for the Play Store
version as far as I can remember, so I suspect those are only there in the
debugging build. Unfortunately the presence of these test networks causes the
app the throw a bunch of errors because it can’t contact those networks. Oh well.</p>

<p>The presence of those test networks, in a way, is actually a good thing, as it
means there’s probably already a starting point for what I want to do: building
a per-device nebula app with a config preloaded into it.</p>

<h2 id="further-steps">Further Steps</h2>

<p>Beyond continuing on towards my actual goal of adding DNS resolvers to this app,
there’s a couple of other paths I could potentially go down at this point.</p>

<ul>
  <li>
    <p>As mentioned, nixify the whole thing. I’m 99% sure the android-studio GUI
isn’t actually needed at all, and I only used it for installing the CMake and
NDK plugins because I didn’t bother to look up how to do it on the CLI.</p>
  </li>
  <li>
    <p>Figuring out how to do a proper release build would be great, just for my own
education. Based on the <a href="https://github.com/flutter/flutter/issues/58247">flutter issue</a> it’s possible that all
that’s needed is to downgrade gradle, but maybe that’s not so easy.</p>
  </li>
  <li>
    <p>Get an android emulator working so that I don’t have to install to my phone
everytime I want to test the app out. I’m not sure if that will also work for
the VPN aspect of the app, but it will at least help me iterate on UI changes
faster.</p>
  </li>
</ul>

<p>But at this point I’m done for the day, I’ll continue on this project some other
time.</p>
