
+++
title = "Setting Up maddy On A VPS"
date = 2021-07-06T00:00:00.000Z
template = "html_content/raw.html"
summary = """
In the previous post I left off with being blocked by my ISP from sending
outbound emails on port 25..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/07/06/maddy-vps.html"
raw = """
<p>In the previous post I left off with being blocked by my ISP from sending
outbound emails on port 25, effectively forcing me to set up <a href="https://maddy.email">maddy</a> on a
virtual private server (VPS) somewhere else.</p>

<p>After some research I chose <a href="https://www.vultr.com/">Vultr</a> as my VPS of choice. They apparently
don’t block you from sending outbound emails on port 25, and are in general
pretty cheap. I rented their smallest VPS server for $5/month, plus an
additional $3/month to reserve an IPv4 address (though I’m not sure I really
need that, I have dDNS set up at home and could easily get that working here as
well).</p>

<h2 id="tls">TLS</h2>

<p>The first major hurdle was getting TLS certs for <code class="language-plaintext highlighter-rouge">mydomain.com</code> (not the real
domain) onto my Vultr box. For the time being I’ve opted to effectively
copy-paste my local <a href="https://letsencrypt.org/">LetsEncrypt</a> setup to Vultr, using certbot to
periodically update my records using DNS TXT challenges.</p>

<p>The downside to this is that I now require my Cloudflare API key to be present
on the Vultr box, which effectively means that if the box ever gets owned
someone will have full access to all my DNS. For now I’ve locked down the box as
best as I can, and will look into changing the setup in the future. There’s two
ways I could go about it:</p>

<ul>
  <li>
    <p>SCP the certs from my local box to the remote everytime they’re renewed. This
would require setting up a new user on the remote box with very narrow
privileges. This isn’t the worst thing though.</p>
  </li>
  <li>
    <p>Use a different challenge method than DNS TXT records.</p>
  </li>
</ul>

<p>But again, I’m trying to set up maddy, not LetsEncrypt, and so I needed to move
on.</p>

<h2 id="deployment">Deployment</h2>

<p>In the previous post I talked about how I’m using nix to generate a systemd
service file which encompasses all dependencies automatically, without needing
to install anything to the global system or my nix profile.</p>

<p>Since that’s already been set up, it’s fairly trivial to use <code class="language-plaintext highlighter-rouge">nix-copy-closure</code>
to copy a service file, and <em>all</em> of its dependencies (including configuration)
from my local box to the remote Vultr box. Simply:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-copy-closure -s &lt;ssh host&gt; &lt;nix store path&gt;
</code></pre></div></div>

<p>I whipped up some scripts around this so that I can run a single make target and
have it build the service (and all deps), do a <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> to the remote
host, copy the service file into <code class="language-plaintext highlighter-rouge">/etc/systemd/service</code>, and restart the
service.</p>

<h2 id="changes">Changes</h2>

<p>For the most part the maddy deployment on the remote box is the same as on the
local one. Down the road I will likely change them both significantly, so that
the remote one only deals with SMTP (no need for IMAP) and the local one will
automatically forward all submitted messages to it.</p>

<p>Once that’s done, and the remote Vultr box is set up on my <a href="https://github.com/slackhq/nebula">nebula</a>
network, there won’t be a need for the remote maddy to do any SMTP
authentication, since the submission endpoint can be made entirely private.</p>

<p>For now, however, I’ve set up maddy on the remote box’s public interface with
SMTP authentication enabled, to make testing easier.</p>

<h2 id="testing">Testing</h2>

<p>And now, to test it! I changed the SMTP credentials in my <code class="language-plaintext highlighter-rouge">~/.mailrc</code> file as
appropriate, and let a test email rip:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>echo 'Hello! This is a cool email' | mailx -s 'Subject' -r 'Me &lt;me@mydomain.com&gt;' 'test.email@gmail.com'
</code></pre></div></div>

<p>This would, ideally, send an email from my SMTP server (on my domain) to a test
gmail domain. Unfortunately, it did not do that, but instead maddy spit this out
in its log:</p>

<blockquote>
  <p>maddy[1547]: queue: delivery attempt failed        {“msg_id”:”330a1ed9”,”rcpt”:”mediocregopher@gmail.com”,”reason”:”[2001:19f0:5001:355a:5400:3ff:fe73:3d02] Our system has detected that\\nthis message does not meet IPv6 sending guidelines regarding PTR\\nrecords and authentication. Please review\\n https://support.google.com/mail/?p=IPv6AuthError for more information\\n. gn42si18496961ejc.717 - gsmtp”,”remote_server”:”gmail-smtp-in.l.google.com.”,”smtp_code”:550,”smtp_enchcode”:”5.7.1”,”smtp_msg”:”gmail-smtp-in.l.google.com. said: [2001:19f0:5001:355a:5400:3ff:fe73:3d02] Our system has detected that\\nthis message does not meet IPv6 sending guidelines regarding PTR\\nrecords and authentication. Please review\\n https://support.google.com/mail/?p=IPv6AuthError for more information\\n. gn42si18496961ejc.717 - gsmtp”}</p>
</blockquote>

<p>Luckily Vultr makes setting up PTR records for reverse DNS fairly easy. They
even allowed me to do it on my box’s IPv6 address which I’m not paying to
reserve (though I’m not sure what the long-term risks of that are… can it
change?).</p>

<p>Once done, I attempted to send my email again, and what do you know…</p>

<p><img src="/assets/maddy-vps/success.png" alt="Success!" /></p>

<p>Success!</p>

<p>So now I can send emails. There are a few next steps from here:</p>

<ul>
  <li>
    <p>Get the VPS on my nebula network and lock it down properly.</p>
  </li>
  <li>
    <p>Fix the TLS cert situation.</p>
  </li>
  <li>
    <p>Set up the remote maddy to forward submissions to my local maddy.</p>
  </li>
  <li>
    <p>Use my sick new email!</p>
  </li>
</ul>"""

+++
<p>In the previous post I left off with being blocked by my ISP from sending
outbound emails on port 25, effectively forcing me to set up <a href="https://maddy.email">maddy</a> on a
virtual private server (VPS) somewhere else.</p>

<p>After some research I chose <a href="https://www.vultr.com/">Vultr</a> as my VPS of choice. They apparently
don’t block you from sending outbound emails on port 25, and are in general
pretty cheap. I rented their smallest VPS server for $5/month, plus an
additional $3/month to reserve an IPv4 address (though I’m not sure I really
need that, I have dDNS set up at home and could easily get that working here as
well).</p>

<h2 id="tls">TLS</h2>

<p>The first major hurdle was getting TLS certs for <code class="language-plaintext highlighter-rouge">mydomain.com</code> (not the real
domain) onto my Vultr box. For the time being I’ve opted to effectively
copy-paste my local <a href="https://letsencrypt.org/">LetsEncrypt</a> setup to Vultr, using certbot to
periodically update my records using DNS TXT challenges.</p>

<p>The downside to this is that I now require my Cloudflare API key to be present
on the Vultr box, which effectively means that if the box ever gets owned
someone will have full access to all my DNS. For now I’ve locked down the box as
best as I can, and will look into changing the setup in the future. There’s two
ways I could go about it:</p>

<ul>
  <li>
    <p>SCP the certs from my local box to the remote everytime they’re renewed. This
would require setting up a new user on the remote box with very narrow
privileges. This isn’t the worst thing though.</p>
  </li>
  <li>
    <p>Use a different challenge method than DNS TXT records.</p>
  </li>
</ul>

<p>But again, I’m trying to set up maddy, not LetsEncrypt, and so I needed to move
on.</p>

<h2 id="deployment">Deployment</h2>

<p>In the previous post I talked about how I’m using nix to generate a systemd
service file which encompasses all dependencies automatically, without needing
to install anything to the global system or my nix profile.</p>

<p>Since that’s already been set up, it’s fairly trivial to use <code class="language-plaintext highlighter-rouge">nix-copy-closure</code>
to copy a service file, and <em>all</em> of its dependencies (including configuration)
from my local box to the remote Vultr box. Simply:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>nix-copy-closure -s &lt;ssh host&gt; &lt;nix store path&gt;
</code></pre></div></div>

<p>I whipped up some scripts around this so that I can run a single make target and
have it build the service (and all deps), do a <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> to the remote
host, copy the service file into <code class="language-plaintext highlighter-rouge">/etc/systemd/service</code>, and restart the
service.</p>

<h2 id="changes">Changes</h2>

<p>For the most part the maddy deployment on the remote box is the same as on the
local one. Down the road I will likely change them both significantly, so that
the remote one only deals with SMTP (no need for IMAP) and the local one will
automatically forward all submitted messages to it.</p>

<p>Once that’s done, and the remote Vultr box is set up on my <a href="https://github.com/slackhq/nebula">nebula</a>
network, there won’t be a need for the remote maddy to do any SMTP
authentication, since the submission endpoint can be made entirely private.</p>

<p>For now, however, I’ve set up maddy on the remote box’s public interface with
SMTP authentication enabled, to make testing easier.</p>

<h2 id="testing">Testing</h2>

<p>And now, to test it! I changed the SMTP credentials in my <code class="language-plaintext highlighter-rouge">~/.mailrc</code> file as
appropriate, and let a test email rip:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>echo 'Hello! This is a cool email' | mailx -s 'Subject' -r 'Me &lt;me@mydomain.com&gt;' 'test.email@gmail.com'
</code></pre></div></div>

<p>This would, ideally, send an email from my SMTP server (on my domain) to a test
gmail domain. Unfortunately, it did not do that, but instead maddy spit this out
in its log:</p>

<blockquote>
  <p>maddy[1547]: queue: delivery attempt failed        {“msg_id”:”330a1ed9”,”rcpt”:”mediocregopher@gmail.com”,”reason”:”[2001:19f0:5001:355a:5400:3ff:fe73:3d02] Our system has detected that\nthis message does not meet IPv6 sending guidelines regarding PTR\nrecords and authentication. Please review\n https://support.google.com/mail/?p=IPv6AuthError for more information\n. gn42si18496961ejc.717 - gsmtp”,”remote_server”:”gmail-smtp-in.l.google.com.”,”smtp_code”:550,”smtp_enchcode”:”5.7.1”,”smtp_msg”:”gmail-smtp-in.l.google.com. said: [2001:19f0:5001:355a:5400:3ff:fe73:3d02] Our system has detected that\nthis message does not meet IPv6 sending guidelines regarding PTR\nrecords and authentication. Please review\n https://support.google.com/mail/?p=IPv6AuthError for more information\n. gn42si18496961ejc.717 - gsmtp”}</p>
</blockquote>

<p>Luckily Vultr makes setting up PTR records for reverse DNS fairly easy. They
even allowed me to do it on my box’s IPv6 address which I’m not paying to
reserve (though I’m not sure what the long-term risks of that are… can it
change?).</p>

<p>Once done, I attempted to send my email again, and what do you know…</p>

<p><img src="/assets/maddy-vps/success.png" alt="Success!" /></p>

<p>Success!</p>

<p>So now I can send emails. There are a few next steps from here:</p>

<ul>
  <li>
    <p>Get the VPS on my nebula network and lock it down properly.</p>
  </li>
  <li>
    <p>Fix the TLS cert situation.</p>
  </li>
  <li>
    <p>Set up the remote maddy to forward submissions to my local maddy.</p>
  </li>
  <li>
    <p>Use my sick new email!</p>
  </li>
</ul>
