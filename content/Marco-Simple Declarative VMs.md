
+++
title = "Simple Declarative VMs"
date = 2021-03-07T00:00:00.000Z
template = "html_content/raw.html"
summary = """
I've been on a hunt to find a simple and declarative way to define VMs. I wanted
something like NixO..."""

[extra]
author = "Marco"
originalLink = "https://marcopolo.io/code/simple-vms/"
raw = """
<p>I've been on a hunt to find a simple and declarative way to define VMs. I wanted
something like <a href="https://nixos.org/manual/nixos/stable/#ch-containers">NixOS
Containers</a>, but with a
stronger security guarantee. I wanted to be able to use a Nix expression to
define what the VM should look like, then reference that on my Server's
expression and have it all work automatically. I didn't want to manually
run any commands. The hunt is over, I finally found it.</p>
<h2 id="my-use-case">My Use Case</h2>
<p>I want a machine that I can permanently hook up to a WireGuard VPN and treat
as if it were in a remote place. At first I did this with a physical machine,
but I didn't want to commit the whole machine's compute for a novelty. What I
really want is a small VM that is permanently hooked up to a WireGuard VPN.
Minimal investment with all the upsides.</p>
<h2 id="nixos-qemu">NixOS QEMU</h2>
<p>Nix OS supports building your system in a QEMU runnable environment right out of
the box. <code>nixos-rebuild build-vm</code> is a wrapper over <code>nix build github:marcopolo/marcopolo.github.io#nixosConfigurations.small-vm.config.system.build.vm</code>. (Side note, with
flakes you can build this exact VM by running that command<sup class="footnote-reference"><a href="#1">1</a></sup>). This means NixOS
already did the hard work of turning a NixOS configuration into a valid VM that
can be launched with QEMU. Not only that, but the VM shares the <code>/nix/store</code>
with the host. This results in a really small VM (disk size is 5MB).</p>
<p>NixOS does the heavy lifting of converting a configuration into a script that
will run a VM, so all I need to do is write a service that manages this process.
Enter <a href="https://github.com/MarcoPolo/simple-vms/">simple-vms</a>, heavily inspired by
<a href="https://github.com/Nekroze/vms.nix">vms.nix</a> and
<a href="https://github.com/Mic92/nixos-shell">nixos-shell</a>. <a href="https://github.com/MarcoPolo/simple-vms/">simple-vms</a> is a NixOS
module that takes in a reference to the
<code>nixosConfigurations.small-vm.config.system.build.vm</code> derivation and the
option of whether you want state to be persisted, and defines a Systemd
service for the vm (There can be multiple VMs). This really is a simple
module, the NixOS service definition is about 10 lines long, and its
<code>ExecStart</code> is simply:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">mkdir -p /var/lib/simple-vms/${name}
cd /var/lib/simple-vms/${name}
exec ${cfg.vm.out}/bin/run-nixos-vm;
</span></code></pre>
<p>With this service we can get and keep our VMs up and running.</p>
<h2 id="stateless-vms">Stateless VMs</h2>
<p>I got a sticker recently that said &quot;You either have one source of truth, of
multiple sources of lies.&quot; To that end, I wanted to make my VM completely
stateless. QEMU lets you mount folders into the VM, so I used that to mount host
folders in the VM's <code>/etc/wireguard</code> and <code>/etc/ssh</code> so that the host can
provide the VM with WireGuard keys, and the VM can persist it's SSH host keys.</p>
<p>That's all the VM really needs. Every time my VM shuts down I delete the drive.
And just to be safe, I try deleting any drive on boot too.</p>
<p>If you're running a service on the VM, you'll likely want to persist that
service's state files too in a similar way.</p>
<h2 id="fin">Fin</h2>
<p>That's it. Just a small post for a neat little trick. If you set this up let
me know! I'm interested in hearing your use case.</p>
<h3 id="footnotes">Footnotes</h3>
<div class="footnote-definition" id="1"><sup class="footnote-definition-label">1</sup>
<p>User/pass = root/root. Exit qemu with C-a x.</p>
</div>
"""

+++
<p>I've been on a hunt to find a simple and declarative way to define VMs. I wanted
something like <a href="https://nixos.org/manual/nixos/stable/#ch-containers">NixOS
Containers</a>, but with a
stronger security guarantee. I wanted to be able to use a Nix expression to
define what the VM should look like, then reference that on my Server's
expression and have it all work automatically. I didn't want to manually
run any commands. The hunt is over, I finally found it.</p>
<h2 id="my-use-case">My Use Case</h2>
<p>I want a machine that I can permanently hook up to a WireGuard VPN and treat
as if it were in a remote place. At first I did this with a physical machine,
but I didn't want to commit the whole machine's compute for a novelty. What I
really want is a small VM that is permanently hooked up to a WireGuard VPN.
Minimal investment with all the upsides.</p>
<h2 id="nixos-qemu">NixOS QEMU</h2>
<p>Nix OS supports building your system in a QEMU runnable environment right out of
the box. <code>nixos-rebuild build-vm</code> is a wrapper over <code>nix build github:marcopolo/marcopolo.github.io#nixosConfigurations.small-vm.config.system.build.vm</code>. (Side note, with
flakes you can build this exact VM by running that command<sup class="footnote-reference"><a href="#1">1</a></sup>). This means NixOS
already did the hard work of turning a NixOS configuration into a valid VM that
can be launched with QEMU. Not only that, but the VM shares the <code>/nix/store</code>
with the host. This results in a really small VM (disk size is 5MB).</p>
<p>NixOS does the heavy lifting of converting a configuration into a script that
will run a VM, so all I need to do is write a service that manages this process.
Enter <a href="https://github.com/MarcoPolo/simple-vms/">simple-vms</a>, heavily inspired by
<a href="https://github.com/Nekroze/vms.nix">vms.nix</a> and
<a href="https://github.com/Mic92/nixos-shell">nixos-shell</a>. <a href="https://github.com/MarcoPolo/simple-vms/">simple-vms</a> is a NixOS
module that takes in a reference to the
<code>nixosConfigurations.small-vm.config.system.build.vm</code> derivation and the
option of whether you want state to be persisted, and defines a Systemd
service for the vm (There can be multiple VMs). This really is a simple
module, the NixOS service definition is about 10 lines long, and its
<code>ExecStart</code> is simply:</p>
<pre style="background-color:#2b303b;">
<code><span style="color:#c0c5ce;">mkdir -p /var/lib/simple-vms/${name}
cd /var/lib/simple-vms/${name}
exec ${cfg.vm.out}/bin/run-nixos-vm;
</span></code></pre>
<p>With this service we can get and keep our VMs up and running.</p>
<h2 id="stateless-vms">Stateless VMs</h2>
<p>I got a sticker recently that said &quot;You either have one source of truth, of
multiple sources of lies.&quot; To that end, I wanted to make my VM completely
stateless. QEMU lets you mount folders into the VM, so I used that to mount host
folders in the VM's <code>/etc/wireguard</code> and <code>/etc/ssh</code> so that the host can
provide the VM with WireGuard keys, and the VM can persist it's SSH host keys.</p>
<p>That's all the VM really needs. Every time my VM shuts down I delete the drive.
And just to be safe, I try deleting any drive on boot too.</p>
<p>If you're running a service on the VM, you'll likely want to persist that
service's state files too in a similar way.</p>
<h2 id="fin">Fin</h2>
<p>That's it. Just a small post for a neat little trick. If you set this up let
me know! I'm interested in hearing your use case.</p>
<h3 id="footnotes">Footnotes</h3>
<div class="footnote-definition" id="1"><sup class="footnote-definition-label">1</sup>
<p>User/pass = root/root. Exit qemu with C-a x.</p>
</div>

