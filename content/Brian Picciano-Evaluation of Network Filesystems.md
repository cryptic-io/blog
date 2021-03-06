
+++
title = "Evaluation of Network Filesystems"
date = 2021-04-06T00:00:00.000Z
template = "html_content/raw.html"
summary = """
It’s been a bit since updating my progress on what I’ve been lately calling the
“cryptic nebula” pro..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/04/06/evaluation-of-network-filesystems.html"
raw = """
<p>It’s been a bit since updating my progress on what I’ve been lately calling the
“cryptic nebula” project. When I last left off I was working on building the
<a href="https://github.com/cryptic-io/mobile_nebula">mobile nebula</a> using <a href="https://nixos.org/manual/nix/stable/">nix</a>. For the moment I gave up on
that dream, as flutter and nix just <em>really</em> don’t get along and I don’t want to
get to distracted on problems that aren’t critical to the actual goal.</p>

<p>Instead I’d like to pursue the next critical component of the system, and
that’s a shared filesystem. The use-case I’m ultimately trying to achieve is:</p>

<ul>
  <li>All hosts communicate with each other via the nebula network.</li>
  <li>All hosts are personal machines owned by individuals, <em>not</em> cloud VMs.</li>
  <li>A handful of hosts are always-on, or at least as always-on as can be achieved
in a home environment.</li>
  <li>All hosts are able to read/write to a shared filesystem, which is mounted via
FUSE (or some other mechanism, though I can’t imagine what) on their computer.</li>
  <li>Top-level directories within the shared filesystem can be restricted, so
that only a certain person (or host) can read/write to them.</li>
</ul>

<p>What I’m looking for is some kind of network filesystem, of which there are
<em>many</em>. This document will attempt to evaluate all relevant projects and come up
with the next steps. It may be that no project fits the bill perfectly, and that
I’m stuck either modifying an existing project to my needs or, if things are
looking really dire, starting a new project.</p>

<p>The ultimate use-case here is something like a self-hosted, distributed <a href="https://book.keybase.io/docs/files">keybase
filesystem</a>; somewhere where individuals in
the cluster can back up their personal projects, share files with each other,
and possibly even be used as the base layer for more complex applications on
top.</p>

<p>The individuals involved shouldn’t have to deal with configuring their
distributed FS, either to read from it or add storage resources to it. Ideally
the FS process can be bundled together with the nebula process and run opaquely;
the user is just running their “cryptic nebula” process and everything else is
handled in the background.</p>

<h2 id="low-pass-filter">Low Pass Filter</h2>

<p>There are some criteria for these projects that I’m not willing to compromise
on; these criteria will form a low pass filter which, hopefully, will narrow our
search appreciably.</p>

<p>The network filesystem used by the cryptic nebula must:</p>

<ul>
  <li>Be able to operate over a nebula network (obviously).</li>
  <li>Be open-source. The license doesn’t matter, as long as the code is available.</li>
  <li>Run on both Mac and Linux.</li>
  <li>Not require a third-party to function.</li>
  <li>Allows for a replication factor of 3.</li>
  <li>Supports sharding of data (ie each host need not have the entire dataset).</li>
  <li>Allow for mounting a FUSE filesystem in any hosts’ machine to interact with
the network filesystem.</li>
  <li>Not run in the JVM, or any other VM which is memory-greedy.</li>
</ul>

<p>The last may come across as mean, but the reason for it is that I forsee the
network filesystem client running on users’ personal laptops, which cannot be
assumed to have resources to spare.</p>

<h2 id="rubric">Rubric</h2>

<p>Each criteria in the next set lies along a spectrum. Any project may meet one of
thses criteria fully, partially, or not at all. For each criteria I assign a
point value according to how fully a project meets the criteria, and then sum up
the points to give the project a final score. The project with the highest final
score is not necessarily the winner, but this system should at least give some
good candidates for final consideration.</p>

<p>The criteria, and their associated points values, are:</p>

<ul>
  <li><strong>Hackability</strong>: is the source-code of the project approachable?
    <ul>
      <li>0: No</li>
      <li>1: Kind of, and there’s not much of a community.</li>
      <li>2: Kind of, but there is an active community.</li>
      <li>3: Yes</li>
    </ul>
  </li>
  <li><strong>Documentation</strong>: is the project well documented?
    <ul>
      <li>0: No docs.</li>
      <li>1: Incomplete or out-of-date docs.</li>
      <li>2: Very well documented.</li>
    </ul>
  </li>
  <li><strong>Transience</strong>: how does the system handle hosts appearing or disappearing?
    <ul>
      <li>0: Requires an automated system to be built to handle adding/removing
hosts.</li>
      <li>1: Gracefully handled.</li>
    </ul>
  </li>
  <li><strong>Priority</strong>: is it possible to give certain hosts priority when choosing
which will host/replicate some piece of data?
    <ul>
      <li>0: No.</li>
      <li>1: Yes.</li>
    </ul>
  </li>
  <li><strong>Caching</strong>: will hosts reading a file have that file cached locally for the
next reading (until the file is modified)?
    <ul>
      <li>0: No.</li>
      <li>1: Yes.</li>
    </ul>
  </li>
  <li><strong>Conflicts</strong>: if two hosts updated the same file at the same time, how is
that handled?
    <ul>
      <li>0: The file can no longer be updated.</li>
      <li>1: One update clobbers the other, or both go through in an undefined
order.</li>
      <li>2: One update is disallowed.</li>
      <li>3: A copy of the file containing the “losing” update is created (ie: how
dropbox does it).</li>
      <li>4: Strategy can be configured on the file/directory level.</li>
    </ul>
  </li>
  <li><strong>Consistency</strong>: how does the system handle a file being changed frequently?
    <ul>
      <li>0: File changes must be propagated before subsequent updates are allowed (fully consistent).</li>
      <li>1: Files are snapshotted at some large-ish interval (eventually consistent).</li>
      <li>2: File state (ie content hash, last modifid, etc) is propagated
frequently but contents are only fully propagated once the file has
“settled” (eventually consistent with debounce).</li>
    </ul>
  </li>
  <li><strong>POSIX</strong>: how POSIX compliant is the mounted fileystem?
    <ul>
      <li>0: Only the most basic features are implemented.</li>
      <li>1: Some extra features are implemented.</li>
      <li>2: Fully POSIX compliant.</li>
    </ul>
  </li>
  <li><strong>Scale</strong>: how many hosts can be a part of the cluster?
    <ul>
      <li>0: A finite number.</li>
      <li>1: A finite number of dedicated hosts, infinite ephemeral.</li>
      <li>2: Infinite hosts.</li>
    </ul>
  </li>
  <li><strong>Failure</strong>: how does the system handle failures (network partitions, hosts
hanging, buggy client versions)?
    <ul>
      <li>0: Data loss.</li>
      <li>1: Reads and writes are halted.</li>
      <li>2: Reads are allowed but writes are halted.</li>
      <li>3: System is partially read/write, except effected parts.</li>
    </ul>
  </li>
  <li><strong>Limitations</strong>: are there limits on how big files can be, or how big
directories can be?
    <ul>
      <li>0: Files are limited to below 1TB in size.</li>
      <li>1: Directories are limited to below 100,000 files.</li>
      <li>2: No limits.</li>
    </ul>
  </li>
  <li><strong>Encryption</strong>: how is data encrypted?
    <ul>
      <li>0: Not at all, DIY.</li>
      <li>1: Encrypted at rest.</li>
      <li>2: Per-user encryption.</li>
    </ul>
  </li>
  <li><strong>Permissions</strong>: how are modifications to data restricted?
    <ul>
      <li>0: Not at all.</li>
      <li>1: Permissions are only superifically enforced.</li>
      <li>2: Fully enforced user/group restrictions, complex patterns, and/or POSIX ACLs.</li>
    </ul>
  </li>
  <li><strong>Administration</strong>: how much administration is required for the system to
function?
    <ul>
      <li>0: Frequent.</li>
      <li>1: Infrequent.</li>
      <li>2: Essentially none.</li>
    </ul>
  </li>
  <li><strong>Simplicity</strong>: how understandable is the system as a whole?
    <ul>
      <li>0: Very complex.</li>
      <li>1: Understandable with some study.</li>
      <li>2: Very simple, easy to predict.</li>
    </ul>
  </li>
  <li><strong>Visibility</strong>: how much visibility is available into processes within the
system?
    <ul>
      <li>0: Total black box.</li>
      <li>1: Basic logging.</li>
      <li>2: CLI tooling.</li>
      <li>3: Exportable metrics (e.g. prometheus).</li>
    </ul>
  </li>
</ul>

<h2 id="evaluations">Evaluations</h2>

<p>With the rubric defined, let’s start actually working through our options! There
are many, many different possibilities, so this may not be an exhaustive list.</p>

<h3 id="ceph"><a href="https://docs.ceph.com/en/latest/cephfs/index.html">Ceph</a></h3>

<blockquote>
  <p>The Ceph File System, or CephFS, is a POSIX-compliant file system built on
top of Ceph’s distributed object store, RADOS. CephFS endeavors to provide a
state-of-the-art, multi-use, highly available, and performant file store for
a variety of applications, including traditional use-cases like shared home
directories, HPC scratch space, and distributed workflow shared storage.</p>
</blockquote>

<ul>
  <li>Hackability: 2. Very active community, but it’s C++.</li>
  <li>Documentation: 2. Hella docs, very daunting.</li>
  <li>Transience: 0. Adding hosts seems to require multiple configuration steps.</li>
  <li>Priority: 1. There is fine-tuning on a per-host basis.</li>
  <li>Caching: 1. Clients can cache both metadata and block data.</li>
  <li>Conflicts: 1. The FS behaves as much like a real FS as possible.</li>
  <li>Consistency: 0. System is CP.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. Cluster can grow without any real bounds.</li>
  <li>Failure: 3. There’s no indication anywhere that Ceph goes into any kind of cluster-wide failure mode.</li>
  <li>Limitations: 2. There are performance considerations with large directories, but no hard limits.</li>
  <li>Encryption: 0. None to speak of.</li>
  <li>Permissions: 2. POSIX ACLs supported.</li>
  <li>Administration: 1. This is a guess, but Ceph seems to be self-healing in general, but still needs hand-holding in certain situations (adding/removing nodes, etc…)</li>
  <li>Simplicity: 0. There are many moving pieces, as well as many different kinds of processes and entities.</li>
  <li>Visibility: 3. Lots of tooling to dig into the state of the cluster, as well as a prometheus module.</li>
</ul>

<p>TOTAL: 22</p>

<h4 id="comments">Comments</h4>

<p>Ceph has been recommended to me by a few people. It is clearly a very mature
project, though that maturity has brought with it a lot of complexity. A lot of
the complexity of Ceph seems to be rooted in its strong consistency guarantees,
which I’m confident it fulfills well, but are not really needed for the
use-case I’m interested in. I’d prefer a simpler, eventually consistent,
system. It’s also not clear to me that Ceph would even perform very well in my
use-case as it seems to want an actual datacenter deployment, with beefy
hardware and hosts which are generally close together.</p>

<h3 id="glusterfs"><a href="https://docs.gluster.org/en/latest/">GlusterFS</a></h3>

<blockquote>
  <p>GlusterFS is a scalable network filesystem suitable for data-intensive tasks
such as cloud storage and media streaming. GlusterFS is free and open source
software and can utilize common off-the-shelf hardware.</p>
</blockquote>

<ul>
  <li>Hackability: 2. Mostly C code, but there is an active community.</li>
  <li>Documentation: 2. Good docs.</li>
  <li>Transience: 0. New nodes cannot add themselves to the pool.</li>
  <li>Priority: 0. Data is distributed based on consistent hashing algo, nothing else.</li>
  <li>Caching: 1. Docs mention client-side caching layer.</li>
  <li>Conflicts: 0. File becomes frozen, manual intervention is needed to save it.</li>
  <li>Consistency: 0. Gluster aims to be fully consistent.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. No apparent limits.</li>
  <li>Failure: 3. Clients determine on their own whether or not they have a quorum for a particular sub-volume.</li>
  <li>Limitations: 2. Limited by the file system underlying each volume, I think.</li>
  <li>Encryption: 2. Encryption can be done on the volume level, each user could have a private volume.</li>
  <li>Permissions: 2. ACL checking is enforced on the server-side, but requires syncing of users and group membership across servers.</li>
  <li>Administration: 1. Beyond adding/removing nodes the system is fairly self-healing.</li>
  <li>Simplicity: 1. There’s only one kind of server process, and the configuration of volumes is is well documented and straightforward.</li>
  <li>Visibility: 3. Prometheus exporter available.</li>
</ul>

<p>TOTAL: 23</p>

<h4 id="comments-1">Comments</h4>

<p>GlusterFS was my initial choice when I did a brief survey of DFSs for this
use-case. However, after further digging into it I think it will suffer the
same ultimate problem as CephFS: too much consistency for a wide-area
application like I’m envisioning. The need for syncing user/groups across
machines as actual system users is also cumbersome enough to make it not a
great choice.</p>

<h3 id="moosefs"><a href="https://moosefs.com/">MooseFS</a></h3>

<blockquote>
  <p>MooseFS is a Petabyte Open Source Network Distributed File System. It is easy
to deploy and maintain, highly reliable, fault tolerant, highly performing,
easily scalable and POSIX compliant.</p>

  <p>MooseFS spreads data over a number of commodity servers, which are visible to
the user as one resource. For standard file operations MooseFS acts like
ordinary Unix-like file system.</p>
</blockquote>

<ul>
  <li>Hackability: 2. All C code, pretty dense, but backed by a company.</li>
  <li>Documentation: 2. There’s a giant PDF you can read through like a book. I
guess that’s…. good?</li>
  <li>Transience: 0. Nodes must be added manually.</li>
  <li>Priority: 1. There’s “Storage Classes”.</li>
  <li>Caching: 1. Caching is done on the client, and there’s some synchronization
with the master server around it.</li>
  <li>Conflicts: 1. Both update operations will go through.</li>
  <li>Consistency: 0. Afaict it’s a fully consistent system, with a master server
being used to synchronize changes.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. Cluster can grow without any real bounds.</li>
  <li>Failure: 1. If the master server is unreachable then the client can’t
function.</li>
  <li>Limitations: 2. Limits are very large, effectively no limit.</li>
  <li>Encryption: 0. Docs make no mention of encryption.</li>
  <li>Permissions: 1. Afaict permissions are done by the OS on the fuse mount.</li>
  <li>Administration: 1. It seems that if the topology is stable there shouldn’t be
much going on.</li>
  <li>Simplicity: 0. There are many moving pieces, as well as many different kinds of processes and entities.</li>
  <li>Visibility: 2. Lots of cli tooling, no prometheus metrics that I could find.</li>
</ul>

<p>TOTAL: 17</p>

<p>Overall MooseFS seems to me like a poor-developer’s Ceph. It can do exactly the
same things, but with less of a community around it. The sale’s pitch and
feature-gating also don’t ingratiate it to me. The most damning “feature” is the
master metadata server, which acts as a SPOF and only sort of supports
replication (but not failover, unless you get Pro).</p>

<h2 id="cutting-room-floor">Cutting Room Floor</h2>

<p>The following projects were intended to be reviewed, but didn’t make the cut for
various reasons.</p>

<ul>
  <li>
    <p>Tahoe-LAFS: The FUSE mount (which is actually an SFTP mount) doesn’t support
mutable files.</p>
  </li>
  <li>
    <p>HekaFS: Doesn’t appear to exist anymore(?)</p>
  </li>
  <li>
    <p>IPFS-cluster: Doesn’t support sharding.</p>
  </li>
  <li>
    <p>MinFS: Seems to only work off S3, no longer maintained anyway.</p>
  </li>
  <li>
    <p>DRDB: Linux specific, no mac support.</p>
  </li>
  <li>
    <p>BeeGFS: No mac support (I don’t think? I couldn’t find any indication it
supports macs at any rate).</p>
  </li>
  <li>
    <p>NFS: No support for sharding the dataset.</p>
  </li>
</ul>

<h2 id="conclusions">Conclusions</h2>

<p>Going through the featuresets of all these different projects really helped me
focus in on how I actually expect this system to function, and a few things
stood out to me:</p>

<ul>
  <li>
    <p>Perfect consistency is not a goal, and is ultimately harmful for this
use-case. The FS needs to propagate changes relatively quickly, but if two
different hosts are updating the same file it’s not necessary to synchronize
those updates like a local filesystem would; just let one changeset clobber
the other and let the outer application deal with coordination.</p>
  </li>
  <li>
    <p>Permissions are extremely important, and yet for all these projects are
generally an afterthought. In a distributed setting we can’t rely on the OS
user/groups of a host to permission read/write access. Instead that must be
done primarily via e2e encryption.</p>
  </li>
  <li>
    <p>Transience is not something most of these project expect, but is a hard
requirement of this use-case. In the long run we need something which can be
run on home hardware on home ISPs, which is not reliable at all. Hosts need to
be able to flit in and out of existence, and the cluster as a whole needs to
self-heal through that process.</p>
  </li>
</ul>

<p>In the end, it may be necessary to roll our own project for this, as I don’t
think any of the existing distributed file systems are suitable for what’s
needed.</p>"""

+++
<p>It’s been a bit since updating my progress on what I’ve been lately calling the
“cryptic nebula” project. When I last left off I was working on building the
<a href="https://github.com/cryptic-io/mobile_nebula">mobile nebula</a> using <a href="https://nixos.org/manual/nix/stable/">nix</a>. For the moment I gave up on
that dream, as flutter and nix just <em>really</em> don’t get along and I don’t want to
get to distracted on problems that aren’t critical to the actual goal.</p>

<p>Instead I’d like to pursue the next critical component of the system, and
that’s a shared filesystem. The use-case I’m ultimately trying to achieve is:</p>

<ul>
  <li>All hosts communicate with each other via the nebula network.</li>
  <li>All hosts are personal machines owned by individuals, <em>not</em> cloud VMs.</li>
  <li>A handful of hosts are always-on, or at least as always-on as can be achieved
in a home environment.</li>
  <li>All hosts are able to read/write to a shared filesystem, which is mounted via
FUSE (or some other mechanism, though I can’t imagine what) on their computer.</li>
  <li>Top-level directories within the shared filesystem can be restricted, so
that only a certain person (or host) can read/write to them.</li>
</ul>

<p>What I’m looking for is some kind of network filesystem, of which there are
<em>many</em>. This document will attempt to evaluate all relevant projects and come up
with the next steps. It may be that no project fits the bill perfectly, and that
I’m stuck either modifying an existing project to my needs or, if things are
looking really dire, starting a new project.</p>

<p>The ultimate use-case here is something like a self-hosted, distributed <a href="https://book.keybase.io/docs/files">keybase
filesystem</a>; somewhere where individuals in
the cluster can back up their personal projects, share files with each other,
and possibly even be used as the base layer for more complex applications on
top.</p>

<p>The individuals involved shouldn’t have to deal with configuring their
distributed FS, either to read from it or add storage resources to it. Ideally
the FS process can be bundled together with the nebula process and run opaquely;
the user is just running their “cryptic nebula” process and everything else is
handled in the background.</p>

<h2 id="low-pass-filter">Low Pass Filter</h2>

<p>There are some criteria for these projects that I’m not willing to compromise
on; these criteria will form a low pass filter which, hopefully, will narrow our
search appreciably.</p>

<p>The network filesystem used by the cryptic nebula must:</p>

<ul>
  <li>Be able to operate over a nebula network (obviously).</li>
  <li>Be open-source. The license doesn’t matter, as long as the code is available.</li>
  <li>Run on both Mac and Linux.</li>
  <li>Not require a third-party to function.</li>
  <li>Allows for a replication factor of 3.</li>
  <li>Supports sharding of data (ie each host need not have the entire dataset).</li>
  <li>Allow for mounting a FUSE filesystem in any hosts’ machine to interact with
the network filesystem.</li>
  <li>Not run in the JVM, or any other VM which is memory-greedy.</li>
</ul>

<p>The last may come across as mean, but the reason for it is that I forsee the
network filesystem client running on users’ personal laptops, which cannot be
assumed to have resources to spare.</p>

<h2 id="rubric">Rubric</h2>

<p>Each criteria in the next set lies along a spectrum. Any project may meet one of
thses criteria fully, partially, or not at all. For each criteria I assign a
point value according to how fully a project meets the criteria, and then sum up
the points to give the project a final score. The project with the highest final
score is not necessarily the winner, but this system should at least give some
good candidates for final consideration.</p>

<p>The criteria, and their associated points values, are:</p>

<ul>
  <li><strong>Hackability</strong>: is the source-code of the project approachable?
    <ul>
      <li>0: No</li>
      <li>1: Kind of, and there’s not much of a community.</li>
      <li>2: Kind of, but there is an active community.</li>
      <li>3: Yes</li>
    </ul>
  </li>
  <li><strong>Documentation</strong>: is the project well documented?
    <ul>
      <li>0: No docs.</li>
      <li>1: Incomplete or out-of-date docs.</li>
      <li>2: Very well documented.</li>
    </ul>
  </li>
  <li><strong>Transience</strong>: how does the system handle hosts appearing or disappearing?
    <ul>
      <li>0: Requires an automated system to be built to handle adding/removing
hosts.</li>
      <li>1: Gracefully handled.</li>
    </ul>
  </li>
  <li><strong>Priority</strong>: is it possible to give certain hosts priority when choosing
which will host/replicate some piece of data?
    <ul>
      <li>0: No.</li>
      <li>1: Yes.</li>
    </ul>
  </li>
  <li><strong>Caching</strong>: will hosts reading a file have that file cached locally for the
next reading (until the file is modified)?
    <ul>
      <li>0: No.</li>
      <li>1: Yes.</li>
    </ul>
  </li>
  <li><strong>Conflicts</strong>: if two hosts updated the same file at the same time, how is
that handled?
    <ul>
      <li>0: The file can no longer be updated.</li>
      <li>1: One update clobbers the other, or both go through in an undefined
order.</li>
      <li>2: One update is disallowed.</li>
      <li>3: A copy of the file containing the “losing” update is created (ie: how
dropbox does it).</li>
      <li>4: Strategy can be configured on the file/directory level.</li>
    </ul>
  </li>
  <li><strong>Consistency</strong>: how does the system handle a file being changed frequently?
    <ul>
      <li>0: File changes must be propagated before subsequent updates are allowed (fully consistent).</li>
      <li>1: Files are snapshotted at some large-ish interval (eventually consistent).</li>
      <li>2: File state (ie content hash, last modifid, etc) is propagated
frequently but contents are only fully propagated once the file has
“settled” (eventually consistent with debounce).</li>
    </ul>
  </li>
  <li><strong>POSIX</strong>: how POSIX compliant is the mounted fileystem?
    <ul>
      <li>0: Only the most basic features are implemented.</li>
      <li>1: Some extra features are implemented.</li>
      <li>2: Fully POSIX compliant.</li>
    </ul>
  </li>
  <li><strong>Scale</strong>: how many hosts can be a part of the cluster?
    <ul>
      <li>0: A finite number.</li>
      <li>1: A finite number of dedicated hosts, infinite ephemeral.</li>
      <li>2: Infinite hosts.</li>
    </ul>
  </li>
  <li><strong>Failure</strong>: how does the system handle failures (network partitions, hosts
hanging, buggy client versions)?
    <ul>
      <li>0: Data loss.</li>
      <li>1: Reads and writes are halted.</li>
      <li>2: Reads are allowed but writes are halted.</li>
      <li>3: System is partially read/write, except effected parts.</li>
    </ul>
  </li>
  <li><strong>Limitations</strong>: are there limits on how big files can be, or how big
directories can be?
    <ul>
      <li>0: Files are limited to below 1TB in size.</li>
      <li>1: Directories are limited to below 100,000 files.</li>
      <li>2: No limits.</li>
    </ul>
  </li>
  <li><strong>Encryption</strong>: how is data encrypted?
    <ul>
      <li>0: Not at all, DIY.</li>
      <li>1: Encrypted at rest.</li>
      <li>2: Per-user encryption.</li>
    </ul>
  </li>
  <li><strong>Permissions</strong>: how are modifications to data restricted?
    <ul>
      <li>0: Not at all.</li>
      <li>1: Permissions are only superifically enforced.</li>
      <li>2: Fully enforced user/group restrictions, complex patterns, and/or POSIX ACLs.</li>
    </ul>
  </li>
  <li><strong>Administration</strong>: how much administration is required for the system to
function?
    <ul>
      <li>0: Frequent.</li>
      <li>1: Infrequent.</li>
      <li>2: Essentially none.</li>
    </ul>
  </li>
  <li><strong>Simplicity</strong>: how understandable is the system as a whole?
    <ul>
      <li>0: Very complex.</li>
      <li>1: Understandable with some study.</li>
      <li>2: Very simple, easy to predict.</li>
    </ul>
  </li>
  <li><strong>Visibility</strong>: how much visibility is available into processes within the
system?
    <ul>
      <li>0: Total black box.</li>
      <li>1: Basic logging.</li>
      <li>2: CLI tooling.</li>
      <li>3: Exportable metrics (e.g. prometheus).</li>
    </ul>
  </li>
</ul>

<h2 id="evaluations">Evaluations</h2>

<p>With the rubric defined, let’s start actually working through our options! There
are many, many different possibilities, so this may not be an exhaustive list.</p>

<h3 id="ceph"><a href="https://docs.ceph.com/en/latest/cephfs/index.html">Ceph</a></h3>

<blockquote>
  <p>The Ceph File System, or CephFS, is a POSIX-compliant file system built on
top of Ceph’s distributed object store, RADOS. CephFS endeavors to provide a
state-of-the-art, multi-use, highly available, and performant file store for
a variety of applications, including traditional use-cases like shared home
directories, HPC scratch space, and distributed workflow shared storage.</p>
</blockquote>

<ul>
  <li>Hackability: 2. Very active community, but it’s C++.</li>
  <li>Documentation: 2. Hella docs, very daunting.</li>
  <li>Transience: 0. Adding hosts seems to require multiple configuration steps.</li>
  <li>Priority: 1. There is fine-tuning on a per-host basis.</li>
  <li>Caching: 1. Clients can cache both metadata and block data.</li>
  <li>Conflicts: 1. The FS behaves as much like a real FS as possible.</li>
  <li>Consistency: 0. System is CP.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. Cluster can grow without any real bounds.</li>
  <li>Failure: 3. There’s no indication anywhere that Ceph goes into any kind of cluster-wide failure mode.</li>
  <li>Limitations: 2. There are performance considerations with large directories, but no hard limits.</li>
  <li>Encryption: 0. None to speak of.</li>
  <li>Permissions: 2. POSIX ACLs supported.</li>
  <li>Administration: 1. This is a guess, but Ceph seems to be self-healing in general, but still needs hand-holding in certain situations (adding/removing nodes, etc…)</li>
  <li>Simplicity: 0. There are many moving pieces, as well as many different kinds of processes and entities.</li>
  <li>Visibility: 3. Lots of tooling to dig into the state of the cluster, as well as a prometheus module.</li>
</ul>

<p>TOTAL: 22</p>

<h4 id="comments">Comments</h4>

<p>Ceph has been recommended to me by a few people. It is clearly a very mature
project, though that maturity has brought with it a lot of complexity. A lot of
the complexity of Ceph seems to be rooted in its strong consistency guarantees,
which I’m confident it fulfills well, but are not really needed for the
use-case I’m interested in. I’d prefer a simpler, eventually consistent,
system. It’s also not clear to me that Ceph would even perform very well in my
use-case as it seems to want an actual datacenter deployment, with beefy
hardware and hosts which are generally close together.</p>

<h3 id="glusterfs"><a href="https://docs.gluster.org/en/latest/">GlusterFS</a></h3>

<blockquote>
  <p>GlusterFS is a scalable network filesystem suitable for data-intensive tasks
such as cloud storage and media streaming. GlusterFS is free and open source
software and can utilize common off-the-shelf hardware.</p>
</blockquote>

<ul>
  <li>Hackability: 2. Mostly C code, but there is an active community.</li>
  <li>Documentation: 2. Good docs.</li>
  <li>Transience: 0. New nodes cannot add themselves to the pool.</li>
  <li>Priority: 0. Data is distributed based on consistent hashing algo, nothing else.</li>
  <li>Caching: 1. Docs mention client-side caching layer.</li>
  <li>Conflicts: 0. File becomes frozen, manual intervention is needed to save it.</li>
  <li>Consistency: 0. Gluster aims to be fully consistent.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. No apparent limits.</li>
  <li>Failure: 3. Clients determine on their own whether or not they have a quorum for a particular sub-volume.</li>
  <li>Limitations: 2. Limited by the file system underlying each volume, I think.</li>
  <li>Encryption: 2. Encryption can be done on the volume level, each user could have a private volume.</li>
  <li>Permissions: 2. ACL checking is enforced on the server-side, but requires syncing of users and group membership across servers.</li>
  <li>Administration: 1. Beyond adding/removing nodes the system is fairly self-healing.</li>
  <li>Simplicity: 1. There’s only one kind of server process, and the configuration of volumes is is well documented and straightforward.</li>
  <li>Visibility: 3. Prometheus exporter available.</li>
</ul>

<p>TOTAL: 23</p>

<h4 id="comments-1">Comments</h4>

<p>GlusterFS was my initial choice when I did a brief survey of DFSs for this
use-case. However, after further digging into it I think it will suffer the
same ultimate problem as CephFS: too much consistency for a wide-area
application like I’m envisioning. The need for syncing user/groups across
machines as actual system users is also cumbersome enough to make it not a
great choice.</p>

<h3 id="moosefs"><a href="https://moosefs.com/">MooseFS</a></h3>

<blockquote>
  <p>MooseFS is a Petabyte Open Source Network Distributed File System. It is easy
to deploy and maintain, highly reliable, fault tolerant, highly performing,
easily scalable and POSIX compliant.</p>

  <p>MooseFS spreads data over a number of commodity servers, which are visible to
the user as one resource. For standard file operations MooseFS acts like
ordinary Unix-like file system.</p>
</blockquote>

<ul>
  <li>Hackability: 2. All C code, pretty dense, but backed by a company.</li>
  <li>Documentation: 2. There’s a giant PDF you can read through like a book. I
guess that’s…. good?</li>
  <li>Transience: 0. Nodes must be added manually.</li>
  <li>Priority: 1. There’s “Storage Classes”.</li>
  <li>Caching: 1. Caching is done on the client, and there’s some synchronization
with the master server around it.</li>
  <li>Conflicts: 1. Both update operations will go through.</li>
  <li>Consistency: 0. Afaict it’s a fully consistent system, with a master server
being used to synchronize changes.</li>
  <li>POSIX: 2. Fully POSIX compliant.</li>
  <li>Scale: 2. Cluster can grow without any real bounds.</li>
  <li>Failure: 1. If the master server is unreachable then the client can’t
function.</li>
  <li>Limitations: 2. Limits are very large, effectively no limit.</li>
  <li>Encryption: 0. Docs make no mention of encryption.</li>
  <li>Permissions: 1. Afaict permissions are done by the OS on the fuse mount.</li>
  <li>Administration: 1. It seems that if the topology is stable there shouldn’t be
much going on.</li>
  <li>Simplicity: 0. There are many moving pieces, as well as many different kinds of processes and entities.</li>
  <li>Visibility: 2. Lots of cli tooling, no prometheus metrics that I could find.</li>
</ul>

<p>TOTAL: 17</p>

<p>Overall MooseFS seems to me like a poor-developer’s Ceph. It can do exactly the
same things, but with less of a community around it. The sale’s pitch and
feature-gating also don’t ingratiate it to me. The most damning “feature” is the
master metadata server, which acts as a SPOF and only sort of supports
replication (but not failover, unless you get Pro).</p>

<h2 id="cutting-room-floor">Cutting Room Floor</h2>

<p>The following projects were intended to be reviewed, but didn’t make the cut for
various reasons.</p>

<ul>
  <li>
    <p>Tahoe-LAFS: The FUSE mount (which is actually an SFTP mount) doesn’t support
mutable files.</p>
  </li>
  <li>
    <p>HekaFS: Doesn’t appear to exist anymore(?)</p>
  </li>
  <li>
    <p>IPFS-cluster: Doesn’t support sharding.</p>
  </li>
  <li>
    <p>MinFS: Seems to only work off S3, no longer maintained anyway.</p>
  </li>
  <li>
    <p>DRDB: Linux specific, no mac support.</p>
  </li>
  <li>
    <p>BeeGFS: No mac support (I don’t think? I couldn’t find any indication it
supports macs at any rate).</p>
  </li>
  <li>
    <p>NFS: No support for sharding the dataset.</p>
  </li>
</ul>

<h2 id="conclusions">Conclusions</h2>

<p>Going through the featuresets of all these different projects really helped me
focus in on how I actually expect this system to function, and a few things
stood out to me:</p>

<ul>
  <li>
    <p>Perfect consistency is not a goal, and is ultimately harmful for this
use-case. The FS needs to propagate changes relatively quickly, but if two
different hosts are updating the same file it’s not necessary to synchronize
those updates like a local filesystem would; just let one changeset clobber
the other and let the outer application deal with coordination.</p>
  </li>
  <li>
    <p>Permissions are extremely important, and yet for all these projects are
generally an afterthought. In a distributed setting we can’t rely on the OS
user/groups of a host to permission read/write access. Instead that must be
done primarily via e2e encryption.</p>
  </li>
  <li>
    <p>Transience is not something most of these project expect, but is a hard
requirement of this use-case. In the long run we need something which can be
run on home hardware on home ISPs, which is not reliable at all. Hosts need to
be able to flit in and out of existence, and the cluster as a whole needs to
self-heal through that process.</p>
  </li>
</ul>

<p>In the end, it may be necessary to roll our own project for this, as I don’t
think any of the existing distributed file systems are suitable for what’s
needed.</p>
