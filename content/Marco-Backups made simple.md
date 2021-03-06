
+++
title = "Backups made simple"
date = 2021-03-07T00:00:00.000Z
template = "html_content/raw.html"
summary = """
I've made a backup system I can be proud of, and I'd like to share it with you
today. It follows a p..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/backups-made-simple/"
raw = """
<p>I've made a backup system I can be proud of, and I'd like to share it with you
today. It follows a philosophy I've been fleshing out called <em>The
Functional Infra</em>. Concretely it aims to:</p>
<ul>
<li>Be pure. An output should only be a function of its inputs.</li>
<li>Be declarative and reproducible. A by product of being pure.</li>
<li>Support rollbacks. Also a by product of being pure.</li>
<li>Surface actionable errors. The corollary being it should be easy to understand
and observe what is happening.</li>
</ul>
<p>At a high level, the backup system works like so:</p>
<ol>
<li>ZFS creates automatic snapshots every so often.</li>
<li>Those snapshots are replicated to an EBS-backed EC2 instance that is only
alive while backup replication is happening. Taking advantage of ZFS'
incremental snapshot to make replication generally quite fast.</li>
<li>The EBS drive itself stays around after the instance is terminated. This
drive is a Cold HDD (sc1) which costs about $0.015 gb/month.</li>
</ol>
<h2 id="zfs">ZFS</h2>
<p>To be honest I haven't used ZFS all that much, but that's kind of my point. I,
as a non-expert in ZFS, have been able to get a lot out of it just by
following the straightforward documentation. It seems like the API is well
thought out and the semantics are reasonable. For example, a consistent snapshot
is as easy as doing <code>zfs snapshot tank/home/marco@friday</code>.</p>
<h3 id="automatic-snapshots">Automatic snapshots</h3>
<p>On NixOS setting up automatic snapshots is a breeze, just add the following to
your NixOS Configuration:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">services</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">zfs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">autoSnapshot</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>and setting the <code>com.sun:auto-snapshot</code> option on the filesystem. E.g.: <code>zfs set com.sun:auto-snapshot=true &lt;pool&gt;/&lt;fs&gt;</code>. Note that this can also be done on
creation of the filesystem: <code>zfs create -o mountpoint=legacy -o com.sun:auto-snapshot=true tank/home</code>.</p>
<p>With that enabled, ZFS will keep a snapshot for the latest 4 15-minute, 24
hourly, 7 daily, 4 weekly and 12 monthly snapshots.</p>
<h3 id="on-demand-ec2-instance-for-backups">On Demand EC2 Instance for Backups</h3>
<p>Now that we've demonstrated how to setup snapshotting, we need to tackle the
problem of replicating those snapshots somewhere so we can have real backups.
For that I use one of my favorite little tools:
<a href="https://github.com/stephank/lazyssh">lazyssh</a>. Its humble description betrays
little information at its true usefulness. The description is simply:
<em>A jump-host SSH server that starts machines on-demand</em>. What it enables is
pretty magical. It essentially lets you run arbitrary code when something SSHs
through the jump-host.</p>
<p>Let's take the classic ZFS replication example from the
<a href="https://docs.oracle.com/cd/E18752_01/html/819-5461/gbchx.html">docs</a>:
<code>host1# zfs send tank/dana@snap1 | ssh host2 zfs recv newtank/dana</code>. This
command copies a snapshot from a machine named <code>host1</code> to another machine named
<code>host2</code> over SSH. Simple and secure backups. But it relies on <code>host2</code> being
available. With <code>lazyssh</code> we can make <code>host2</code> only exist when needed.
<code>host2</code> would start when the ssh command is invoked and terminated when the ssh
command finishes. The command with <code>lazyssh</code> would look something like this
(assuming you have a <code>lazyssh</code> target in your <code>.ssh/config</code> as explained in the
<a href="https://github.com/stephank/lazyssh">docs</a>):</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">host1# zfs send tank/dana@snap1 | ssh -J lazyssh host2 zfs recv newtank/dana
</span></code></pre>
<p>Note the only difference is the <code>-J lazyssh</code>.</p>
<p>So how do we actually setup <code>lazyssh</code> to do this? Here is my configuration:</p>
<div >
    <script src="https:&#x2F;&#x2F;gist.github.com&#x2F;MarcoPolo&#x2F;13462e986711f62bfc6b7b8e494c5cc8.js"></script>
</div>
<p>Note there are a couple of setup steps:</p>
<ol>
<li>Create the initial sc1 EBS Drive. I did this in the AWS Console, but you
could do this in Terraform or the AWS CLI.</li>
<li>Create the ZFS pool on the drive. I launched my lazy archiver without the ZFS
filesystem option and ran: <code>zpool create -o ashift=12 -O mountpoint=none POOL_NAME /dev/DRIVE_LOCATION</code>. Then I created the
<code>POOL_NAME/backup</code> dataset with <code>zfs create -o acltype=posixacl -o xattr=sa -o mountpoint=legacy POOL_NAME/backup</code>.</li>
</ol>
<p>As a quality of life and security improvement I setup
<a href="https://github.com/nix-community/home-manager">homemanager</a> to manage my SSH
config and known_hosts file so these are automatically correct and properly
setup. I generate the lines for known_hosts when I generate the host keys
that go in the <code>user_data</code> field in the <code>lazsyssh-config.hcl</code> above. Here's the
relevant section from my homemanager config:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">programs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">ssh </span><span style="color:#c0c5ce;">= {
    </span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;

    </span><span style="color:#65737e;"># I keep this file tracked in Git alongside my NixOS configs.
    </span><span style="color:#d08770;">userKnownHostsFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">/path/to/known_hosts</span><span style="color:#c0c5ce;">&quot;;
    </span><span style="color:#d08770;">matchBlocks </span><span style="color:#c0c5ce;">= {
      &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot; = {
        </span><span style="color:#d08770;">user </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">hostname </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">proxyJump </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">lazyssh</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identityFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_AWS_KEYPAIR</span><span style="color:#c0c5ce;">&quot;;
      };

      &quot;</span><span style="color:#a3be8c;">lazyssh</span><span style="color:#c0c5ce;">&quot; = {
        </span><span style="color:#65737e;"># This assume you are running lazyssh locally, but it can also
        # reference another machine.
        </span><span style="color:#d08770;">hostname </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">localhost</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">port </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">7922</span><span style="color:#c0c5ce;">;
        </span><span style="color:#d08770;">user </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">jump</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identityFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_LAZYSSH_CLIENT_KEY</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identitiesOnly </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
        </span><span style="color:#d08770;">extraOptions </span><span style="color:#c0c5ce;">= {
          &quot;</span><span style="color:#a3be8c;">PreferredAuthentications</span><span style="color:#c0c5ce;">&quot; = &quot;</span><span style="color:#a3be8c;">publickey</span><span style="color:#c0c5ce;">&quot;;
        };
      };
    };
  };
}
</span></code></pre>
<p>Finally, I use the provided NixOS Module for <code>lazyssh</code> to manage starting it and
keeping it up. Here's the relevant parts from my <code>flake.nix</code>:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  # My fork that supports placements and terminating instances after failing to
  # attach volume.
  inputs.lazyssh.url = &quot;github:marcopolo/lazyssh/attach-volumes&quot;;
  inputs.lazyssh.inputs.nixpkgs.follows = &quot;nixpkgs&quot;;

    outputs =
    { self
    , nixpkgs
    , lazyssh
    }: {
      nixosConfigurations = {

        nixMachineHostName = nixpkgs.lib.nixosSystem {
          system = &quot;x86_64-linux&quot;;
          modules = [
              {
                imports = [lazyssh.nixosModule]
                services.lazyssh.configFile =
                  &quot;/path/to/lazyssh-config.hcl&quot;;
                # You&#39;ll need to add the correct AWS credentials to `/home/lazyssh/.aws`
                # This could probably be a symlink with home-manager to a
                # managed file somewhere else, but I haven&#39;t go down that path
                # yet
                users.users.lazyssh = {
                  isNormalUser = true;
                  createHome = true;
                };
              }
          ];
        };
      };
    }
}
</span></code></pre>
<p>With all that setup, I can ssh into the archiver by simple running <code>ssh archiver</code>. Under the hood, <code>lazyssh</code> starts the EC2 instance and attaches the
EBS drive to it. And since <code>ssh archiver</code> works, so does the original example
of: <code>zfs send tank/dana@snap1 | ssh archiver zfs recv newtank/dana</code>.</p>
<h2 id="automatic-replication">Automatic Replication</h2>
<p>The next part of the puzzle is to have backups happen automatically. There are
various tools you can use for this. Even a simple cron that runs the <code>send/recv</code>
on a schedule. I opted to go for what NixOS supports out of the box, which is
<a href="https://github.com/alunduil/zfs-replicate">https://github.com/alunduil/zfs-replicate</a>.
Unfortunately, I ran into a couple issues that led me to make a fork. Namely:</p>
<ol>
<li>Using <code>/usr/bin/env - ssh</code> fails to use the ssh config file. My fork supports
specifying a custom ssh binary to use.</li>
<li>Support for <code>ExecStartPre</code>. This is to &quot;warm up&quot; the archiver instance. I run
<code>nixos-rebuild switch</code> which is basically a no-op if there is no changes to
apply from the configuration file, or blocks until the changes have been
applied. In my case these are usually the changes inside the UserData field.</li>
<li>Support for <code>ExecStopPost</code>. This is to add observability to this process.</li>
<li>I wanted to raise the systemd timeout limit. In case the <code>ExecStartPre</code> takes
a while to warm-up the instance.</li>
</ol>
<p>Thankfully with flakes, using my own fork was painless. Here's the relevant
section from my <code>flake.nix</code> file:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">  </span><span style="color:#65737e;"># inputs.zfs-replicate.url = &quot;github:marcopolo/zfs-replicate/flake&quot;;
  # ...
  # Inside nixosSystem modules...
  </span><span style="color:#c0c5ce;">(</span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">pkgs, ... </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    {
      </span><span style="color:#d08770;">imports </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">zfs-replicate</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">nixosModule </span><span style="color:#c0c5ce;">];
      </span><span style="color:#65737e;"># Disable the existing module
      </span><span style="color:#d08770;">disabledModules </span><span style="color:#c0c5ce;">= [ &quot;</span><span style="color:#a3be8c;">services/backup/zfs-replication.nix</span><span style="color:#c0c5ce;">&quot; ];

      </span><span style="color:#d08770;">services</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">zfs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">autoReplication </span><span style="color:#c0c5ce;">=
        </span><span style="color:#b48ead;">let
          </span><span style="color:#d08770;">host </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">sshPath </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">openssh</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/ssh</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#65737e;"># Make sure the machine is up-to-date
          </span><span style="color:#d08770;">execStartPre </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">sshPath</span><span style="font-style:italic;color:#ab7967;">} ${</span><span style="font-style:italic;color:#bf616a;">host</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;"> nixos-rebuild switch</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">honeycombAPIKey </span><span style="color:#c0c5ce;">= (</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">./secrets.nix</span><span style="color:#c0c5ce;">).</span><span style="color:#bf616a;">honeycomb_api_key</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">honeycombCommand </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">writeScriptBin </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">reportResult</span><span style="color:#c0c5ce;">&quot; &#39;&#39;</span><span style="color:#a3be8c;">
            #!/usr/bin/env </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">bash</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/bash
            </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">curl</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/curl https://api.honeycomb.io/1/events/zfs-replication -X POST \\
              -H &quot;X-Honeycomb-Team: </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">honeycombAPIKey</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">&quot; \\
              -H &quot;X-Honeycomb-Event-Time: $(</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">coreutils</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/date -u +&quot;%Y-%m-%dT%H:%M:%SZ&quot;)&quot; \\
              -d &quot;{\\&quot;serviceResult\\&quot;:\\&quot;$SERVICE_RESULT\\&quot;, \\&quot;exitCode\\&quot;: \\&quot;$EXIT_CODE\\&quot;, \\&quot;exitStatus\\&quot;: \\&quot;$EXIT_STATUS\\&quot;}&quot;
          </span><span style="color:#c0c5ce;">&#39;&#39;;
          </span><span style="color:#d08770;">execStopPost </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">honeycombCommand</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/reportResult</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#b48ead;">in
        </span><span style="color:#c0c5ce;">{
          </span><span style="color:#b48ead;">inherit </span><span style="color:#d08770;">execStartPre execStopPost host sshPath</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">timeout </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">90000</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">username </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">localFilesystem </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">rpool/safe</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">remoteFilesystem </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">rpool/backup</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">identityFilePath </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_AWS_KEY_PAIR</span><span style="color:#c0c5ce;">&quot;;
        };
    })
</span></code></pre>
<p>That sets up a systemd service that runs after every snapshot. It also
reports the result of the replication to
<a href="https://www.honeycomb.io/">Honeycomb</a>, which brings us to our next
section...</p>
<h2 id="observability">Observability</h2>
<p>The crux of any automated process is it failing silently. This is especially bad
in the context of backups, since you don't need them until you do. I solved this
by reporting the result of the replication to Honeycomb after every run. It
reports the <code>$SERVICE_RESULT</code>, <code>$EXIT_CODE</code> and <code>$EXIT_STATUS</code> as returned by
systemd. I then create an alert that fires if there are no successful runs in
the past hour.</p>
<h2 id="future-work">Future Work</h2>
<p>While I like this system for being simple, I think there is a bit more work in
making it pure. For one, there should be no more than 1 manual step for setup,
and 1 manual step for tear down. There should also be a similar simplicity in
upgrading/downgrading storage space.</p>
<p>For reliability, the archiver instance should scrub its drive on a schedule.
This isn't setup yet.</p>
<p>At $0.015 gb/month this is relatively cheap, but not the cheapest. According to
<a href="https://filstats.com/">filstats</a> I could use
<a href="https://www.filecoin.com/">Filecoin</a> to store data for much less. There's no
Block Device interface to this yet, so it wouldn't be as simple as ZFS
<code>send/recv</code>. You'd lose the benefits of incremental snapshots. But it may be
possible to build a block device interface on top. Maybe with an <a href="https://en.wikipedia.org/wiki/Network_block_device">nbd-server</a>?</p>
<h2 id="extra">Extra</h2>
<p>Bits and pieces that may be helpful if you try setting something similar up.</p>
<h3 id="setting-host-key-and-nix-configuration-with-userdata">Setting host key and Nix Configuration with UserData</h3>
<p>NixOS on AWS has this undocumented nifty feature of setting the ssh host
key and a new <code>configuration.nix</code> file straight from the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_UserData.html">UserData
field</a>.
This lets you one, be sure that your SSH connection isn't being
<a href="https://en.wikipedia.org/wiki/Man-in-the-middle_attack">MITM</a>, and two, configure
the machine in a simple way. I use this feature to set the SSH host key and set
the machine up with ZFS and the the <code>lz4</code> compression package.</p>
<h3 id="questions-comments">Questions? Comments?</h3>
<p>Email me if you set this system up. This is purposely not a tutorial, so you may
hit snags. If you think something could be clearer feel free to make an
<a href="https://github.com/marcopolo/marcopolo.github.io">edit</a>.</p>
"""

+++
<p>I've made a backup system I can be proud of, and I'd like to share it with you
today. It follows a philosophy I've been fleshing out called <em>The
Functional Infra</em>. Concretely it aims to:</p>
<ul>
<li>Be pure. An output should only be a function of its inputs.</li>
<li>Be declarative and reproducible. A by product of being pure.</li>
<li>Support rollbacks. Also a by product of being pure.</li>
<li>Surface actionable errors. The corollary being it should be easy to understand
and observe what is happening.</li>
</ul>
<p>At a high level, the backup system works like so:</p>
<ol>
<li>ZFS creates automatic snapshots every so often.</li>
<li>Those snapshots are replicated to an EBS-backed EC2 instance that is only
alive while backup replication is happening. Taking advantage of ZFS'
incremental snapshot to make replication generally quite fast.</li>
<li>The EBS drive itself stays around after the instance is terminated. This
drive is a Cold HDD (sc1) which costs about $0.015 gb/month.</li>
</ol>
<h2 id="zfs">ZFS</h2>
<p>To be honest I haven't used ZFS all that much, but that's kind of my point. I,
as a non-expert in ZFS, have been able to get a lot out of it just by
following the straightforward documentation. It seems like the API is well
thought out and the semantics are reasonable. For example, a consistent snapshot
is as easy as doing <code>zfs snapshot tank/home/marco@friday</code>.</p>
<h3 id="automatic-snapshots">Automatic snapshots</h3>
<p>On NixOS setting up automatic snapshots is a breeze, just add the following to
your NixOS Configuration:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">services</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">zfs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">autoSnapshot</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
}
</span></code></pre>
<p>and setting the <code>com.sun:auto-snapshot</code> option on the filesystem. E.g.: <code>zfs set com.sun:auto-snapshot=true &lt;pool&gt;/&lt;fs&gt;</code>. Note that this can also be done on
creation of the filesystem: <code>zfs create -o mountpoint=legacy -o com.sun:auto-snapshot=true tank/home</code>.</p>
<p>With that enabled, ZFS will keep a snapshot for the latest 4 15-minute, 24
hourly, 7 daily, 4 weekly and 12 monthly snapshots.</p>
<h3 id="on-demand-ec2-instance-for-backups">On Demand EC2 Instance for Backups</h3>
<p>Now that we've demonstrated how to setup snapshotting, we need to tackle the
problem of replicating those snapshots somewhere so we can have real backups.
For that I use one of my favorite little tools:
<a href="https://github.com/stephank/lazyssh">lazyssh</a>. Its humble description betrays
little information at its true usefulness. The description is simply:
<em>A jump-host SSH server that starts machines on-demand</em>. What it enables is
pretty magical. It essentially lets you run arbitrary code when something SSHs
through the jump-host.</p>
<p>Let's take the classic ZFS replication example from the
<a href="https://docs.oracle.com/cd/E18752_01/html/819-5461/gbchx.html">docs</a>:
<code>host1# zfs send tank/dana@snap1 | ssh host2 zfs recv newtank/dana</code>. This
command copies a snapshot from a machine named <code>host1</code> to another machine named
<code>host2</code> over SSH. Simple and secure backups. But it relies on <code>host2</code> being
available. With <code>lazyssh</code> we can make <code>host2</code> only exist when needed.
<code>host2</code> would start when the ssh command is invoked and terminated when the ssh
command finishes. The command with <code>lazyssh</code> would look something like this
(assuming you have a <code>lazyssh</code> target in your <code>.ssh/config</code> as explained in the
<a href="https://github.com/stephank/lazyssh">docs</a>):</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">host1# zfs send tank/dana@snap1 | ssh -J lazyssh host2 zfs recv newtank/dana
</span></code></pre>
<p>Note the only difference is the <code>-J lazyssh</code>.</p>
<p>So how do we actually setup <code>lazyssh</code> to do this? Here is my configuration:</p>
<div >
    <script src="https:&#x2F;&#x2F;gist.github.com&#x2F;MarcoPolo&#x2F;13462e986711f62bfc6b7b8e494c5cc8.js"></script>
</div>
<p>Note there are a couple of setup steps:</p>
<ol>
<li>Create the initial sc1 EBS Drive. I did this in the AWS Console, but you
could do this in Terraform or the AWS CLI.</li>
<li>Create the ZFS pool on the drive. I launched my lazy archiver without the ZFS
filesystem option and ran: <code>zpool create -o ashift=12 -O mountpoint=none POOL_NAME /dev/DRIVE_LOCATION</code>. Then I created the
<code>POOL_NAME/backup</code> dataset with <code>zfs create -o acltype=posixacl -o xattr=sa -o mountpoint=legacy POOL_NAME/backup</code>.</li>
</ol>
<p>As a quality of life and security improvement I setup
<a href="https://github.com/nix-community/home-manager">homemanager</a> to manage my SSH
config and known_hosts file so these are automatically correct and properly
setup. I generate the lines for known_hosts when I generate the host keys
that go in the <code>user_data</code> field in the <code>lazsyssh-config.hcl</code> above. Here's the
relevant section from my homemanager config:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  </span><span style="color:#d08770;">programs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">ssh </span><span style="color:#c0c5ce;">= {
    </span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;

    </span><span style="color:#65737e;"># I keep this file tracked in Git alongside my NixOS configs.
    </span><span style="color:#d08770;">userKnownHostsFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">/path/to/known_hosts</span><span style="color:#c0c5ce;">&quot;;
    </span><span style="color:#d08770;">matchBlocks </span><span style="color:#c0c5ce;">= {
      &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot; = {
        </span><span style="color:#d08770;">user </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">hostname </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">proxyJump </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">lazyssh</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identityFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_AWS_KEYPAIR</span><span style="color:#c0c5ce;">&quot;;
      };

      &quot;</span><span style="color:#a3be8c;">lazyssh</span><span style="color:#c0c5ce;">&quot; = {
        </span><span style="color:#65737e;"># This assume you are running lazyssh locally, but it can also
        # reference another machine.
        </span><span style="color:#d08770;">hostname </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">localhost</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">port </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">7922</span><span style="color:#c0c5ce;">;
        </span><span style="color:#d08770;">user </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">jump</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identityFile </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_LAZYSSH_CLIENT_KEY</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#d08770;">identitiesOnly </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
        </span><span style="color:#d08770;">extraOptions </span><span style="color:#c0c5ce;">= {
          &quot;</span><span style="color:#a3be8c;">PreferredAuthentications</span><span style="color:#c0c5ce;">&quot; = &quot;</span><span style="color:#a3be8c;">publickey</span><span style="color:#c0c5ce;">&quot;;
        };
      };
    };
  };
}
</span></code></pre>
<p>Finally, I use the provided NixOS Module for <code>lazyssh</code> to manage starting it and
keeping it up. Here's the relevant parts from my <code>flake.nix</code>:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">{
  # My fork that supports placements and terminating instances after failing to
  # attach volume.
  inputs.lazyssh.url = &quot;github:marcopolo/lazyssh/attach-volumes&quot;;
  inputs.lazyssh.inputs.nixpkgs.follows = &quot;nixpkgs&quot;;

    outputs =
    { self
    , nixpkgs
    , lazyssh
    }: {
      nixosConfigurations = {

        nixMachineHostName = nixpkgs.lib.nixosSystem {
          system = &quot;x86_64-linux&quot;;
          modules = [
              {
                imports = [lazyssh.nixosModule]
                services.lazyssh.configFile =
                  &quot;/path/to/lazyssh-config.hcl&quot;;
                # You&#39;ll need to add the correct AWS credentials to `/home/lazyssh/.aws`
                # This could probably be a symlink with home-manager to a
                # managed file somewhere else, but I haven&#39;t go down that path
                # yet
                users.users.lazyssh = {
                  isNormalUser = true;
                  createHome = true;
                };
              }
          ];
        };
      };
    }
}
</span></code></pre>
<p>With all that setup, I can ssh into the archiver by simple running <code>ssh archiver</code>. Under the hood, <code>lazyssh</code> starts the EC2 instance and attaches the
EBS drive to it. And since <code>ssh archiver</code> works, so does the original example
of: <code>zfs send tank/dana@snap1 | ssh archiver zfs recv newtank/dana</code>.</p>
<h2 id="automatic-replication">Automatic Replication</h2>
<p>The next part of the puzzle is to have backups happen automatically. There are
various tools you can use for this. Even a simple cron that runs the <code>send/recv</code>
on a schedule. I opted to go for what NixOS supports out of the box, which is
<a href="https://github.com/alunduil/zfs-replicate">https://github.com/alunduil/zfs-replicate</a>.
Unfortunately, I ran into a couple issues that led me to make a fork. Namely:</p>
<ol>
<li>Using <code>/usr/bin/env - ssh</code> fails to use the ssh config file. My fork supports
specifying a custom ssh binary to use.</li>
<li>Support for <code>ExecStartPre</code>. This is to &quot;warm up&quot; the archiver instance. I run
<code>nixos-rebuild switch</code> which is basically a no-op if there is no changes to
apply from the configuration file, or blocks until the changes have been
applied. In my case these are usually the changes inside the UserData field.</li>
<li>Support for <code>ExecStopPost</code>. This is to add observability to this process.</li>
<li>I wanted to raise the systemd timeout limit. In case the <code>ExecStartPre</code> takes
a while to warm-up the instance.</li>
</ol>
<p>Thankfully with flakes, using my own fork was painless. Here's the relevant
section from my <code>flake.nix</code> file:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">  </span><span style="color:#65737e;"># inputs.zfs-replicate.url = &quot;github:marcopolo/zfs-replicate/flake&quot;;
  # ...
  # Inside nixosSystem modules...
  </span><span style="color:#c0c5ce;">(</span><span style="color:#8fa1b3;">{ </span><span style="color:#c0c5ce;">pkgs, ... </span><span style="color:#8fa1b3;">}</span><span style="color:#c0c5ce;">:
    {
      </span><span style="color:#d08770;">imports </span><span style="color:#c0c5ce;">= [ </span><span style="color:#bf616a;">zfs-replicate</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">nixosModule </span><span style="color:#c0c5ce;">];
      </span><span style="color:#65737e;"># Disable the existing module
      </span><span style="color:#d08770;">disabledModules </span><span style="color:#c0c5ce;">= [ &quot;</span><span style="color:#a3be8c;">services/backup/zfs-replication.nix</span><span style="color:#c0c5ce;">&quot; ];

      </span><span style="color:#d08770;">services</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">zfs</span><span style="color:#c0c5ce;">.</span><span style="color:#d08770;">autoReplication </span><span style="color:#c0c5ce;">=
        </span><span style="color:#b48ead;">let
          </span><span style="color:#d08770;">host </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">archiver</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">sshPath </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">openssh</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/ssh</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#65737e;"># Make sure the machine is up-to-date
          </span><span style="color:#d08770;">execStartPre </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">sshPath</span><span style="font-style:italic;color:#ab7967;">} ${</span><span style="font-style:italic;color:#bf616a;">host</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;"> nixos-rebuild switch</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">honeycombAPIKey </span><span style="color:#c0c5ce;">= (</span><span style="color:#96b5b4;">import </span><span style="color:#a3be8c;">./secrets.nix</span><span style="color:#c0c5ce;">).</span><span style="color:#bf616a;">honeycomb_api_key</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">honeycombCommand </span><span style="color:#c0c5ce;">= </span><span style="color:#bf616a;">pkgs</span><span style="color:#c0c5ce;">.</span><span style="color:#bf616a;">writeScriptBin </span><span style="color:#c0c5ce;">&quot;</span><span style="color:#a3be8c;">reportResult</span><span style="color:#c0c5ce;">&quot; &#39;&#39;</span><span style="color:#a3be8c;">
            #!/usr/bin/env </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">bash</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/bash
            </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">curl</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/curl https://api.honeycomb.io/1/events/zfs-replication -X POST \
              -H &quot;X-Honeycomb-Team: </span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">honeycombAPIKey</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">&quot; \
              -H &quot;X-Honeycomb-Event-Time: $(</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">pkgs</span><span style="font-style:italic;color:#c0c5ce;">.</span><span style="font-style:italic;color:#bf616a;">coreutils</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/date -u +&quot;%Y-%m-%dT%H:%M:%SZ&quot;)&quot; \
              -d &quot;{\&quot;serviceResult\&quot;:\&quot;$SERVICE_RESULT\&quot;, \&quot;exitCode\&quot;: \&quot;$EXIT_CODE\&quot;, \&quot;exitStatus\&quot;: \&quot;$EXIT_STATUS\&quot;}&quot;
          </span><span style="color:#c0c5ce;">&#39;&#39;;
          </span><span style="color:#d08770;">execStopPost </span><span style="color:#c0c5ce;">= &quot;</span><span style="font-style:italic;color:#ab7967;">${</span><span style="font-style:italic;color:#bf616a;">honeycombCommand</span><span style="font-style:italic;color:#ab7967;">}</span><span style="color:#a3be8c;">/bin/reportResult</span><span style="color:#c0c5ce;">&quot;;
        </span><span style="color:#b48ead;">in
        </span><span style="color:#c0c5ce;">{
          </span><span style="color:#b48ead;">inherit </span><span style="color:#d08770;">execStartPre execStopPost host sshPath</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">enable </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">true</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">timeout </span><span style="color:#c0c5ce;">= </span><span style="color:#d08770;">90000</span><span style="color:#c0c5ce;">;
          </span><span style="color:#d08770;">username </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">root</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">localFilesystem </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">rpool/safe</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">remoteFilesystem </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">rpool/backup</span><span style="color:#c0c5ce;">&quot;;
          </span><span style="color:#d08770;">identityFilePath </span><span style="color:#c0c5ce;">= &quot;</span><span style="color:#a3be8c;">PATH_TO_AWS_KEY_PAIR</span><span style="color:#c0c5ce;">&quot;;
        };
    })
</span></code></pre>
<p>That sets up a systemd service that runs after every snapshot. It also
reports the result of the replication to
<a href="https://www.honeycomb.io/">Honeycomb</a>, which brings us to our next
section...</p>
<h2 id="observability">Observability</h2>
<p>The crux of any automated process is it failing silently. This is especially bad
in the context of backups, since you don't need them until you do. I solved this
by reporting the result of the replication to Honeycomb after every run. It
reports the <code>$SERVICE_RESULT</code>, <code>$EXIT_CODE</code> and <code>$EXIT_STATUS</code> as returned by
systemd. I then create an alert that fires if there are no successful runs in
the past hour.</p>
<h2 id="future-work">Future Work</h2>
<p>While I like this system for being simple, I think there is a bit more work in
making it pure. For one, there should be no more than 1 manual step for setup,
and 1 manual step for tear down. There should also be a similar simplicity in
upgrading/downgrading storage space.</p>
<p>For reliability, the archiver instance should scrub its drive on a schedule.
This isn't setup yet.</p>
<p>At $0.015 gb/month this is relatively cheap, but not the cheapest. According to
<a href="https://filstats.com/">filstats</a> I could use
<a href="https://www.filecoin.com/">Filecoin</a> to store data for much less. There's no
Block Device interface to this yet, so it wouldn't be as simple as ZFS
<code>send/recv</code>. You'd lose the benefits of incremental snapshots. But it may be
possible to build a block device interface on top. Maybe with an <a href="https://en.wikipedia.org/wiki/Network_block_device">nbd-server</a>?</p>
<h2 id="extra">Extra</h2>
<p>Bits and pieces that may be helpful if you try setting something similar up.</p>
<h3 id="setting-host-key-and-nix-configuration-with-userdata">Setting host key and Nix Configuration with UserData</h3>
<p>NixOS on AWS has this undocumented nifty feature of setting the ssh host
key and a new <code>configuration.nix</code> file straight from the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_UserData.html">UserData
field</a>.
This lets you one, be sure that your SSH connection isn't being
<a href="https://en.wikipedia.org/wiki/Man-in-the-middle_attack">MITM</a>, and two, configure
the machine in a simple way. I use this feature to set the SSH host key and set
the machine up with ZFS and the the <code>lz4</code> compression package.</p>
<h3 id="questions-comments">Questions? Comments?</h3>
<p>Email me if you set this system up. This is purposely not a tutorial, so you may
hit snags. If you think something could be clearer feel free to make an
<a href="https://github.com/marcopolo/marcopolo.github.io">edit</a>.</p>

