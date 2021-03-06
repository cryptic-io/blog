
+++
title = "Interacting with Go from React Native through JSI"
date = 2019-06-27T00:00:00.000Z
template = "html_content/raw.html"
summary = """
Introduction
There are 3 parts that let JS talk to Go:
The C++ binding
Installing the binding
Callin..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/go-rn-jsi/"
raw = """
<h1 id="introduction">Introduction</h1>
<p>There are 3 parts that let JS talk to Go:</p>
<ol>
<li>The C++ binding</li>
<li>Installing the binding</li>
<li>Calling Go</li>
</ol>
<p>Not all the code is shown, check out the <a href="https://github.com/MarcoPolo/react-native-hostobject-demo">source code</a> for specifics.</p>
<h3 id="part-1-the-c-binding">Part 1 - The C++ Binding</h3>
<p>The binding is the C++ glue code that will hook up your Go code to the JS runtime. The binding itself is composed of two main parts.</p>
<h4 id="part-1-1-the-c-binding">Part 1.1 - The C++ Binding</h4>
<p>The binding is a c++ class that implements the <code>jsi::HostObject</code> interface. At the very least it's useful for it to have a <code>get</code> method defined. The type of the <code>get</code> method is:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">jsi::Value </span><span style="color:#8fa1b3;">get</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">, </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::PropNameID &amp;</span><span style="color:#bf616a;">name</span><span style="color:#c0c5ce;">) </span><span style="color:#b48ead;">override</span><span style="color:#c0c5ce;">;
</span></code></pre>
<p>It returns a <code>jsi::Value</code> (a value that is safe for JS). It's given the JS runtime and the prop string used by JS when it <code>get</code>s the field. e.g. <code>global.nativeTest.foo</code> will call this method with PropNameID === <code>&quot;foo&quot;</code>.</p>
<h4 id="part-1-2-the-c-binding-s-install">Part 1.2 - The C++ Binding's install</h4>
<p>Now that we've defined our HostObject, we need to install it into the runtime. We use a static member function that we'll call later to set this up. It looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">void </span><span style="color:#c0c5ce;">TestBinding::</span><span style="color:#8fa1b3;">install</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">,
                          std::shared_ptr&lt;TestBinding&gt; </span><span style="color:#bf616a;">testBinding</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#65737e;">// What is the name that js will use when it reaches for this?
  // i.e. `global.nativeTest` in JS
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> testModuleName = &quot;</span><span style="color:#a3be8c;">nativeTest</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#65737e;">// Create a JS object version of our binding
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> object = jsi::Object::</span><span style="color:#bf616a;">createFromHostObject</span><span style="color:#c0c5ce;">(runtime, testBinding);
  </span><span style="color:#65737e;">// set the &quot;nativeTest&quot; propert
</span><span style="color:#c0c5ce;">  runtime.</span><span style="color:#bf616a;">global</span><span style="color:#c0c5ce;">().</span><span style="color:#bf616a;">setProperty</span><span style="color:#c0c5ce;">(runtime, testModuleName, std::</span><span style="color:#bf616a;">move</span><span style="color:#c0c5ce;">(object));
}
</span></code></pre><h3 id="part-2-installing-the-binding-on-android">Part 2. Installing the binding (on Android)</h3>
<p>Since we have a reference to the runtime in Java land, we'll have to create a JNI method to pass the runtime ptr to the native C++ land. We can add this JNI method to our TestBinding file with a guard.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">#if</span><span style="color:#c0c5ce;"> ANDROID
</span><span style="color:#b48ead;">extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; {
JNIEXPORT </span><span style="color:#b48ead;">void</span><span style="color:#c0c5ce;"> JNICALL </span><span style="color:#8fa1b3;">Java_com_testmodule_MainActivity_install</span><span style="color:#c0c5ce;">(
    JNIEnv *</span><span style="color:#bf616a;">env</span><span style="color:#c0c5ce;">, jobject </span><span style="color:#bf616a;">thiz</span><span style="color:#c0c5ce;">, jlong </span><span style="color:#bf616a;">runtimePtr</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> testBinding = std::</span><span style="color:#bf616a;">make_shared</span><span style="color:#c0c5ce;">&lt;example::TestBinding&gt;();
  jsi::Runtime *runtime = (jsi::Runtime *)runtimePtr;

  example::TestBinding::</span><span style="color:#bf616a;">install</span><span style="color:#c0c5ce;">(*runtime, testBinding);
}
}
</span><span style="color:#b48ead;">#endif
</span></code></pre>
<p>Then on the Java side (after we compile this into a shared library), we register this native function and call it when we're ready.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// In MainActivity

</span><span style="color:#b48ead;">public class </span><span style="color:#ebcb8b;">MainActivity </span><span style="color:#b48ead;">extends </span><span style="color:#a3be8c;">ReactActivity </span><span style="color:#b48ead;">implements </span><span style="color:#a3be8c;">ReactInstanceManager</span><span style="color:#eff1f5;">.</span><span style="color:#a3be8c;">ReactInstanceEventListener </span><span style="color:#eff1f5;">{
    </span><span style="color:#b48ead;">static </span><span style="color:#eff1f5;">{
        </span><span style="color:#65737e;">// Load our jni
        </span><span style="color:#ebcb8b;">System</span><span style="color:#eff1f5;">.</span><span style="color:#bf616a;">loadLibrary</span><span style="color:#eff1f5;">(</span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">test_module_jni</span><span style="color:#c0c5ce;">&quot;</span><span style="color:#eff1f5;">);
    }

    </span><span style="color:#65737e;">//... ellided ...

    </span><span style="color:#eff1f5;">@</span><span style="color:#bf616a;">Override
    </span><span style="color:#b48ead;">public void </span><span style="color:#8fa1b3;">onReactContextInitialized</span><span style="color:#eff1f5;">(</span><span style="color:#ebcb8b;">ReactContext </span><span style="color:#bf616a;">context</span><span style="color:#eff1f5;">) {
        </span><span style="color:#65737e;">// Call our native function with the runtime pointer
        </span><span style="color:#bf616a;">install</span><span style="color:#eff1f5;">(context.</span><span style="color:#bf616a;">getJavaScriptContextHolder</span><span style="color:#eff1f5;">().</span><span style="color:#bf616a;">get</span><span style="color:#eff1f5;">());
    }

    </span><span style="color:#65737e;">//  declare our native function
    </span><span style="color:#b48ead;">public native void </span><span style="color:#8fa1b3;">install</span><span style="color:#eff1f5;">(</span><span style="color:#b48ead;">long </span><span style="color:#bf616a;">jsContextNativePointer</span><span style="color:#eff1f5;">);
}
</span></code></pre><h3 id="part-3-calling-go">Part 3. Calling Go</h3>
<p>Now that our binding is installed in the runtime, we can make it do something useful.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">jsi::Value TestBinding::</span><span style="color:#8fa1b3;">get</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">,
                            </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::PropNameID &amp;</span><span style="color:#bf616a;">name</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> methodName = name.</span><span style="color:#bf616a;">utf8</span><span style="color:#c0c5ce;">(runtime);

  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(methodName == &quot;</span><span style="color:#a3be8c;">runTest</span><span style="color:#c0c5ce;">&quot;) {
    </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">jsi::Function::</span><span style="color:#bf616a;">createFromHostFunction</span><span style="color:#c0c5ce;">(
        runtime, name, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">,
        [](jsi::Runtime &amp;runtime, </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::Value &amp;thisValue,
           </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::Value *arguments,
           size_t count) -&gt; </span><span style="color:#bf616a;">jsi</span><span style="color:#c0c5ce;">::</span><span style="color:#bf616a;">Value </span><span style="color:#c0c5ce;">{ </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">TestNum</span><span style="color:#c0c5ce;">(); });
  }
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">jsi::Value::</span><span style="color:#bf616a;">undefined</span><span style="color:#c0c5ce;">();
}

</span></code></pre>
<p>Here we return a <code>jsi::Function</code> when JS calls <code>global.nativeTest.runTest</code>. When JS calls it (as in <code>global.nativeTest.runTest()</code>) we execute the code inside the closure, which just returns <code>TestNum()</code>. TestNum is a Go function that's exported through cgo so that it is available to c/c++. Our Go code looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">package </span><span style="color:#bf616a;">main

</span><span style="color:#b48ead;">import </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot;

</span><span style="color:#65737e;">// TestNum returns a test number to be used in JSI
//export TestNum
</span><span style="color:#b48ead;">func </span><span style="color:#8fa1b3;">TestNum</span><span style="color:#c0c5ce;">() </span><span style="color:#b48ead;">int </span><span style="color:#c0c5ce;">{
\t</span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">int</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">9001</span><span style="color:#c0c5ce;">)
}
</span><span style="color:#b48ead;">func </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
}
</span></code></pre>
<p>cgo builds a header and creates a shared library that is used by our binding.</p>
<h3 id="building">Building</h3>
<ul>
<li>Look at the CMakeLists.txt for specifics on building the C++ code.</li>
<li>Look at from-go/build.sh for specifics on building the go code.</li>
</ul>
<h3 id="a-go-shared-library-for-c-java">A Go Shared Library for C + Java</h3>
<p>It's possible to build the Go code as a shared library for both C and Java, but you'll have to define your own JNI methods. It would be nice if gomobile bind also generated C headers for android, but it doesn't seem possible right now. Instead you'll have to run <code>go build -buildmode=c-shared</code> directly and define your jni methods yourself. Take a look at <code>from-go/build.sh</code> and testnum.go for specifics.</p>
<h2 id="further-reading">Further Reading</h2>
<p><a href="https://medium.com/@christian.falch/https-medium-com-christian-falch-react-native-jsi-challenge-1201a69c8fbf">JSI Challenge #1</a></p>
<p><a href="https://medium.com/@christian.falch/react-native-jsi-challenge-2-56fc4dd91613">JSI Challenge #2</a></p>
<p><a href="http://blog.nparashuram.com/2019/01/react-natives-new-architecture-glossary.html">RN Glossary of Terms</a></p>
<p><a href="https://blog.dogan.io/2015/08/15/java-jni-jnr-go/">GO JNI</a></p>
<p><a href="https://rakyll.org/cross-compilation/">GO Cross Compilation</a></p>
"""

+++
<h1 id="introduction">Introduction</h1>
<p>There are 3 parts that let JS talk to Go:</p>
<ol>
<li>The C++ binding</li>
<li>Installing the binding</li>
<li>Calling Go</li>
</ol>
<p>Not all the code is shown, check out the <a href="https://github.com/MarcoPolo/react-native-hostobject-demo">source code</a> for specifics.</p>
<h3 id="part-1-the-c-binding">Part 1 - The C++ Binding</h3>
<p>The binding is the C++ glue code that will hook up your Go code to the JS runtime. The binding itself is composed of two main parts.</p>
<h4 id="part-1-1-the-c-binding">Part 1.1 - The C++ Binding</h4>
<p>The binding is a c++ class that implements the <code>jsi::HostObject</code> interface. At the very least it's useful for it to have a <code>get</code> method defined. The type of the <code>get</code> method is:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">jsi::Value </span><span style="color:#8fa1b3;">get</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">, </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::PropNameID &amp;</span><span style="color:#bf616a;">name</span><span style="color:#c0c5ce;">) </span><span style="color:#b48ead;">override</span><span style="color:#c0c5ce;">;
</span></code></pre>
<p>It returns a <code>jsi::Value</code> (a value that is safe for JS). It's given the JS runtime and the prop string used by JS when it <code>get</code>s the field. e.g. <code>global.nativeTest.foo</code> will call this method with PropNameID === <code>&quot;foo&quot;</code>.</p>
<h4 id="part-1-2-the-c-binding-s-install">Part 1.2 - The C++ Binding's install</h4>
<p>Now that we've defined our HostObject, we need to install it into the runtime. We use a static member function that we'll call later to set this up. It looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">void </span><span style="color:#c0c5ce;">TestBinding::</span><span style="color:#8fa1b3;">install</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">,
                          std::shared_ptr&lt;TestBinding&gt; </span><span style="color:#bf616a;">testBinding</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#65737e;">// What is the name that js will use when it reaches for this?
  // i.e. `global.nativeTest` in JS
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> testModuleName = &quot;</span><span style="color:#a3be8c;">nativeTest</span><span style="color:#c0c5ce;">&quot;;
  </span><span style="color:#65737e;">// Create a JS object version of our binding
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> object = jsi::Object::</span><span style="color:#bf616a;">createFromHostObject</span><span style="color:#c0c5ce;">(runtime, testBinding);
  </span><span style="color:#65737e;">// set the &quot;nativeTest&quot; propert
</span><span style="color:#c0c5ce;">  runtime.</span><span style="color:#bf616a;">global</span><span style="color:#c0c5ce;">().</span><span style="color:#bf616a;">setProperty</span><span style="color:#c0c5ce;">(runtime, testModuleName, std::</span><span style="color:#bf616a;">move</span><span style="color:#c0c5ce;">(object));
}
</span></code></pre><h3 id="part-2-installing-the-binding-on-android">Part 2. Installing the binding (on Android)</h3>
<p>Since we have a reference to the runtime in Java land, we'll have to create a JNI method to pass the runtime ptr to the native C++ land. We can add this JNI method to our TestBinding file with a guard.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">#if</span><span style="color:#c0c5ce;"> ANDROID
</span><span style="color:#b48ead;">extern </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot; {
JNIEXPORT </span><span style="color:#b48ead;">void</span><span style="color:#c0c5ce;"> JNICALL </span><span style="color:#8fa1b3;">Java_com_testmodule_MainActivity_install</span><span style="color:#c0c5ce;">(
    JNIEnv *</span><span style="color:#bf616a;">env</span><span style="color:#c0c5ce;">, jobject </span><span style="color:#bf616a;">thiz</span><span style="color:#c0c5ce;">, jlong </span><span style="color:#bf616a;">runtimePtr</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> testBinding = std::</span><span style="color:#bf616a;">make_shared</span><span style="color:#c0c5ce;">&lt;example::TestBinding&gt;();
  jsi::Runtime *runtime = (jsi::Runtime *)runtimePtr;

  example::TestBinding::</span><span style="color:#bf616a;">install</span><span style="color:#c0c5ce;">(*runtime, testBinding);
}
}
</span><span style="color:#b48ead;">#endif
</span></code></pre>
<p>Then on the Java side (after we compile this into a shared library), we register this native function and call it when we're ready.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#65737e;">// In MainActivity

</span><span style="color:#b48ead;">public class </span><span style="color:#ebcb8b;">MainActivity </span><span style="color:#b48ead;">extends </span><span style="color:#a3be8c;">ReactActivity </span><span style="color:#b48ead;">implements </span><span style="color:#a3be8c;">ReactInstanceManager</span><span style="color:#eff1f5;">.</span><span style="color:#a3be8c;">ReactInstanceEventListener </span><span style="color:#eff1f5;">{
    </span><span style="color:#b48ead;">static </span><span style="color:#eff1f5;">{
        </span><span style="color:#65737e;">// Load our jni
        </span><span style="color:#ebcb8b;">System</span><span style="color:#eff1f5;">.</span><span style="color:#bf616a;">loadLibrary</span><span style="color:#eff1f5;">(</span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">test_module_jni</span><span style="color:#c0c5ce;">&quot;</span><span style="color:#eff1f5;">);
    }

    </span><span style="color:#65737e;">//... ellided ...

    </span><span style="color:#eff1f5;">@</span><span style="color:#bf616a;">Override
    </span><span style="color:#b48ead;">public void </span><span style="color:#8fa1b3;">onReactContextInitialized</span><span style="color:#eff1f5;">(</span><span style="color:#ebcb8b;">ReactContext </span><span style="color:#bf616a;">context</span><span style="color:#eff1f5;">) {
        </span><span style="color:#65737e;">// Call our native function with the runtime pointer
        </span><span style="color:#bf616a;">install</span><span style="color:#eff1f5;">(context.</span><span style="color:#bf616a;">getJavaScriptContextHolder</span><span style="color:#eff1f5;">().</span><span style="color:#bf616a;">get</span><span style="color:#eff1f5;">());
    }

    </span><span style="color:#65737e;">//  declare our native function
    </span><span style="color:#b48ead;">public native void </span><span style="color:#8fa1b3;">install</span><span style="color:#eff1f5;">(</span><span style="color:#b48ead;">long </span><span style="color:#bf616a;">jsContextNativePointer</span><span style="color:#eff1f5;">);
}
</span></code></pre><h3 id="part-3-calling-go">Part 3. Calling Go</h3>
<p>Now that our binding is installed in the runtime, we can make it do something useful.</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">jsi::Value TestBinding::</span><span style="color:#8fa1b3;">get</span><span style="color:#c0c5ce;">(jsi::Runtime &amp;</span><span style="color:#bf616a;">runtime</span><span style="color:#c0c5ce;">,
                            </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::PropNameID &amp;</span><span style="color:#bf616a;">name</span><span style="color:#c0c5ce;">) {
  </span><span style="color:#b48ead;">auto</span><span style="color:#c0c5ce;"> methodName = name.</span><span style="color:#bf616a;">utf8</span><span style="color:#c0c5ce;">(runtime);

  </span><span style="color:#b48ead;">if </span><span style="color:#c0c5ce;">(methodName == &quot;</span><span style="color:#a3be8c;">runTest</span><span style="color:#c0c5ce;">&quot;) {
    </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">jsi::Function::</span><span style="color:#bf616a;">createFromHostFunction</span><span style="color:#c0c5ce;">(
        runtime, name, </span><span style="color:#d08770;">0</span><span style="color:#c0c5ce;">,
        [](jsi::Runtime &amp;runtime, </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::Value &amp;thisValue,
           </span><span style="color:#b48ead;">const</span><span style="color:#c0c5ce;"> jsi::Value *arguments,
           size_t count) -&gt; </span><span style="color:#bf616a;">jsi</span><span style="color:#c0c5ce;">::</span><span style="color:#bf616a;">Value </span><span style="color:#c0c5ce;">{ </span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">TestNum</span><span style="color:#c0c5ce;">(); });
  }
  </span><span style="color:#b48ead;">return </span><span style="color:#c0c5ce;">jsi::Value::</span><span style="color:#bf616a;">undefined</span><span style="color:#c0c5ce;">();
}

</span></code></pre>
<p>Here we return a <code>jsi::Function</code> when JS calls <code>global.nativeTest.runTest</code>. When JS calls it (as in <code>global.nativeTest.runTest()</code>) we execute the code inside the closure, which just returns <code>TestNum()</code>. TestNum is a Go function that's exported through cgo so that it is available to c/c++. Our Go code looks like this:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#b48ead;">package </span><span style="color:#bf616a;">main

</span><span style="color:#b48ead;">import </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">C</span><span style="color:#c0c5ce;">&quot;

</span><span style="color:#65737e;">// TestNum returns a test number to be used in JSI
//export TestNum
</span><span style="color:#b48ead;">func </span><span style="color:#8fa1b3;">TestNum</span><span style="color:#c0c5ce;">() </span><span style="color:#b48ead;">int </span><span style="color:#c0c5ce;">{
	</span><span style="color:#b48ead;">return </span><span style="color:#bf616a;">int</span><span style="color:#c0c5ce;">(</span><span style="color:#d08770;">9001</span><span style="color:#c0c5ce;">)
}
</span><span style="color:#b48ead;">func </span><span style="color:#8fa1b3;">main</span><span style="color:#c0c5ce;">() {
}
</span></code></pre>
<p>cgo builds a header and creates a shared library that is used by our binding.</p>
<h3 id="building">Building</h3>
<ul>
<li>Look at the CMakeLists.txt for specifics on building the C++ code.</li>
<li>Look at from-go/build.sh for specifics on building the go code.</li>
</ul>
<h3 id="a-go-shared-library-for-c-java">A Go Shared Library for C + Java</h3>
<p>It's possible to build the Go code as a shared library for both C and Java, but you'll have to define your own JNI methods. It would be nice if gomobile bind also generated C headers for android, but it doesn't seem possible right now. Instead you'll have to run <code>go build -buildmode=c-shared</code> directly and define your jni methods yourself. Take a look at <code>from-go/build.sh</code> and testnum.go for specifics.</p>
<h2 id="further-reading">Further Reading</h2>
<p><a href="https://medium.com/@christian.falch/https-medium-com-christian-falch-react-native-jsi-challenge-1201a69c8fbf">JSI Challenge #1</a></p>
<p><a href="https://medium.com/@christian.falch/react-native-jsi-challenge-2-56fc4dd91613">JSI Challenge #2</a></p>
<p><a href="http://blog.nparashuram.com/2019/01/react-natives-new-architecture-glossary.html">RN Glossary of Terms</a></p>
<p><a href="https://blog.dogan.io/2015/08/15/java-jni-jnr-go/">GO JNI</a></p>
<p><a href="https://rakyll.org/cross-compilation/">GO Cross Compilation</a></p>

