
+++
title = "Minting A Single NFT"
date = 2021-12-01T00:00:00.000Z
template = "html_content/raw.html"
summary = """
In a previous post I made a page to sell some NFTs I had designed. I say
“designed”, not “made”, bec..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/12/01/minting-a-single-nft.html"
raw = """
<p>In a <a href="/2021/10/31/dog-money.html">previous post</a> I made a page to sell some NFTs I had designed. I say
“designed”, not “made”, because the NFTs don’t actually exist yet.</p>

<p>On <a href="https://opensea.io">OpenSea</a>, where those NFTs are listed, the NFT isn’t
actually “minted” (created) until first sale. This is primarily done to save the
artist the cost of minting an NFT which no one else is going to buy. There might
be a way to mint outside of a sale on OpenSea, but I haven’t dug too much into
it because it doesn’t matter.</p>

<p>It doesn’t matter because a primary goal here is to not go broke. And OpenSea is
primarily on Ethereum, a blockchain that can’t actually be used by normal people
because of the crazy fees. There are some L2s for it, but I don’t have any set
up, and keeping an NFT in an L2 feels like borrowed time.</p>

<p>So, as an initial test, I’ve printed an NFT on Solana, using
<a href="https://holaplex.com/">Holaplex</a>. Solana because it’s cheap and fast and
wonderful, and Holaplex because… a lot of reasons.</p>

<p>The main one is that other projects, like <a href="https://solsea.io/">SolSea</a> and
<a href="https://www.alpha.art/">AlphaArt</a>, require a sign-up just to print NFTs. And
not a crypto signup, where you just connect a wallet. But like a real one, with
an email. <a href="https://solanart.io/">Solanart</a> requires you to contact them
privately through discord to mint on them!</p>

<p>Why? NFTs are a weird market. A lot of these platforms appear to the
<del>customer</del> user more like casino games than anything, where the object is to
find the shiny thing which is going to get popular for one whimsical reason or
another. The artists get paid, the platform takes a cut, and whoever minted the
NFT prays.</p>

<p>For reasons involving the word “rug”, the artist, the one who is attaching their
work to an NFT, is not necessarily to be trusted. So there’s a lot of mechanisms
within the Solana NFT world to build trust between the audience and the artist.
Things like chain-enforced fair auctions (open to everyone at the same time) and
gatekeeping measures are examples.</p>

<p>Which is all well and good, but I still couldn’t mint an NFT.</p>

<h2 id="metaplex">Metaplex</h2>

<p>So I tried another tact: self-hosting. It’s like, my favorite thing? I talk
about it a lot.</p>

<p>I attempted to get <a href="https://www.metaplex.com/">Metaplex</a> set up locally. Metaplex is an organization,
associated with Solana Labs in some way I think, that’s helped develop the NFT
standard on Solana. And they also develop an open-source toolkit for hosting
your own NFT store, complete with NFT minting with no fees or other road blocks.
Sounds perfect!</p>

<p>Except that I’m not a capable enough javascript developer to get it running. I
got as far as the running the Next server and loading the app in my browser, but
a second into running it spits out some error in the console and nothing works
after that. I’ve spent too much time on it already, I won’t go into it more.</p>

<p>So metaplex, for now, is out.</p>

<h2 id="holaplex">Holaplex</h2>

<p>Until I, somehow, (how actually though…?), found <a href="https://holaplex.com/">Holaplex</a>. It’s
a very thinly skinned hosted Metaplex, with a really smooth signup process which
doesn’t involve any emails. Each user gets a storefront under their own
subdomain of whatever NFTs they want, and that’s it. It’s like geocities for
NFTs; pretty much the next best thing to self-hosted.</p>

<p>But to mint an NFT you don’t even need to do that, you just hit the “Mint NFTs”
button. So I did that, I uploaded an image, I paid the hosting fee ($2), and
that was it!</p>

<p>You can view my first NFT <a href="https://solscan.io/token/HsFpMvY9j5uy68CSDxRvb5aeoj4L3D4vsAkHsFqKvDYb">here</a>! It’s not for sale.</p>

<p>I’m hoping that one day I can get back to Metaplex and get it working, I’d much
prefer to have my store hosted myself. But at least this NFT exists now, and I
have a mechanism to make other ones for other people.</p>"""

+++
<p>In a <a href="/2021/10/31/dog-money.html">previous post</a> I made a page to sell some NFTs I had designed. I say
“designed”, not “made”, because the NFTs don’t actually exist yet.</p>

<p>On <a href="https://opensea.io">OpenSea</a>, where those NFTs are listed, the NFT isn’t
actually “minted” (created) until first sale. This is primarily done to save the
artist the cost of minting an NFT which no one else is going to buy. There might
be a way to mint outside of a sale on OpenSea, but I haven’t dug too much into
it because it doesn’t matter.</p>

<p>It doesn’t matter because a primary goal here is to not go broke. And OpenSea is
primarily on Ethereum, a blockchain that can’t actually be used by normal people
because of the crazy fees. There are some L2s for it, but I don’t have any set
up, and keeping an NFT in an L2 feels like borrowed time.</p>

<p>So, as an initial test, I’ve printed an NFT on Solana, using
<a href="https://holaplex.com/">Holaplex</a>. Solana because it’s cheap and fast and
wonderful, and Holaplex because… a lot of reasons.</p>

<p>The main one is that other projects, like <a href="https://solsea.io/">SolSea</a> and
<a href="https://www.alpha.art/">AlphaArt</a>, require a sign-up just to print NFTs. And
not a crypto signup, where you just connect a wallet. But like a real one, with
an email. <a href="https://solanart.io/">Solanart</a> requires you to contact them
privately through discord to mint on them!</p>

<p>Why? NFTs are a weird market. A lot of these platforms appear to the
<del>customer</del> user more like casino games than anything, where the object is to
find the shiny thing which is going to get popular for one whimsical reason or
another. The artists get paid, the platform takes a cut, and whoever minted the
NFT prays.</p>

<p>For reasons involving the word “rug”, the artist, the one who is attaching their
work to an NFT, is not necessarily to be trusted. So there’s a lot of mechanisms
within the Solana NFT world to build trust between the audience and the artist.
Things like chain-enforced fair auctions (open to everyone at the same time) and
gatekeeping measures are examples.</p>

<p>Which is all well and good, but I still couldn’t mint an NFT.</p>

<h2 id="metaplex">Metaplex</h2>

<p>So I tried another tact: self-hosting. It’s like, my favorite thing? I talk
about it a lot.</p>

<p>I attempted to get <a href="https://www.metaplex.com/">Metaplex</a> set up locally. Metaplex is an organization,
associated with Solana Labs in some way I think, that’s helped develop the NFT
standard on Solana. And they also develop an open-source toolkit for hosting
your own NFT store, complete with NFT minting with no fees or other road blocks.
Sounds perfect!</p>

<p>Except that I’m not a capable enough javascript developer to get it running. I
got as far as the running the Next server and loading the app in my browser, but
a second into running it spits out some error in the console and nothing works
after that. I’ve spent too much time on it already, I won’t go into it more.</p>

<p>So metaplex, for now, is out.</p>

<h2 id="holaplex">Holaplex</h2>

<p>Until I, somehow, (how actually though…?), found <a href="https://holaplex.com/">Holaplex</a>. It’s
a very thinly skinned hosted Metaplex, with a really smooth signup process which
doesn’t involve any emails. Each user gets a storefront under their own
subdomain of whatever NFTs they want, and that’s it. It’s like geocities for
NFTs; pretty much the next best thing to self-hosted.</p>

<p>But to mint an NFT you don’t even need to do that, you just hit the “Mint NFTs”
button. So I did that, I uploaded an image, I paid the hosting fee ($2), and
that was it!</p>

<p>You can view my first NFT <a href="https://solscan.io/token/HsFpMvY9j5uy68CSDxRvb5aeoj4L3D4vsAkHsFqKvDYb">here</a>! It’s not for sale.</p>

<p>I’m hoping that one day I can get back to Metaplex and get it working, I’d much
prefer to have my store hosted myself. But at least this NFT exists now, and I
have a mechanism to make other ones for other people.</p>
