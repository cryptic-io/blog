
+++
title = "Self-Hosted Email With maddy: A Naive First Attempt"
date = 2021-06-26T00:00:00.000Z
template = "html_content/raw.html"
summary = """
For a long time now I’ve wanted to get off gmail and host my own email
domains. I’ve looked into it ..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/06/26/selfhosted-email-with-maddy.html"
raw = """
<p>For a <em>long</em> time now I’ve wanted to get off gmail and host my own email
domains. I’ve looked into it a few times, but have been discouraged on multiple
fronts:</p>

<ul>
  <li>
    <p>Understanding the protocols underlying email isn’t straightforward; it’s an
old system, there’s a lot of cruft, lots of auxiliary protocols that are now
essentially required, and a lot of different services required to tape it all
together.</p>
  </li>
  <li>
    <p>The services which are required are themselves old, and use operational
patterns that maybe used to make sense but are now pretty freaking cumbersome.
For example, postfix requires something like 3 different system accounts.</p>
  </li>
  <li>
    <p>Deviating from the non-standard route and using something like
<a href="https://mailinabox.email/">Mail-in-a-box</a> involves running docker, which I’m trying to avoid.</p>
  </li>
</ul>

<p>So up till now I had let the idea sit, waiting for something better to come
along.</p>

<p><a href="https://maddy.email">maddy</a> is, I think, something better. According to the homepage
“[maddy] replaces Postfix, Dovecot, OpenDKIM, OpenSPF, OpenDMARC and more with
one daemon with uniform configuration and minimal maintenance cost.” Sounds
perfect! The homepage is clean and to the point, it’s written in go, and the
docs appear to be reasonably well written. And, to top it all off, it’s already
been added to <a href="https://search.nixos.org/packages?channel=21.05&amp;from=0&amp;size=50&amp;sort=relevance&amp;query=maddy">nixpkgs</a>!</p>

<p>So in this post (and subsequent posts) I’ll be documenting my journey into
getting a maddy server running to see how well it works out.</p>

<h2 id="just-do-it">Just Do It</h2>

<p>I’m almost 100% sure this won’t work, but to start with I’m going to simply get
maddy up and running on my home media server as per the tutorial on its site,
and go from there.</p>

<p>First there’s some global system configuration I need to perform. Ideally maddy
could be completely packaged up and not pollute the rest of the system at all,
and if I was using NixOS I think that would be possible, but as it is I need to
create a user for maddy and ensure it’s able to read the TLS certificates that I
manage via <a href="https://letsencrypt.org/">LetsEncrypt</a>.</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">sudo </span>useradd <span class="nt">-mrU</span> <span class="nt">-s</span> /sbin/nologin <span class="nt">-d</span> /var/lib/maddy <span class="nt">-c</span> <span class="s2">"maddy mail server"</span> maddy
<span class="nb">sudo </span>setfacl <span class="nt">-R</span> <span class="nt">-m</span> u:maddy:rX /etc/letsencrypt/<span class="o">{</span>live,archive<span class="o">}</span>
</code></pre></div></div>

<p>The next step is to set up the nix build of the systemd service file. This is a
strategy I’ve been using recently to nix-ify my services without needing to deal
with nix profiles. The idea is to encode the nix store path to everything
directly into the systemd service file, and install that file normally. In this
case this looks something like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.writeTextFile {
    name = "mediocregopher-maddy-service";
    text = ''
        [Unit]
        Description=mediocregopher maddy
        Documentation=man:maddy(1)
        Documentation=man:maddy.conf(5)
        Documentation=https://maddy.email
        After=network.target

        [Service]
        Type=notify
        NotifyAccess=main
        Restart=always
        RestartSec=1s

        User=maddy
        Group=maddy

        # cd to state directory to make sure any relative paths
        # in config will be relative to it unless handled specially.
        WorkingDirectory=/mnt/vol1/maddy
        ReadWritePaths=/mnt/vol1/maddy

        # ... lots of directives from
        # https://github.com/foxcpp/maddy/blob/master/dist/systemd/maddy.service
        # that we'll elide here ...

        ExecStart=${pkgs.maddy}/bin/maddy -config ${./maddy.conf}

        ExecReload=/bin/kill -USR1 $MAINPID
        ExecReload=/bin/kill -USR2 $MAINPID

        [Install]
        WantedBy=multi-user.target
    '';
}
</code></pre></div></div>

<p>With the service now testable, it falls on me to actually go through the setup
steps described in the <a href="https://maddy.email/tutorials/setting-up/">tutorial</a>.</p>

<h2 id="following-the-tutorial">Following The Tutorial</h2>

<p>The first step in the tutorial is setting up of domain names, which I first
perform in cloudflare (where my DNS is hosted) and then reflect into the conf
file. Then I point the <code class="language-plaintext highlighter-rouge">tls file</code> configuration line at my LetsEncrypt
directory by changing the line to:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>tls file /etc/letsencrypt/live/$(hostname)/fullchain.pem /etc/letsencrypt/live/$(hostname)/privkey.pem
</code></pre></div></div>

<p>maddy can access these files thanks to the <code class="language-plaintext highlighter-rouge">setfacl</code> command I performed
earlier.</p>

<p>At this point the server should be effectively configured. However, starting it
via systemd results in this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>failed to load /etc/letsencrypt/live/mx.mydomain.com/fullchain.pem and /etc/letsencrypt/live/mx.mydomain.com/privkey.pem
</code></pre></div></div>

<p>(For my own security I’m not going to be using the actual email domain in this
post, I’ll use <code class="language-plaintext highlighter-rouge">mydomain.com</code> instead.)</p>

<p>This makes sense… I use a wildcard domain with LetsEncrypt, so certs for the
<code class="language-plaintext highlighter-rouge">mx</code> sub-domain specifically won’t exist. I need to figure out how to tell maddy
to use the wildcard, or actually create a separate certificate for the <code class="language-plaintext highlighter-rouge">mx</code>
sub-domain. I’d rather the former, obviously, as it’s far less work.</p>

<p>Luckily, making it use the wildcard isn’t too hard, all that is needed is to
change the <code class="language-plaintext highlighter-rouge">tls file</code> line to:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>tls file /etc/letsencrypt/live/$(primary_domain)/fullchain.pem /etc/letsencrypt/live/$(primary_domain)/privkey.pem
</code></pre></div></div>

<p>This works because my <code class="language-plaintext highlighter-rouge">primary_domain</code> domain is set to the top-level
(<code class="language-plaintext highlighter-rouge">mydomain.com</code>), which is what the wildcard cert is issued for.</p>

<p>At this point maddy is up and running, but there’s still a slight problem. maddy
appears to be placing all of its state files in <code class="language-plaintext highlighter-rouge">/var/lib/maddy</code>, even though
I’d like to place them in <code class="language-plaintext highlighter-rouge">/mnt/vol1/maddy</code>. I had set the <code class="language-plaintext highlighter-rouge">WorkingDirectory</code> in
the systemd service file to this, but apparently that’s not enough. After
digging through the codebase I discover an undocumented directive which can be
added to the conf file:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>state_dir /mnt/vol1/maddy
</code></pre></div></div>

<p>Kind of annoying, but at least it works.</p>

<p>The next step is to fiddle with DNS records some more. I add the SPF, DMARC and
DKIM records to cloudflare as described by the tutorial (what do these do? I
have no fuckin clue).</p>

<p>I also need to set up MTA-STS (again, not really knowing what that is). The
tutorial says I need to make a file with certain contents available at the URL
<code class="language-plaintext highlighter-rouge">https://mta-sts.mydomain.com/.well-known/mta-sts.txt</code>. I love it when protocol
has to give up and resort to another one in order to keep itself afloat, it
really inspires confidence.</p>

<p>Anyway, I set that subdomain up in cloudflare, and add the following to my nginx
configuration:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>server {
    listen      80;
    server_name mta-sts.mydomain.com;
    include     include/public_whitelist.conf;

    location / {
        return 404;
    }

    location /.well-known/mta-sts.txt {

        # Check out openresty if you want to get super useful nginx plugins, like
        # the echo module, out-of-the-box.
        echo 'mode: enforce';
        echo 'max_age: 604800';
        echo 'mx: mx.mydomain.com';
    }
}
</code></pre></div></div>

<p>(Note: my <code class="language-plaintext highlighter-rouge">public_whitelist.conf</code> only allows cloudflare IPs to access this
sub-domain, which is something I do for all sub-domains which I can put through
cloudflare.)</p>

<p>Finally, I need to create some actual credentials in maddy with which to send my
email. I do this via the <code class="language-plaintext highlighter-rouge">maddyctl</code> command-line utility:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; sudo maddyctl --config maddy.conf creds create 'me@mydomain.com'
Enter password for new user:
&gt; sudo maddyctl --config maddy.conf imap-acct create 'me@mydomain.com'
</code></pre></div></div>

<h2 id="send-it">Send It!</h2>

<p>At this point I’m ready to actually test the email sending. I’m going to use
<a href="https://wiki.archlinux.org/title/S-nail">S-nail</a> to do so, and after reading through the docs there I put the
following in my <code class="language-plaintext highlighter-rouge">~/.mailrc</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>set v15-compat
set mta=smtp://me%40mydomain.com:password@localhost:587 smtp-use-starttls
</code></pre></div></div>

<p>And attempt the following <code class="language-plaintext highlighter-rouge">mailx</code> command to send an email from my new mail
server:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; echo 'Hello! This is a cool email' | mailx -s 'Subject' -r 'Me &lt;me@mydomain.com&gt;' 'test.email@gmail.com'
reproducible_build: TLS certificate does not match: localhost:587
/home/mediocregopher/dead.letter 10/313
reproducible_build: ... message not sent
</code></pre></div></div>

<p>Damn. TLS is failing because I’m connecting over <code class="language-plaintext highlighter-rouge">localhost</code>, but maddy is
serving the TLS certs for <code class="language-plaintext highlighter-rouge">mydomain.com</code>. Since I haven’t gone through the steps
of exposing maddy publicly yet (which would require port forwarding in my
router, as well as opening a port in iptables) I can’t properly test this with
TLS not being required. <em>It’s very important that I remember to re-require TLS
before putting anything public.</em></p>

<p>In the meantime I remove the <code class="language-plaintext highlighter-rouge">smtp-use-starttls</code> entry from my <code class="language-plaintext highlighter-rouge">~/.mailrc</code>, and
retry the <code class="language-plaintext highlighter-rouge">mailx</code> command. This time I get a different error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reproducible_build: SMTP server: 523 5.7.10 TLS is required
</code></pre></div></div>

<p>It turns out there’s a further configuration directive I need to add, this time
in <code class="language-plaintext highlighter-rouge">maddy.conf</code>. Within my <code class="language-plaintext highlighter-rouge">submission</code> configuration block I add the following
line:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>insecure_auth true
</code></pre></div></div>

<p>This allows plaintext auth over non-TLS connections. Kind of sketchy, but again
I’ll undo this before putting anything public.</p>

<p>Finally, I try the <code class="language-plaintext highlighter-rouge">mailx</code> command one more time, and it successfully returns!</p>

<p>Unfortunately, no email is ever received in my gmail :( I check the maddy logs
and see what I feared most all along:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Jun 29 08:44:58 maddy[127396]: remote: cannot use MX        {"domain":"gmail.com","io_op":"dial","msg_id":"5c23d76a-60db30e7","reason":"dial tcp 142.250.152.26:25: connect: connection timed out","remote_addr":"142.250.152.
26:25","remote_server":"alt1.gmail-smtp-in.l.google.com.","smtp_code":450,"smtp_enchcode":"4.4.2","smtp_msg":"Network I/O error"}
</code></pre></div></div>

<p>My ISP is blocking outbound connections on port 25. This is classic email
bullshit; ISPs essentially can’t allow outbound SMTP connections, as email is so
easily abusable it would drastically increase the amount of spam being sent from
their networks.</p>

<h2 id="lessons-learned">Lessons Learned</h2>

<p>The next attempt will involve an external VPS which allows SMTP, and a lot more
interesting configuration. But for now I’m forced to turn off maddy and let this
dream sit for a little while longer.</p>"""

+++
<p>For a <em>long</em> time now I’ve wanted to get off gmail and host my own email
domains. I’ve looked into it a few times, but have been discouraged on multiple
fronts:</p>

<ul>
  <li>
    <p>Understanding the protocols underlying email isn’t straightforward; it’s an
old system, there’s a lot of cruft, lots of auxiliary protocols that are now
essentially required, and a lot of different services required to tape it all
together.</p>
  </li>
  <li>
    <p>The services which are required are themselves old, and use operational
patterns that maybe used to make sense but are now pretty freaking cumbersome.
For example, postfix requires something like 3 different system accounts.</p>
  </li>
  <li>
    <p>Deviating from the non-standard route and using something like
<a href="https://mailinabox.email/">Mail-in-a-box</a> involves running docker, which I’m trying to avoid.</p>
  </li>
</ul>

<p>So up till now I had let the idea sit, waiting for something better to come
along.</p>

<p><a href="https://maddy.email">maddy</a> is, I think, something better. According to the homepage
“[maddy] replaces Postfix, Dovecot, OpenDKIM, OpenSPF, OpenDMARC and more with
one daemon with uniform configuration and minimal maintenance cost.” Sounds
perfect! The homepage is clean and to the point, it’s written in go, and the
docs appear to be reasonably well written. And, to top it all off, it’s already
been added to <a href="https://search.nixos.org/packages?channel=21.05&amp;from=0&amp;size=50&amp;sort=relevance&amp;query=maddy">nixpkgs</a>!</p>

<p>So in this post (and subsequent posts) I’ll be documenting my journey into
getting a maddy server running to see how well it works out.</p>

<h2 id="just-do-it">Just Do It</h2>

<p>I’m almost 100% sure this won’t work, but to start with I’m going to simply get
maddy up and running on my home media server as per the tutorial on its site,
and go from there.</p>

<p>First there’s some global system configuration I need to perform. Ideally maddy
could be completely packaged up and not pollute the rest of the system at all,
and if I was using NixOS I think that would be possible, but as it is I need to
create a user for maddy and ensure it’s able to read the TLS certificates that I
manage via <a href="https://letsencrypt.org/">LetsEncrypt</a>.</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nb">sudo </span>useradd <span class="nt">-mrU</span> <span class="nt">-s</span> /sbin/nologin <span class="nt">-d</span> /var/lib/maddy <span class="nt">-c</span> <span class="s2">"maddy mail server"</span> maddy
<span class="nb">sudo </span>setfacl <span class="nt">-R</span> <span class="nt">-m</span> u:maddy:rX /etc/letsencrypt/<span class="o">{</span>live,archive<span class="o">}</span>
</code></pre></div></div>

<p>The next step is to set up the nix build of the systemd service file. This is a
strategy I’ve been using recently to nix-ify my services without needing to deal
with nix profiles. The idea is to encode the nix store path to everything
directly into the systemd service file, and install that file normally. In this
case this looks something like:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>pkgs.writeTextFile {
    name = "mediocregopher-maddy-service";
    text = ''
        [Unit]
        Description=mediocregopher maddy
        Documentation=man:maddy(1)
        Documentation=man:maddy.conf(5)
        Documentation=https://maddy.email
        After=network.target

        [Service]
        Type=notify
        NotifyAccess=main
        Restart=always
        RestartSec=1s

        User=maddy
        Group=maddy

        # cd to state directory to make sure any relative paths
        # in config will be relative to it unless handled specially.
        WorkingDirectory=/mnt/vol1/maddy
        ReadWritePaths=/mnt/vol1/maddy

        # ... lots of directives from
        # https://github.com/foxcpp/maddy/blob/master/dist/systemd/maddy.service
        # that we'll elide here ...

        ExecStart=${pkgs.maddy}/bin/maddy -config ${./maddy.conf}

        ExecReload=/bin/kill -USR1 $MAINPID
        ExecReload=/bin/kill -USR2 $MAINPID

        [Install]
        WantedBy=multi-user.target
    '';
}
</code></pre></div></div>

<p>With the service now testable, it falls on me to actually go through the setup
steps described in the <a href="https://maddy.email/tutorials/setting-up/">tutorial</a>.</p>

<h2 id="following-the-tutorial">Following The Tutorial</h2>

<p>The first step in the tutorial is setting up of domain names, which I first
perform in cloudflare (where my DNS is hosted) and then reflect into the conf
file. Then I point the <code class="language-plaintext highlighter-rouge">tls file</code> configuration line at my LetsEncrypt
directory by changing the line to:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>tls file /etc/letsencrypt/live/$(hostname)/fullchain.pem /etc/letsencrypt/live/$(hostname)/privkey.pem
</code></pre></div></div>

<p>maddy can access these files thanks to the <code class="language-plaintext highlighter-rouge">setfacl</code> command I performed
earlier.</p>

<p>At this point the server should be effectively configured. However, starting it
via systemd results in this error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>failed to load /etc/letsencrypt/live/mx.mydomain.com/fullchain.pem and /etc/letsencrypt/live/mx.mydomain.com/privkey.pem
</code></pre></div></div>

<p>(For my own security I’m not going to be using the actual email domain in this
post, I’ll use <code class="language-plaintext highlighter-rouge">mydomain.com</code> instead.)</p>

<p>This makes sense… I use a wildcard domain with LetsEncrypt, so certs for the
<code class="language-plaintext highlighter-rouge">mx</code> sub-domain specifically won’t exist. I need to figure out how to tell maddy
to use the wildcard, or actually create a separate certificate for the <code class="language-plaintext highlighter-rouge">mx</code>
sub-domain. I’d rather the former, obviously, as it’s far less work.</p>

<p>Luckily, making it use the wildcard isn’t too hard, all that is needed is to
change the <code class="language-plaintext highlighter-rouge">tls file</code> line to:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>tls file /etc/letsencrypt/live/$(primary_domain)/fullchain.pem /etc/letsencrypt/live/$(primary_domain)/privkey.pem
</code></pre></div></div>

<p>This works because my <code class="language-plaintext highlighter-rouge">primary_domain</code> domain is set to the top-level
(<code class="language-plaintext highlighter-rouge">mydomain.com</code>), which is what the wildcard cert is issued for.</p>

<p>At this point maddy is up and running, but there’s still a slight problem. maddy
appears to be placing all of its state files in <code class="language-plaintext highlighter-rouge">/var/lib/maddy</code>, even though
I’d like to place them in <code class="language-plaintext highlighter-rouge">/mnt/vol1/maddy</code>. I had set the <code class="language-plaintext highlighter-rouge">WorkingDirectory</code> in
the systemd service file to this, but apparently that’s not enough. After
digging through the codebase I discover an undocumented directive which can be
added to the conf file:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>state_dir /mnt/vol1/maddy
</code></pre></div></div>

<p>Kind of annoying, but at least it works.</p>

<p>The next step is to fiddle with DNS records some more. I add the SPF, DMARC and
DKIM records to cloudflare as described by the tutorial (what do these do? I
have no fuckin clue).</p>

<p>I also need to set up MTA-STS (again, not really knowing what that is). The
tutorial says I need to make a file with certain contents available at the URL
<code class="language-plaintext highlighter-rouge">https://mta-sts.mydomain.com/.well-known/mta-sts.txt</code>. I love it when protocol
has to give up and resort to another one in order to keep itself afloat, it
really inspires confidence.</p>

<p>Anyway, I set that subdomain up in cloudflare, and add the following to my nginx
configuration:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>server {
    listen      80;
    server_name mta-sts.mydomain.com;
    include     include/public_whitelist.conf;

    location / {
        return 404;
    }

    location /.well-known/mta-sts.txt {

        # Check out openresty if you want to get super useful nginx plugins, like
        # the echo module, out-of-the-box.
        echo 'mode: enforce';
        echo 'max_age: 604800';
        echo 'mx: mx.mydomain.com';
    }
}
</code></pre></div></div>

<p>(Note: my <code class="language-plaintext highlighter-rouge">public_whitelist.conf</code> only allows cloudflare IPs to access this
sub-domain, which is something I do for all sub-domains which I can put through
cloudflare.)</p>

<p>Finally, I need to create some actual credentials in maddy with which to send my
email. I do this via the <code class="language-plaintext highlighter-rouge">maddyctl</code> command-line utility:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; sudo maddyctl --config maddy.conf creds create 'me@mydomain.com'
Enter password for new user:
&gt; sudo maddyctl --config maddy.conf imap-acct create 'me@mydomain.com'
</code></pre></div></div>

<h2 id="send-it">Send It!</h2>

<p>At this point I’m ready to actually test the email sending. I’m going to use
<a href="https://wiki.archlinux.org/title/S-nail">S-nail</a> to do so, and after reading through the docs there I put the
following in my <code class="language-plaintext highlighter-rouge">~/.mailrc</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>set v15-compat
set mta=smtp://me%40mydomain.com:password@localhost:587 smtp-use-starttls
</code></pre></div></div>

<p>And attempt the following <code class="language-plaintext highlighter-rouge">mailx</code> command to send an email from my new mail
server:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>&gt; echo 'Hello! This is a cool email' | mailx -s 'Subject' -r 'Me &lt;me@mydomain.com&gt;' 'test.email@gmail.com'
reproducible_build: TLS certificate does not match: localhost:587
/home/mediocregopher/dead.letter 10/313
reproducible_build: ... message not sent
</code></pre></div></div>

<p>Damn. TLS is failing because I’m connecting over <code class="language-plaintext highlighter-rouge">localhost</code>, but maddy is
serving the TLS certs for <code class="language-plaintext highlighter-rouge">mydomain.com</code>. Since I haven’t gone through the steps
of exposing maddy publicly yet (which would require port forwarding in my
router, as well as opening a port in iptables) I can’t properly test this with
TLS not being required. <em>It’s very important that I remember to re-require TLS
before putting anything public.</em></p>

<p>In the meantime I remove the <code class="language-plaintext highlighter-rouge">smtp-use-starttls</code> entry from my <code class="language-plaintext highlighter-rouge">~/.mailrc</code>, and
retry the <code class="language-plaintext highlighter-rouge">mailx</code> command. This time I get a different error:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>reproducible_build: SMTP server: 523 5.7.10 TLS is required
</code></pre></div></div>

<p>It turns out there’s a further configuration directive I need to add, this time
in <code class="language-plaintext highlighter-rouge">maddy.conf</code>. Within my <code class="language-plaintext highlighter-rouge">submission</code> configuration block I add the following
line:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>insecure_auth true
</code></pre></div></div>

<p>This allows plaintext auth over non-TLS connections. Kind of sketchy, but again
I’ll undo this before putting anything public.</p>

<p>Finally, I try the <code class="language-plaintext highlighter-rouge">mailx</code> command one more time, and it successfully returns!</p>

<p>Unfortunately, no email is ever received in my gmail :( I check the maddy logs
and see what I feared most all along:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Jun 29 08:44:58 maddy[127396]: remote: cannot use MX        {"domain":"gmail.com","io_op":"dial","msg_id":"5c23d76a-60db30e7","reason":"dial tcp 142.250.152.26:25: connect: connection timed out","remote_addr":"142.250.152.
26:25","remote_server":"alt1.gmail-smtp-in.l.google.com.","smtp_code":450,"smtp_enchcode":"4.4.2","smtp_msg":"Network I/O error"}
</code></pre></div></div>

<p>My ISP is blocking outbound connections on port 25. This is classic email
bullshit; ISPs essentially can’t allow outbound SMTP connections, as email is so
easily abusable it would drastically increase the amount of spam being sent from
their networks.</p>

<h2 id="lessons-learned">Lessons Learned</h2>

<p>The next attempt will involve an external VPS which allows SMTP, and a lot more
interesting configuration. But for now I’m forced to turn off maddy and let this
dream sit for a little while longer.</p>
