
+++
title = "NFTs"
date = 2021-05-02T00:00:00.000Z
template = "html_content/raw.html"
summary = """
NFT stands for “non-fungible token”. The “token” part refers to an NFT being a
token whose ownership..."""

[extra]
author = "Brian Picciano"
originalLink = "https://blog.mediocregopher.com/2021/05/02/nfts.html"
raw = """
<p>NFT stands for “non-fungible token”. The “token” part refers to an NFT being a
token whose ownership is recorded on a blockchain. Pretty much all
cryptocurrencies, from bitcoin to your favorite shitcoin, could be called tokens
in this sense. Each token has exactly one owner, and ownership of the token can
be transferred from one wallet to another via a transaction on the blockchain.</p>

<p>What sets an NFT apart from a cryptocurrency is the “non-fungible” part.
Cryptocurrency tokens are fungible; one bitcoin is the same as any other bitoin
(according to the protocol, at least), in the same way as one US dollar holds as
much value as any other US dollar. Fungibility is the property of two units of
something being exactly interchangeable.</p>

<p>NFTs are <em>not</em> fungible. One is not the same as any other. Each has some piece
of data attached to it, and each is recorded separately on a blockchain as an
individual token. You can think of an NFT as a unique cryptocurrency which has a
supply of 1 and can’t be divided.</p>

<p>Depending on the protocol used to produce an NFT, the data attached to it might
be completely independent of its identity, even. It may be possible to produce
two NFTs with the exact same data attached to them (again, depending on the
protocol used), but even so those two NFTs will be independent and not
interchangeable.</p>

<h2 id="fud">FUD</h2>

<p>Before getting into why NFTs are interesting, I want to first address some
common criticism I see of them online (aka, in my twitter feed). The most
common, and unfortunately least legitimate, criticism has to do with the
environmental impact of NFTs. While the impact on energy usage and the
environment when talking about bitcoin is a topic worth going into, bitcoin
doesn’t support hosting NFTs and therefore that topic is irrelevant here.</p>

<p>Most NFTs are hosted on ethereum, which does have a comparable energy footprint
to bitcoin (it’s somewhat less than half, according to the internet). <em>However</em>,
ethereum is taking actual, concrete steps towards changing its consensus
mechanism from proof-of-work (PoW) to proof-of-stake (PoS), which will cut the
energy usage of the network down to essentially nothing. The rollout plan for
Ethereum PoS covers the next couple of years, and after that we don’t really
have to worry about the energy usage of NFTs any longer.</p>

<p>The other big criticism I hear is about the value and nature of art and what the
impact of NFTs are in that area. I’m going to talk more about this in this post,
but, simply put, I don’t think that the value and nature of art are immutable,
anymore than the form of art is immutable. Perhaps NFTs <em>will</em> change art, but
change isn’t bad in itself, and furthermore I don’t think they will actually
change it all that much. People will still produce art, it’s only the
distribution mechanism that might change.</p>

<h2 id="real-useful-boring-things">Real, Useful, Boring Things</h2>

<p>Most of the coverage around NFTs has to do with using them to represent
collectibles and art. I’d like to start by talking about other use-cases, those
where NFTs are actually “useful” (in the dull, practical sense).</p>

<p>Each NFT can carry some piece of data along with it. This data can be anything,
but for a practical use-case it needs to be something which indicates ownership
of some internet good. It <em>cannot</em> be the good itself. For example, an NFT which
contains an image does not really convey the ownership of that image; anyone can
copy the image data and own that image as well (intellectual property rights be
damned!).</p>

<p>A real use-case for NFTs which I’m already, if accidentally, taking advantage
of, is domain name registration. I am the proud owner of the
<a href="https://nfton.me/nft/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/7558304748055753202351203668187280010336475031529884349040105080320604507070">mediocregopher.eth</a> domain name (the <code class="language-plaintext highlighter-rouge">.eth</code> TLD is not yet in wide usage
in browsers, but one day!). The domain name’s ownership is indicated by an NFT:
whoever holds that NFT, which I currently do, has the right to change all
information attached to the <code class="language-plaintext highlighter-rouge">mediocregopher.eth</code> domain. If I want to sell the
domain all I need to do is sell the NFT, which can be done via an ethereum
transaction.</p>

<p>Domain names work well for NFTs because knowing the data attached to the NFT
doesn’t actually do anything for you. It’s the actual <em>ownership</em> of the NFT
which unlocks value. And I think this is the key rule for where to look to apply
NFTs to practical use-cases: the ownership of the NFT has to unlock some
functionality, not the data attached to it. The functionality has to be digital
in nature, as well, as anything related to the physical world is not as easily
guaranteed.</p>

<p>I haven’t thought of many further practical use-cases of NFTs, but we’re still
in early stages and I’m sure more will come up. In any case, the practical stuff
is boring, let’s talk about art.</p>

<h2 id="art-memes-and-all-wonderful-things">Art, Memes, and All Wonderful Things</h2>

<p>For many the most baffling aspect of NFTs is their use as collectibles. Indeed,
their use as collectibles is their <em>primary</em> use right now, even though these
collectibles procur no practical value for their owner; at best they are
speculative goods, small gambles, and at worst just a complete waste of money.
How can this be?</p>

<p>The curmudgeons of the world would have you believe that money is only worth
spending on goods which offer practical value. If the good is neither consumable
in a way which meets a basic need, nor produces other goods of further value,
then it is worthless. Obviously NFTs fall into the “worthless” category.</p>

<p>Unfortunately for them, the curmudgeons don’t live in reality. People spend
their money on stupid, pointless shit all the time. I’m prepared to argue that
people almost exclusively spend their money on stupid, pointless shit. The
monetary value of a good has very little to do with its ability to meet a basic
necessity or its ability to produce value (whatever that even really means), and
more to do with how owning the shiny thing or doing the fun thing makes us
stupid monkeys very happy (for a time).</p>

<p>Rather than bemoan NFTs, and our simple irrationality which makes them
desirable, let’s embrace them as a new tool for expressing our irrationality to
the world, a tool which we have yet to fully explore.</p>

<h3 id="a-moment-captured">A Moment Captured</h3>

<p>It’s 1857 and Jean-François Millet reveals to the world what would become one of
his best known works: <em>The Gleaners</em>.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/nfts/gleaners.jpg" target="_blank">
    <picture>
      <source media="(min-width: 1000px) and (min-resolution: 3.0dppx)" srcset="/img/nfts/3000px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.5dppx)" srcset="/img/nfts/2500px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.0dppx)" srcset="/img/nfts/2000px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 1.5dppx)" srcset="/img/nfts/1500px/gleaners.jpg" />
      <source media="(min-width: 500px), (min-resolution: 1.1dppx)" srcset="/img/nfts/1000px/gleaners.jpg" />
      <source srcset="/img/nfts/500px/gleaners.jpg" />
      <img style="max-height: 60vh;" src="/img/nfts/1000px/gleaners.jpg" alt="" />
    </picture>
  </a>
</div>

<p>The painting depicts three peasants gleaning a field, the bulk of their harvest
already stacked high in the background. The <a href="https://en.wikipedia.org/wiki/The_Gleaners">wikipedia entry</a> has this
to say about the painting’s eventual final sale:</p>

<blockquote>
  <p>In 1889, the painting, then owned by banker Ferdinand Bischoffsheim, sold for
300,000 francs at auction. The buyer remained anonymous, but rumours were
that the painting was coveted by an American buyer. It was announced less than
a week later that Champagne maker Jeanne-Alexandrine Louise Pommery had
acquired the piece, which silenced gossip on her supposed financial issues
after leaving her grapes on the vines weeks longer than her competitors.</p>
</blockquote>

<p>I think we can all breathe a sigh of relief for Jeanne-Alexandrine.</p>

<p>I’d like to talk about <em>why</em> this painting was worth 300k francs, and really
what makes art valuable at all (aside from the money laundering and tax evasion
that high-value art enables). Millet didn’t merely take a picture using paints
and canvas, an exact replica of what his eyes could see. It’s doubtful this
scene ever played out in reality, exactly as depicted, at all! It existed only
within Millet himself.</p>

<p>In <em>The Gleaners</em> Millet captured far more than an image: the image itself
conveys the struggle of a humble life, the joy of the harvest, the history of
the french peasantry (and therefore the other french societal classes as well),
the vastness of the world compared to our little selves, and surely many other
things, each dependant on the viewer. The image conveys emotions, and most
importantly it conveys emotions captured at a particular moment, a moment which
no longer exists and will never exist again. The capturing of such a moment by
an artist capable of doing it some justice, so others can experience it to any
significant degree far into the future, is a rare event.</p>

<p>Access to that rare moment is what is being purchased for 300k francs. We refer
to the painting as the “original”, but really the painting is only the
first-hand reproduction of the moment, which is the true original, and proximity
to the true original is what is being purchased. All other reproductions must be
based on this first-hand one (be they photographs or painted copies), and are
therefore second and third-hand.</p>

<p>Consider the value of a concert ticket; it is based on both how much in demand
the performance is, how close to the performance the seating section is, and how
many seats in that section there are. When one purchases the “original” <em>The
Gleaners</em>, one is purchasing a front-row ticket to a world-class performance at
a venue with only one seat. That is why it was worth 300k francs.</p>

<p>I have one final thing to say here and then I’ll move onto the topic at hand:
the history of the work compounds its value as well. <em>The Gleaners</em> conveys an
emotion, but knowing the critical reaction of the french elite at its first
unveiling can add to that emotion.</p>

<p>Again, from the <a href="https://en.wikipedia.org/wiki/The_Gleaners">wiki entry</a>:</p>

<blockquote>
  <p>Millet’s The Gleaners was also not perceived well due to its large size, 33
inches by 44 inches, or 84 by 112 centimetres. This was large for a painting
depicting labor. Normally this size of a canvas was reserved for religious or
mythological style paintings. Millet’s work did not depict anything
religiously affiliated, nor was there any reference to any mythological
beliefs. The painting illustrated a realistic view of poverty and the working
class. One critic commented that “his three gleaners have gigantic
pretensions, they pose as the Three Fates of Poverty…their ugliness and
their grossness unrelieved.”</p>
</blockquote>

<p>Now scroll back up and see if you don’t now have more affinity for the painting
than before you knew that. If so, then the face value just went up, just a
little bit.</p>

<h3 id="the-value-of-an-nft">The Value of an NFT</h3>

<p>With this acknowledgement of <em>why</em> people desire art, we can understand why they
would want an NFT depicting an artwork.</p>

<p>A few days ago an NFT of this image sold for almost $500k:</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/nfts/disaster-girl.jpg" target="_blank">
    <picture>
      <source media="(min-width: 1000px) and (min-resolution: 2.5dppx)" srcset="/img/nfts/2500px/disaster-girl.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.0dppx)" srcset="/img/nfts/2000px/disaster-girl.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 1.5dppx)" srcset="/img/nfts/1500px/disaster-girl.jpg" />
      <source media="(min-width: 500px), (min-resolution: 1.1dppx)" srcset="/img/nfts/1000px/disaster-girl.jpg" />
      <source srcset="/img/nfts/500px/disaster-girl.jpg" />
      <img style="max-height: 60vh;" src="/img/nfts/1000px/disaster-girl.jpg" alt="" />
    </picture>
  </a>
</div>

<p>Most of the internet knows this image as <em>Disaster Girl</em>, a meme which has been
around since time immemorial (from the internet’s perspective, anyway, in
reality it was taken in 2007). The moment captured is funny, the girl in the
image smiling as if she had set the fire which blazes in the background. But, as
with <em>The Gleaners</em>, the image itself isn’t everything. The countless usages of
the image, the original and all of its remixes, all passed around as memes on
the internet for the past 14 years, have all worked to add to the image’s
demand. <em>Disaster Girl</em> is no longer just a funny picture or a versatile meme
format, it’s a piece of human history and nostalgia.</p>

<p>Unlike physical paintings, however, internet memes are imminently copyable. If
they weren’t they could hardly function as memes! We can only have one
“original” <em>The Gleaners</em>, but anyone with a computer can have an exact, perfect
copy of the original <em>Disaster Girl</em>, such that there’s no true original. But if
I were to put up an NFT of <em>Disaster Girl</em> for sale, I wouldn’t get a damned
penny for it (probably). Why was that version apparently worth $500k?</p>

<p>The reason is that the seller is the girl in the image herself, now 21 years old
and in college. I have no particular connection to <em>Disaster Girl</em>, so buying an
NFT from me would be like buying a print of <em>The Gleaners</em> off some rando in the
street; just a shallow copy, worth only the material it’s printed on plus some
labor, and nothing more. But when Disaster Girl herself sells the NFT, then the
buyer is actually part of the moment, they are entering themselves into the
history of this meme that the whole world has taken a part in for the last 14
years! $500k isn’t so unreasonable in that light.</p>

<h3 id="property-on-the-internet">Property on the Internet</h3>

<p>I don’t make it a secret that I consider “intellectual property” to be a giant
fucking scam that the world has unfortunately bought into. Data, be it a
physical book or a digital file, is essentially free to copy, and so any price
placed on the copying or sharing of knowledge is purely artificial. But we don’t
have an alternate mechanism for paying producers of knowledge and art, and so we
continue to treat data as property even though it bears absolutely no
resemblance to anything of the kind.</p>

<p>Disaster Girl has not, to my knowledge, asserted any property rights on the
image of herself. Doing so in any real sense, beyond going after a handful of
high-value targets who might settle a lawsuit, is simply not a feasible option.
Instead, by selling an NFT, Disaster Girl has been compensated for her labor
(meager as it was) in a way which was proportional to its impact on the world,
all without the invocation of the law. A great success!</p>

<p>Actually, the labor was performed by Disaster Girl’s father, who took the
original image and sent it into a photo contest or something. What would have
happened if the NFT was sold in his name? I imagine that it would not have sold
for nearly as much. This makes sense to me, even if it does not make sense from
a purely economical point of view. Disaster Girl’s father did the work in the
moment, but being a notable figure to the general public is its own kind of
labor, and it’s likely that his daughter has born the larger burden over time.
The same logic applies to why we pay our movie stars absurd amounts even while
the crew makes a “normal” wage.</p>

<p>Should the father not then get compensated at all? I think he should, and I
think he could! If he were to produce an NFT of his own, of the exact same
image, it would also fetch a decent price. Probably not 6 figures, possibly not
even 4, but considering the actual contribution he made (taking a picture and
uploading it), I think the price would be fair. How many photographers get paid
anything at all for their off-hand pictures of family outings?</p>

<p>And this is the point I’d like to make: an NFT’s price, like in all art, is
proportional to the distance to the moment captured. The beauty is that this
distance is purely subjective; it is judged not by rules set down in law by
fallable lawyers, but instead by the public at large. It is, in essence, a
democritization of intellectual property disputes. If multiple people claim to
having produced a single work, let them all produce an NFT, and the market will
decide what each of their work is worth.</p>

<p>Will the market ever be wrong? Certainly. But will it distribute the worth more
incorrectly than our current system, where artists must sell their rights to a
large publisher in order to see a meager profit, while the publisher rakes in
the vastly larger share? I sincerely doubt it.</p>

<h3 id="content-creation">Content Creation</h3>

<p>Another interesting mechanism of NFTs is that some platforms (e.g.
<a href="https://rarible.com/">Rarible</a>) allow the seller to attach a royalty percentage to the NFT
being solde. When this is done it means the original seller will receive some
percentage of all future sales of that NFT.</p>

<p>I think this opens some interesting possibilities for content creators. Normally
a content creator would need to sell ads or subscriptions in order to profit
from their content, but if they instead/in addition sell NFTs associated with
their content (e.g. one per episode of their youtube show) they can add another
revenue stream. As their show, or whatever, begins to take off, older NFTs
become more valuable, and the content creator can take advantage of that new
increased value via royalties set on the NFTs.</p>

<p>There’s some further interesting side-effects that come from using NFTs in this
way. If a creator releases a work, and a corresponding NFT for that work, their
incentive is no longer to gate access to that work (as it would be in our
current IP system) or burden the work with advertisements and pleas for
subscriptions/donations. There’s an entirely new goalpost for the creator:
actual value to others.</p>

<p>The value of the NFT is based entirely and arbitrarily on other’s feelings
towards the original work, and so it is in the creator’s interest to increase
the visibility and virality of the work. We can expect a creator who has sold an
NFT for a work, with royalties attached, to actively ensure there is as
little gatekeeping around the work as possible, and to create work which is
completely platform-agnostic and available absolutely everywhere. Releasing a
work as public-domain could even become a norm, should NFTs prove more
profitable than other revenue streams.</p>

<h3 id="shill-gang">Shill Gang</h3>

<p>While the content creator’s relationship with their platform(s) will change
drastically, I also expect that their relationship with their fans, or really
their fan’s relationship with the creator’s work, will change even more. Fans
are no longer passive viewers, they can have an actual investment in a work’s
success. Where fans currently shill their favorite show or game or whatever out
of love, they can now also do it for personal profit. I think this is the worst
possible externality of NFTs I’ve encountered: internet fandom becoming orders
of magnitude more fierce and unbearable, as they relentlessly shill their
investments to the world at large.</p>

<p>There is one good thing to come out of this new fan/content relationship though,
and that’s the fan’s role in distribution and preservation of work. Since fans
now have a financial incentive to see a work persist into the future, they will
take it upon themselves to ensure that the works won’t accidentally fall off the
face of the internet (as things often do). This can be difficult currently since
work is often tied down with IP restrictions, but, as we’ve established, work
which uses NFTs for revenue is incentivized to <em>not</em> tie itself down in any way,
so fans will have much more freedom in this respect.</p>

<h3 id="art">Art</h3>

<p>It seems unlikely to me that art will cease to be created, or cease to be
valuable. The human creative instinct comes prior to money, and we have always
created art regardless of economic concerns. It’s true that the nature of our
art changes according to economics (don’t forget to hit that “Follow” button at
the top!), but if anything I think NFTs can change our art for the better. Our
work can be more to the point, more accessible, and less encumbered by legal
bullshit.</p>

<h2 id="fin">Fin</h2>

<p>That crypto cat is out of the bag, at this point, and I doubt if there’s
anything that can put it back. The world has never before had the tools that
cryptocurrency and related technologies (like NFTs) offer, and our lives will
surely change as new uses of these tools make themselves apparent. I’ve tried to
extrapolate some uses and changes that could come out of NFTs here, but I have
no doubt that I’ve missed or mistook some.</p>

<p>It’s my hope that this post has at least offered some food-for-thought related
to NFTs, beyond the endless hot takes and hype that can be found on social
media, and that the reader can now have a bigger picture view of NFTs and where
they might take us as a society, should we embrace them.</p>"""

+++
<p>NFT stands for “non-fungible token”. The “token” part refers to an NFT being a
token whose ownership is recorded on a blockchain. Pretty much all
cryptocurrencies, from bitcoin to your favorite shitcoin, could be called tokens
in this sense. Each token has exactly one owner, and ownership of the token can
be transferred from one wallet to another via a transaction on the blockchain.</p>

<p>What sets an NFT apart from a cryptocurrency is the “non-fungible” part.
Cryptocurrency tokens are fungible; one bitcoin is the same as any other bitoin
(according to the protocol, at least), in the same way as one US dollar holds as
much value as any other US dollar. Fungibility is the property of two units of
something being exactly interchangeable.</p>

<p>NFTs are <em>not</em> fungible. One is not the same as any other. Each has some piece
of data attached to it, and each is recorded separately on a blockchain as an
individual token. You can think of an NFT as a unique cryptocurrency which has a
supply of 1 and can’t be divided.</p>

<p>Depending on the protocol used to produce an NFT, the data attached to it might
be completely independent of its identity, even. It may be possible to produce
two NFTs with the exact same data attached to them (again, depending on the
protocol used), but even so those two NFTs will be independent and not
interchangeable.</p>

<h2 id="fud">FUD</h2>

<p>Before getting into why NFTs are interesting, I want to first address some
common criticism I see of them online (aka, in my twitter feed). The most
common, and unfortunately least legitimate, criticism has to do with the
environmental impact of NFTs. While the impact on energy usage and the
environment when talking about bitcoin is a topic worth going into, bitcoin
doesn’t support hosting NFTs and therefore that topic is irrelevant here.</p>

<p>Most NFTs are hosted on ethereum, which does have a comparable energy footprint
to bitcoin (it’s somewhat less than half, according to the internet). <em>However</em>,
ethereum is taking actual, concrete steps towards changing its consensus
mechanism from proof-of-work (PoW) to proof-of-stake (PoS), which will cut the
energy usage of the network down to essentially nothing. The rollout plan for
Ethereum PoS covers the next couple of years, and after that we don’t really
have to worry about the energy usage of NFTs any longer.</p>

<p>The other big criticism I hear is about the value and nature of art and what the
impact of NFTs are in that area. I’m going to talk more about this in this post,
but, simply put, I don’t think that the value and nature of art are immutable,
anymore than the form of art is immutable. Perhaps NFTs <em>will</em> change art, but
change isn’t bad in itself, and furthermore I don’t think they will actually
change it all that much. People will still produce art, it’s only the
distribution mechanism that might change.</p>

<h2 id="real-useful-boring-things">Real, Useful, Boring Things</h2>

<p>Most of the coverage around NFTs has to do with using them to represent
collectibles and art. I’d like to start by talking about other use-cases, those
where NFTs are actually “useful” (in the dull, practical sense).</p>

<p>Each NFT can carry some piece of data along with it. This data can be anything,
but for a practical use-case it needs to be something which indicates ownership
of some internet good. It <em>cannot</em> be the good itself. For example, an NFT which
contains an image does not really convey the ownership of that image; anyone can
copy the image data and own that image as well (intellectual property rights be
damned!).</p>

<p>A real use-case for NFTs which I’m already, if accidentally, taking advantage
of, is domain name registration. I am the proud owner of the
<a href="https://nfton.me/nft/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/7558304748055753202351203668187280010336475031529884349040105080320604507070">mediocregopher.eth</a> domain name (the <code class="language-plaintext highlighter-rouge">.eth</code> TLD is not yet in wide usage
in browsers, but one day!). The domain name’s ownership is indicated by an NFT:
whoever holds that NFT, which I currently do, has the right to change all
information attached to the <code class="language-plaintext highlighter-rouge">mediocregopher.eth</code> domain. If I want to sell the
domain all I need to do is sell the NFT, which can be done via an ethereum
transaction.</p>

<p>Domain names work well for NFTs because knowing the data attached to the NFT
doesn’t actually do anything for you. It’s the actual <em>ownership</em> of the NFT
which unlocks value. And I think this is the key rule for where to look to apply
NFTs to practical use-cases: the ownership of the NFT has to unlock some
functionality, not the data attached to it. The functionality has to be digital
in nature, as well, as anything related to the physical world is not as easily
guaranteed.</p>

<p>I haven’t thought of many further practical use-cases of NFTs, but we’re still
in early stages and I’m sure more will come up. In any case, the practical stuff
is boring, let’s talk about art.</p>

<h2 id="art-memes-and-all-wonderful-things">Art, Memes, and All Wonderful Things</h2>

<p>For many the most baffling aspect of NFTs is their use as collectibles. Indeed,
their use as collectibles is their <em>primary</em> use right now, even though these
collectibles procur no practical value for their owner; at best they are
speculative goods, small gambles, and at worst just a complete waste of money.
How can this be?</p>

<p>The curmudgeons of the world would have you believe that money is only worth
spending on goods which offer practical value. If the good is neither consumable
in a way which meets a basic need, nor produces other goods of further value,
then it is worthless. Obviously NFTs fall into the “worthless” category.</p>

<p>Unfortunately for them, the curmudgeons don’t live in reality. People spend
their money on stupid, pointless shit all the time. I’m prepared to argue that
people almost exclusively spend their money on stupid, pointless shit. The
monetary value of a good has very little to do with its ability to meet a basic
necessity or its ability to produce value (whatever that even really means), and
more to do with how owning the shiny thing or doing the fun thing makes us
stupid monkeys very happy (for a time).</p>

<p>Rather than bemoan NFTs, and our simple irrationality which makes them
desirable, let’s embrace them as a new tool for expressing our irrationality to
the world, a tool which we have yet to fully explore.</p>

<h3 id="a-moment-captured">A Moment Captured</h3>

<p>It’s 1857 and Jean-François Millet reveals to the world what would become one of
his best known works: <em>The Gleaners</em>.</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/nfts/gleaners.jpg" target="_blank">
    <picture>
      <source media="(min-width: 1000px) and (min-resolution: 3.0dppx)" srcset="/img/nfts/3000px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.5dppx)" srcset="/img/nfts/2500px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.0dppx)" srcset="/img/nfts/2000px/gleaners.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 1.5dppx)" srcset="/img/nfts/1500px/gleaners.jpg" />
      <source media="(min-width: 500px), (min-resolution: 1.1dppx)" srcset="/img/nfts/1000px/gleaners.jpg" />
      <source srcset="/img/nfts/500px/gleaners.jpg" />
      <img style="max-height: 60vh;" src="/img/nfts/1000px/gleaners.jpg" alt="" />
    </picture>
  </a>
</div>

<p>The painting depicts three peasants gleaning a field, the bulk of their harvest
already stacked high in the background. The <a href="https://en.wikipedia.org/wiki/The_Gleaners">wikipedia entry</a> has this
to say about the painting’s eventual final sale:</p>

<blockquote>
  <p>In 1889, the painting, then owned by banker Ferdinand Bischoffsheim, sold for
300,000 francs at auction. The buyer remained anonymous, but rumours were
that the painting was coveted by an American buyer. It was announced less than
a week later that Champagne maker Jeanne-Alexandrine Louise Pommery had
acquired the piece, which silenced gossip on her supposed financial issues
after leaving her grapes on the vines weeks longer than her competitors.</p>
</blockquote>

<p>I think we can all breathe a sigh of relief for Jeanne-Alexandrine.</p>

<p>I’d like to talk about <em>why</em> this painting was worth 300k francs, and really
what makes art valuable at all (aside from the money laundering and tax evasion
that high-value art enables). Millet didn’t merely take a picture using paints
and canvas, an exact replica of what his eyes could see. It’s doubtful this
scene ever played out in reality, exactly as depicted, at all! It existed only
within Millet himself.</p>

<p>In <em>The Gleaners</em> Millet captured far more than an image: the image itself
conveys the struggle of a humble life, the joy of the harvest, the history of
the french peasantry (and therefore the other french societal classes as well),
the vastness of the world compared to our little selves, and surely many other
things, each dependant on the viewer. The image conveys emotions, and most
importantly it conveys emotions captured at a particular moment, a moment which
no longer exists and will never exist again. The capturing of such a moment by
an artist capable of doing it some justice, so others can experience it to any
significant degree far into the future, is a rare event.</p>

<p>Access to that rare moment is what is being purchased for 300k francs. We refer
to the painting as the “original”, but really the painting is only the
first-hand reproduction of the moment, which is the true original, and proximity
to the true original is what is being purchased. All other reproductions must be
based on this first-hand one (be they photographs or painted copies), and are
therefore second and third-hand.</p>

<p>Consider the value of a concert ticket; it is based on both how much in demand
the performance is, how close to the performance the seating section is, and how
many seats in that section there are. When one purchases the “original” <em>The
Gleaners</em>, one is purchasing a front-row ticket to a world-class performance at
a venue with only one seat. That is why it was worth 300k francs.</p>

<p>I have one final thing to say here and then I’ll move onto the topic at hand:
the history of the work compounds its value as well. <em>The Gleaners</em> conveys an
emotion, but knowing the critical reaction of the french elite at its first
unveiling can add to that emotion.</p>

<p>Again, from the <a href="https://en.wikipedia.org/wiki/The_Gleaners">wiki entry</a>:</p>

<blockquote>
  <p>Millet’s The Gleaners was also not perceived well due to its large size, 33
inches by 44 inches, or 84 by 112 centimetres. This was large for a painting
depicting labor. Normally this size of a canvas was reserved for religious or
mythological style paintings. Millet’s work did not depict anything
religiously affiliated, nor was there any reference to any mythological
beliefs. The painting illustrated a realistic view of poverty and the working
class. One critic commented that “his three gleaners have gigantic
pretensions, they pose as the Three Fates of Poverty…their ugliness and
their grossness unrelieved.”</p>
</blockquote>

<p>Now scroll back up and see if you don’t now have more affinity for the painting
than before you knew that. If so, then the face value just went up, just a
little bit.</p>

<h3 id="the-value-of-an-nft">The Value of an NFT</h3>

<p>With this acknowledgement of <em>why</em> people desire art, we can understand why they
would want an NFT depicting an artwork.</p>

<p>A few days ago an NFT of this image sold for almost $500k:</p>

<div style="
  box-sizing: border-box;
  text-align: center;
  padding-left: 2em;
  padding-right: 2em;
  margin-bottom: 1em;">
  <a href="/img/nfts/disaster-girl.jpg" target="_blank">
    <picture>
      <source media="(min-width: 1000px) and (min-resolution: 2.5dppx)" srcset="/img/nfts/2500px/disaster-girl.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 2.0dppx)" srcset="/img/nfts/2000px/disaster-girl.jpg" />
      <source media="(min-width: 1000px) and (min-resolution: 1.5dppx)" srcset="/img/nfts/1500px/disaster-girl.jpg" />
      <source media="(min-width: 500px), (min-resolution: 1.1dppx)" srcset="/img/nfts/1000px/disaster-girl.jpg" />
      <source srcset="/img/nfts/500px/disaster-girl.jpg" />
      <img style="max-height: 60vh;" src="/img/nfts/1000px/disaster-girl.jpg" alt="" />
    </picture>
  </a>
</div>

<p>Most of the internet knows this image as <em>Disaster Girl</em>, a meme which has been
around since time immemorial (from the internet’s perspective, anyway, in
reality it was taken in 2007). The moment captured is funny, the girl in the
image smiling as if she had set the fire which blazes in the background. But, as
with <em>The Gleaners</em>, the image itself isn’t everything. The countless usages of
the image, the original and all of its remixes, all passed around as memes on
the internet for the past 14 years, have all worked to add to the image’s
demand. <em>Disaster Girl</em> is no longer just a funny picture or a versatile meme
format, it’s a piece of human history and nostalgia.</p>

<p>Unlike physical paintings, however, internet memes are imminently copyable. If
they weren’t they could hardly function as memes! We can only have one
“original” <em>The Gleaners</em>, but anyone with a computer can have an exact, perfect
copy of the original <em>Disaster Girl</em>, such that there’s no true original. But if
I were to put up an NFT of <em>Disaster Girl</em> for sale, I wouldn’t get a damned
penny for it (probably). Why was that version apparently worth $500k?</p>

<p>The reason is that the seller is the girl in the image herself, now 21 years old
and in college. I have no particular connection to <em>Disaster Girl</em>, so buying an
NFT from me would be like buying a print of <em>The Gleaners</em> off some rando in the
street; just a shallow copy, worth only the material it’s printed on plus some
labor, and nothing more. But when Disaster Girl herself sells the NFT, then the
buyer is actually part of the moment, they are entering themselves into the
history of this meme that the whole world has taken a part in for the last 14
years! $500k isn’t so unreasonable in that light.</p>

<h3 id="property-on-the-internet">Property on the Internet</h3>

<p>I don’t make it a secret that I consider “intellectual property” to be a giant
fucking scam that the world has unfortunately bought into. Data, be it a
physical book or a digital file, is essentially free to copy, and so any price
placed on the copying or sharing of knowledge is purely artificial. But we don’t
have an alternate mechanism for paying producers of knowledge and art, and so we
continue to treat data as property even though it bears absolutely no
resemblance to anything of the kind.</p>

<p>Disaster Girl has not, to my knowledge, asserted any property rights on the
image of herself. Doing so in any real sense, beyond going after a handful of
high-value targets who might settle a lawsuit, is simply not a feasible option.
Instead, by selling an NFT, Disaster Girl has been compensated for her labor
(meager as it was) in a way which was proportional to its impact on the world,
all without the invocation of the law. A great success!</p>

<p>Actually, the labor was performed by Disaster Girl’s father, who took the
original image and sent it into a photo contest or something. What would have
happened if the NFT was sold in his name? I imagine that it would not have sold
for nearly as much. This makes sense to me, even if it does not make sense from
a purely economical point of view. Disaster Girl’s father did the work in the
moment, but being a notable figure to the general public is its own kind of
labor, and it’s likely that his daughter has born the larger burden over time.
The same logic applies to why we pay our movie stars absurd amounts even while
the crew makes a “normal” wage.</p>

<p>Should the father not then get compensated at all? I think he should, and I
think he could! If he were to produce an NFT of his own, of the exact same
image, it would also fetch a decent price. Probably not 6 figures, possibly not
even 4, but considering the actual contribution he made (taking a picture and
uploading it), I think the price would be fair. How many photographers get paid
anything at all for their off-hand pictures of family outings?</p>

<p>And this is the point I’d like to make: an NFT’s price, like in all art, is
proportional to the distance to the moment captured. The beauty is that this
distance is purely subjective; it is judged not by rules set down in law by
fallable lawyers, but instead by the public at large. It is, in essence, a
democritization of intellectual property disputes. If multiple people claim to
having produced a single work, let them all produce an NFT, and the market will
decide what each of their work is worth.</p>

<p>Will the market ever be wrong? Certainly. But will it distribute the worth more
incorrectly than our current system, where artists must sell their rights to a
large publisher in order to see a meager profit, while the publisher rakes in
the vastly larger share? I sincerely doubt it.</p>

<h3 id="content-creation">Content Creation</h3>

<p>Another interesting mechanism of NFTs is that some platforms (e.g.
<a href="https://rarible.com/">Rarible</a>) allow the seller to attach a royalty percentage to the NFT
being solde. When this is done it means the original seller will receive some
percentage of all future sales of that NFT.</p>

<p>I think this opens some interesting possibilities for content creators. Normally
a content creator would need to sell ads or subscriptions in order to profit
from their content, but if they instead/in addition sell NFTs associated with
their content (e.g. one per episode of their youtube show) they can add another
revenue stream. As their show, or whatever, begins to take off, older NFTs
become more valuable, and the content creator can take advantage of that new
increased value via royalties set on the NFTs.</p>

<p>There’s some further interesting side-effects that come from using NFTs in this
way. If a creator releases a work, and a corresponding NFT for that work, their
incentive is no longer to gate access to that work (as it would be in our
current IP system) or burden the work with advertisements and pleas for
subscriptions/donations. There’s an entirely new goalpost for the creator:
actual value to others.</p>

<p>The value of the NFT is based entirely and arbitrarily on other’s feelings
towards the original work, and so it is in the creator’s interest to increase
the visibility and virality of the work. We can expect a creator who has sold an
NFT for a work, with royalties attached, to actively ensure there is as
little gatekeeping around the work as possible, and to create work which is
completely platform-agnostic and available absolutely everywhere. Releasing a
work as public-domain could even become a norm, should NFTs prove more
profitable than other revenue streams.</p>

<h3 id="shill-gang">Shill Gang</h3>

<p>While the content creator’s relationship with their platform(s) will change
drastically, I also expect that their relationship with their fans, or really
their fan’s relationship with the creator’s work, will change even more. Fans
are no longer passive viewers, they can have an actual investment in a work’s
success. Where fans currently shill their favorite show or game or whatever out
of love, they can now also do it for personal profit. I think this is the worst
possible externality of NFTs I’ve encountered: internet fandom becoming orders
of magnitude more fierce and unbearable, as they relentlessly shill their
investments to the world at large.</p>

<p>There is one good thing to come out of this new fan/content relationship though,
and that’s the fan’s role in distribution and preservation of work. Since fans
now have a financial incentive to see a work persist into the future, they will
take it upon themselves to ensure that the works won’t accidentally fall off the
face of the internet (as things often do). This can be difficult currently since
work is often tied down with IP restrictions, but, as we’ve established, work
which uses NFTs for revenue is incentivized to <em>not</em> tie itself down in any way,
so fans will have much more freedom in this respect.</p>

<h3 id="art">Art</h3>

<p>It seems unlikely to me that art will cease to be created, or cease to be
valuable. The human creative instinct comes prior to money, and we have always
created art regardless of economic concerns. It’s true that the nature of our
art changes according to economics (don’t forget to hit that “Follow” button at
the top!), but if anything I think NFTs can change our art for the better. Our
work can be more to the point, more accessible, and less encumbered by legal
bullshit.</p>

<h2 id="fin">Fin</h2>

<p>That crypto cat is out of the bag, at this point, and I doubt if there’s
anything that can put it back. The world has never before had the tools that
cryptocurrency and related technologies (like NFTs) offer, and our lives will
surely change as new uses of these tools make themselves apparent. I’ve tried to
extrapolate some uses and changes that could come out of NFTs here, but I have
no doubt that I’ve missed or mistook some.</p>

<p>It’s my hope that this post has at least offered some food-for-thought related
to NFTs, beyond the endless hot takes and hype that can be found on social
media, and that the reader can now have a bigger picture view of NFTs and where
they might take us as a society, should we embrace them.</p>
