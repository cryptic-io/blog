
+++
title = "Managing a Home Server With Nix"
date = 2021-11-08T00:00:00.000Z
template = "html_content/raw.html"
summary = """
My home server has a lot running on it. Some of it I’ve written about in this
blog previously, some ..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/11/08/managing-a-home-server-with-nix.html"
raw = """
<p>My home server has a lot running on it. Some of it I’ve written about in this
blog previously, some of it I haven’t. It’s hosting this blog itself, even!</p>

<p>With all of these services comes management overhead, both in terms of managing
packages and configuration. I’m pretty strict about tracking packages and
configuration in version control, and backing up all state I care about in B2,
such that if, <em>at any moment</em>, the server is abducted by aliens, I won’t have
lost much.</p>

<h2 id="docker">Docker</h2>

<p>Previously I accomplished this with docker. Each service ran in a container
under the docker daemon, with configuration files and state directories shared
in via volume shares. Configuration files could then be stored in a git repo,
and my <code class="language-plaintext highlighter-rouge">docker run</code> commands were documented in <code class="language-plaintext highlighter-rouge">Makefile</code>s, because that was
easy.</p>

<p>This approach had drawbacks, notably:</p>

<ul>
  <li>
    <p>Docker networking is a pain. To be fair I should have just used
<code class="language-plaintext highlighter-rouge">--network=host</code> and dodged the issue, but I didn’t.</p>
  </li>
  <li>
    <p>Docker images aren’t actually deterministically built, so if I were to ever
have to rebuild any of the images I was using it I couldn’t be sure I’d end up
with the same code as before. For some services this is actually a nagging
security concern in the back of my head.</p>
  </li>
  <li>
    <p>File permissions with docker volumes are fucked.</p>
  </li>
  <li>
    <p>Who knows how long the current version of docker will support the old ass
images and configuration system I’m using now. Probably not the next 10 years.
And what if dockerhub goes away, or changes its pricing model?</p>
  </li>
  <li>
    <p>As previously noted, docker is for boomers.</p>
  </li>
</ul>

<h2 id="nix">Nix</h2>

<p>Nix is the new hotness, and it solves all of the above problems quite nicely.
I’m not going to get into too much detail about how nix works here (honestly I’m
not very good at explaining it), but suffice to say I’m switching everything
over, and this post is about how that actually looks in a practical sense.</p>

<p>For the most part I eschew things like <a href="https://nixos.wiki/wiki/Flakes">flakes</a>,
<a href="https://github.com/nix-community/home-manager">home-manager</a>, and any other frameworks built on nix. While the
framework of the day may come and go, the base nix language should remain
constant.</p>

<p>As before with docker, I have a single git repo being stored privately in a way
I’m confident is secure (which is necessary because it contains some secrets).</p>

<p>At the root of the repo there exists a <code class="language-plaintext highlighter-rouge">pkgs.nix</code> file, which looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>{
  src ? builtins.fetchTarball {
    name = "nixpkgs-d50923ab2d308a1ddb21594ba6ae064cab65d8ae";
    url = "https://github.com/NixOS/nixpkgs/archive/d50923ab2d308a1ddb21594ba6ae064cab65d8ae.tar.gz";
    sha256 = "1k7xpymhzb4hilv6a1jp2lsxgc4yiqclh944m8sxyhriv9p2yhpv";
  },
}: (import src) {}
</code></pre></div></div>

<p>This file exists to provide a pinned version of <code class="language-plaintext highlighter-rouge">nixpkgs</code> which will get used
for all services. As long as I don’t change this file the tools available to me
for building my services will remain constant forever, no matter what else
happens in the nix ecosystem.</p>

<p>Each directory in the repo corresponds to a service I run. I’ll focus on a
particular service, <a href="https://github.com/navidrome/navidrome">navidrome</a>, for now:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>:: <span class="nb">ls</span> <span class="nt">-1</span> navidrome
Makefile
default.nix
navidrome.toml
</code></pre></div></div>

<p>Not much to it!</p>

<h3 id="defaultnix">default.nix</h3>

<p>The first file to look at is the <code class="language-plaintext highlighter-rouge">default.nix</code>, as that contains
all the logic. The overall file looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>let

  pkgs = (import ../pkgs.nix) {};

in rec {

    entrypoint = ...;

    service = ...;

    install = ...;

}
</code></pre></div></div>

<p>The file describes an attribute set with three attributes, <code class="language-plaintext highlighter-rouge">entrypoint</code>,
<code class="language-plaintext highlighter-rouge">service</code>, and <code class="language-plaintext highlighter-rouge">install</code>. These form the basic pattern I use for all my
services; pretty much every service I manage has a <code class="language-plaintext highlighter-rouge">default.nix</code> which has
attributes corresponding to these.</p>

<h4 id="entrypoint">Entrypoint</h4>

<p>The first <code class="language-plaintext highlighter-rouge">entrypoint</code>, looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  entrypoint = pkgs.writeScript "mediocregopher-navidrome" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.navidrome}/bin/navidrome --configfile ${./navidrome.toml}
  '';
</code></pre></div></div>

<p>The goal here is to provide an executable which can be run directly, and which
will put together all necessary environment and configuration (<code class="language-plaintext highlighter-rouge">navidrome.toml</code>,
in this case) needed to run the service. Having the entrypoint split out into
its own target, as opposed to inlining it into the service file (defined next),
is convenient for testing; it allows you test <em>exactly</em> what’s going to happen
when running the service normally.</p>

<h4 id="service">Service</h4>

<p><code class="language-plaintext highlighter-rouge">service</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  service = pkgs.writeText "mediocregopher-navidrome-service" ''
    [Unit]
    Description=mediocregopher navidrome
    Requires=network.target
    After=network.target

    [Service]
    Restart=always
    RestartSec=1s
    User=mediocregopher
    Group=mediocregopher
    LimitNOFILE=10000

    # The important part!
    ExecStart=${entrypoint}

    # EXTRA DIRECTIVES ELIDED, SEE
    # https://www.navidrome.org/docs/installation/pre-built-binaries/

    [Install]
    WantedBy=multi-user.target
  '';
</code></pre></div></div>

<p>It’s function is to produce a systemd service file. The service file will
reference the <code class="language-plaintext highlighter-rouge">entrypoint</code> which has already been defined, and in general does
nothing else.</p>

<h4 id="install">Install</h4>

<p><code class="language-plaintext highlighter-rouge">install</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  install = pkgs.writeScript "mediocregopher-navidrome-install" ''
    #!${pkgs.bash}/bin/bash
    sudo cp ${service} /etc/systemd/system/mediocregopher-navidrome.service
    sudo systemctl daemon-reload
    sudo systemctl enable mediocregopher-navidrome
    sudo systemctl restart mediocregopher-navidrome
  '';
</code></pre></div></div>

<p>This attribute produces a script which will install a systemd service on the
system it’s run on. Assuming this is done in the context of a functional nix
environment and standard systemd installation it will “just work”; all relevant
binaries, configuration, etc, will all come along for the ride, and the service
will be running <em>exactly</em> what’s defined in my repo, everytime. Eat your heart
out, ansible!</p>

<p>Nix is usually used for building things, not <em>doing</em> things, so it may seem
unusual for this to be here. But there’s a very good reason for it, which I’ll
get to soon.</p>

<h3 id="makefile">Makefile</h3>

<p>While <code class="language-plaintext highlighter-rouge">default.nix</code> <em>could</em> exist alone, and I <em>could</em> just interact with it
directly using <code class="language-plaintext highlighter-rouge">nix-build</code> commands, I don’t like to do that. Most of the reason
is that I don’t want to have to <em>remember</em> the <code class="language-plaintext highlighter-rouge">nix-build</code> commands I need. So
in each directory there’s a <code class="language-plaintext highlighter-rouge">Makefile</code>, which acts as a kind of index of useful
commands. The one for navidrome looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>install:
\t$$(nix-build -A install --no-out-link)
</code></pre></div></div>

<p>Yup, that’s it. It builds the <code class="language-plaintext highlighter-rouge">install</code> attribute, and runs the resulting script
inline. Easy peasy. Other services might have some other targets, like <code class="language-plaintext highlighter-rouge">init</code>,
which operate the same way but with different script targets.</p>

<h2 id="nix-remotely">Nix Remotely</h2>

<p>If you were waiting for me to explain <em>why</em> the install target is in
<code class="language-plaintext highlighter-rouge">default.nix</code>, rather than just being in the <code class="language-plaintext highlighter-rouge">Makefile</code> (which would also make
sense), this is the part where I do that.</p>

<p>My home server isn’t the only place where I host services, I also have a remote
host which runs some services. These services are defined in this same repo, in
essentially the same way as my local services. The only difference is in the
<code class="language-plaintext highlighter-rouge">Makefile</code>. Let’s look at an example from my <code class="language-plaintext highlighter-rouge">maddy/Makefile</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>install-vultr:
\tnix-build -A install --arg paramsFile ./vultr.nix
\tnix-copy-closure -s ${VULTR} $$(readlink result)
\tssh -tt -q ${VULTR} $$(readlink result)
</code></pre></div></div>

<p>Vultr is the hosting company I’m renting the server from. Apparently I think I
will only ever have one host with them, because I just call it “vultr”.</p>

<p>I’ll go through this one line at a time. The first line is essentially the same
as the <code class="language-plaintext highlighter-rouge">install</code> line from my <code class="language-plaintext highlighter-rouge">navidrome</code> configuration, but with two small
differences: it takes in a parameters file containing the configuration
specific to the vultr host, and it’s only <em>building</em> the install script, not
running it.</p>

<p>The second line is the cool part. My remote host has a working nix environment
already, so I can just use <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> to copy the <code class="language-plaintext highlighter-rouge">install</code> script to
it. Since the <code class="language-plaintext highlighter-rouge">install</code> script references the service file, which in turn
references the <code class="language-plaintext highlighter-rouge">entrypoint</code>, which in turn references the service binary itself,
and all of its configuration, <em>all</em> of it will get synced to the remote host as
part of the <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> command.</p>

<p>The third line runs the install script remotely. Since <code class="language-plaintext highlighter-rouge">nix-copy-closure</code>
already copied over all possible dependencies of the service, the end result is
a systemd service running <em>exactly</em> as it would have if I were running it
locally.</p>

<p>All of this said, it’s clear that provisioning this remote host in the first
place was pretty simple:</p>

<ul>
  <li>Add my ssh key (done automatically by Vultr).</li>
  <li>Add my user to sudoers (done automatically by Vultr).</li>
  <li>Install single-user nix (two bash commands from
<a href="https://nixos.wiki/wiki/Nix_Installation_Guide#Stable_Nix">here</a>).</li>
</ul>

<p>And that’s literally it. No docker, no terraform, no kubernubernetes, no yaml
files… it all “just works”. Will it ever require manual intervention? Yeah,
probably… I haven’t defined uninstall or stop targets, for instance (though
that would be trivial to do). But overall, for a use-case like mine where I
don’t need a lot, I’m quite happy.</p>

<p>That’s pretty much the post. Hosting services at home isn’t very difficult to
begin with, and with this pattern those of us who use nix can do so with greater
reliability and confidence going forward.</p>"""

+++
<p>My home server has a lot running on it. Some of it I’ve written about in this
blog previously, some of it I haven’t. It’s hosting this blog itself, even!</p>

<p>With all of these services comes management overhead, both in terms of managing
packages and configuration. I’m pretty strict about tracking packages and
configuration in version control, and backing up all state I care about in B2,
such that if, <em>at any moment</em>, the server is abducted by aliens, I won’t have
lost much.</p>

<h2 id="docker">Docker</h2>

<p>Previously I accomplished this with docker. Each service ran in a container
under the docker daemon, with configuration files and state directories shared
in via volume shares. Configuration files could then be stored in a git repo,
and my <code class="language-plaintext highlighter-rouge">docker run</code> commands were documented in <code class="language-plaintext highlighter-rouge">Makefile</code>s, because that was
easy.</p>

<p>This approach had drawbacks, notably:</p>

<ul>
  <li>
    <p>Docker networking is a pain. To be fair I should have just used
<code class="language-plaintext highlighter-rouge">--network=host</code> and dodged the issue, but I didn’t.</p>
  </li>
  <li>
    <p>Docker images aren’t actually deterministically built, so if I were to ever
have to rebuild any of the images I was using it I couldn’t be sure I’d end up
with the same code as before. For some services this is actually a nagging
security concern in the back of my head.</p>
  </li>
  <li>
    <p>File permissions with docker volumes are fucked.</p>
  </li>
  <li>
    <p>Who knows how long the current version of docker will support the old ass
images and configuration system I’m using now. Probably not the next 10 years.
And what if dockerhub goes away, or changes its pricing model?</p>
  </li>
  <li>
    <p>As previously noted, docker is for boomers.</p>
  </li>
</ul>

<h2 id="nix">Nix</h2>

<p>Nix is the new hotness, and it solves all of the above problems quite nicely.
I’m not going to get into too much detail about how nix works here (honestly I’m
not very good at explaining it), but suffice to say I’m switching everything
over, and this post is about how that actually looks in a practical sense.</p>

<p>For the most part I eschew things like <a href="https://nixos.wiki/wiki/Flakes">flakes</a>,
<a href="https://github.com/nix-community/home-manager">home-manager</a>, and any other frameworks built on nix. While the
framework of the day may come and go, the base nix language should remain
constant.</p>

<p>As before with docker, I have a single git repo being stored privately in a way
I’m confident is secure (which is necessary because it contains some secrets).</p>

<p>At the root of the repo there exists a <code class="language-plaintext highlighter-rouge">pkgs.nix</code> file, which looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>{
  src ? builtins.fetchTarball {
    name = "nixpkgs-d50923ab2d308a1ddb21594ba6ae064cab65d8ae";
    url = "https://github.com/NixOS/nixpkgs/archive/d50923ab2d308a1ddb21594ba6ae064cab65d8ae.tar.gz";
    sha256 = "1k7xpymhzb4hilv6a1jp2lsxgc4yiqclh944m8sxyhriv9p2yhpv";
  },
}: (import src) {}
</code></pre></div></div>

<p>This file exists to provide a pinned version of <code class="language-plaintext highlighter-rouge">nixpkgs</code> which will get used
for all services. As long as I don’t change this file the tools available to me
for building my services will remain constant forever, no matter what else
happens in the nix ecosystem.</p>

<p>Each directory in the repo corresponds to a service I run. I’ll focus on a
particular service, <a href="https://github.com/navidrome/navidrome">navidrome</a>, for now:</p>

<div class="language-bash highlighter-rouge"><div class="highlight"><pre class="highlight"><code>:: <span class="nb">ls</span> <span class="nt">-1</span> navidrome
Makefile
default.nix
navidrome.toml
</code></pre></div></div>

<p>Not much to it!</p>

<h3 id="defaultnix">default.nix</h3>

<p>The first file to look at is the <code class="language-plaintext highlighter-rouge">default.nix</code>, as that contains
all the logic. The overall file looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>let

  pkgs = (import ../pkgs.nix) {};

in rec {

    entrypoint = ...;

    service = ...;

    install = ...;

}
</code></pre></div></div>

<p>The file describes an attribute set with three attributes, <code class="language-plaintext highlighter-rouge">entrypoint</code>,
<code class="language-plaintext highlighter-rouge">service</code>, and <code class="language-plaintext highlighter-rouge">install</code>. These form the basic pattern I use for all my
services; pretty much every service I manage has a <code class="language-plaintext highlighter-rouge">default.nix</code> which has
attributes corresponding to these.</p>

<h4 id="entrypoint">Entrypoint</h4>

<p>The first <code class="language-plaintext highlighter-rouge">entrypoint</code>, looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  entrypoint = pkgs.writeScript "mediocregopher-navidrome" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.navidrome}/bin/navidrome --configfile ${./navidrome.toml}
  '';
</code></pre></div></div>

<p>The goal here is to provide an executable which can be run directly, and which
will put together all necessary environment and configuration (<code class="language-plaintext highlighter-rouge">navidrome.toml</code>,
in this case) needed to run the service. Having the entrypoint split out into
its own target, as opposed to inlining it into the service file (defined next),
is convenient for testing; it allows you test <em>exactly</em> what’s going to happen
when running the service normally.</p>

<h4 id="service">Service</h4>

<p><code class="language-plaintext highlighter-rouge">service</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  service = pkgs.writeText "mediocregopher-navidrome-service" ''
    [Unit]
    Description=mediocregopher navidrome
    Requires=network.target
    After=network.target

    [Service]
    Restart=always
    RestartSec=1s
    User=mediocregopher
    Group=mediocregopher
    LimitNOFILE=10000

    # The important part!
    ExecStart=${entrypoint}

    # EXTRA DIRECTIVES ELIDED, SEE
    # https://www.navidrome.org/docs/installation/pre-built-binaries/

    [Install]
    WantedBy=multi-user.target
  '';
</code></pre></div></div>

<p>It’s function is to produce a systemd service file. The service file will
reference the <code class="language-plaintext highlighter-rouge">entrypoint</code> which has already been defined, and in general does
nothing else.</p>

<h4 id="install">Install</h4>

<p><code class="language-plaintext highlighter-rouge">install</code> looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>  install = pkgs.writeScript "mediocregopher-navidrome-install" ''
    #!${pkgs.bash}/bin/bash
    sudo cp ${service} /etc/systemd/system/mediocregopher-navidrome.service
    sudo systemctl daemon-reload
    sudo systemctl enable mediocregopher-navidrome
    sudo systemctl restart mediocregopher-navidrome
  '';
</code></pre></div></div>

<p>This attribute produces a script which will install a systemd service on the
system it’s run on. Assuming this is done in the context of a functional nix
environment and standard systemd installation it will “just work”; all relevant
binaries, configuration, etc, will all come along for the ride, and the service
will be running <em>exactly</em> what’s defined in my repo, everytime. Eat your heart
out, ansible!</p>

<p>Nix is usually used for building things, not <em>doing</em> things, so it may seem
unusual for this to be here. But there’s a very good reason for it, which I’ll
get to soon.</p>

<h3 id="makefile">Makefile</h3>

<p>While <code class="language-plaintext highlighter-rouge">default.nix</code> <em>could</em> exist alone, and I <em>could</em> just interact with it
directly using <code class="language-plaintext highlighter-rouge">nix-build</code> commands, I don’t like to do that. Most of the reason
is that I don’t want to have to <em>remember</em> the <code class="language-plaintext highlighter-rouge">nix-build</code> commands I need. So
in each directory there’s a <code class="language-plaintext highlighter-rouge">Makefile</code>, which acts as a kind of index of useful
commands. The one for navidrome looks like this:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>install:
	$$(nix-build -A install --no-out-link)
</code></pre></div></div>

<p>Yup, that’s it. It builds the <code class="language-plaintext highlighter-rouge">install</code> attribute, and runs the resulting script
inline. Easy peasy. Other services might have some other targets, like <code class="language-plaintext highlighter-rouge">init</code>,
which operate the same way but with different script targets.</p>

<h2 id="nix-remotely">Nix Remotely</h2>

<p>If you were waiting for me to explain <em>why</em> the install target is in
<code class="language-plaintext highlighter-rouge">default.nix</code>, rather than just being in the <code class="language-plaintext highlighter-rouge">Makefile</code> (which would also make
sense), this is the part where I do that.</p>

<p>My home server isn’t the only place where I host services, I also have a remote
host which runs some services. These services are defined in this same repo, in
essentially the same way as my local services. The only difference is in the
<code class="language-plaintext highlighter-rouge">Makefile</code>. Let’s look at an example from my <code class="language-plaintext highlighter-rouge">maddy/Makefile</code>:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>install-vultr:
	nix-build -A install --arg paramsFile ./vultr.nix
	nix-copy-closure -s ${VULTR} $$(readlink result)
	ssh -tt -q ${VULTR} $$(readlink result)
</code></pre></div></div>

<p>Vultr is the hosting company I’m renting the server from. Apparently I think I
will only ever have one host with them, because I just call it “vultr”.</p>

<p>I’ll go through this one line at a time. The first line is essentially the same
as the <code class="language-plaintext highlighter-rouge">install</code> line from my <code class="language-plaintext highlighter-rouge">navidrome</code> configuration, but with two small
differences: it takes in a parameters file containing the configuration
specific to the vultr host, and it’s only <em>building</em> the install script, not
running it.</p>

<p>The second line is the cool part. My remote host has a working nix environment
already, so I can just use <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> to copy the <code class="language-plaintext highlighter-rouge">install</code> script to
it. Since the <code class="language-plaintext highlighter-rouge">install</code> script references the service file, which in turn
references the <code class="language-plaintext highlighter-rouge">entrypoint</code>, which in turn references the service binary itself,
and all of its configuration, <em>all</em> of it will get synced to the remote host as
part of the <code class="language-plaintext highlighter-rouge">nix-copy-closure</code> command.</p>

<p>The third line runs the install script remotely. Since <code class="language-plaintext highlighter-rouge">nix-copy-closure</code>
already copied over all possible dependencies of the service, the end result is
a systemd service running <em>exactly</em> as it would have if I were running it
locally.</p>

<p>All of this said, it’s clear that provisioning this remote host in the first
place was pretty simple:</p>

<ul>
  <li>Add my ssh key (done automatically by Vultr).</li>
  <li>Add my user to sudoers (done automatically by Vultr).</li>
  <li>Install single-user nix (two bash commands from
<a href="https://nixos.wiki/wiki/Nix_Installation_Guide#Stable_Nix">here</a>).</li>
</ul>

<p>And that’s literally it. No docker, no terraform, no kubernubernetes, no yaml
files… it all “just works”. Will it ever require manual intervention? Yeah,
probably… I haven’t defined uninstall or stop targets, for instance (though
that would be trivial to do). But overall, for a use-case like mine where I
don’t need a lot, I’m quite happy.</p>

<p>That’s pretty much the post. Hosting services at home isn’t very difficult to
begin with, and with this pattern those of us who use nix can do so with greater
reliability and confidence going forward.</p>
