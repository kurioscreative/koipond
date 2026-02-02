# 🐟 Koipond

**Throw a stone into your pond of code. Watch the ripples rewrite the shore.**

Koipond finds the most recently changed Ruby file in your project, discovers its relatives, and asks Claude to reimagine them. It is built from Ruby's intrinsic qualities — the features that make Ruby _Ruby_ and not just another language with different syntax.

This is not a production tool. This is a toy. All the best things are.

---

## The Idea

You change a file. Its neighbors should know. They should adapt, harmonize, evolve. But they just sit there — frozen in their last known state, drifting slowly out of tune.

What if one command could ripple your change outward?

```
$ koi --poignant
🌊 Pond(my_project, 14 stones)
Last touched: 🪨 user.rb touched=14:32:07
Kin: 🪨 authentication.rb, 🪨 profile.rb

🔮 Reflection: 2 files reimagined from 🪨 user.rb
```

That's Koipond. One stone, thrown by you. Ripples carried by Claude. The pond settles into a new shape.

---

## The Architecture

Koipond is built around four core concepts, each demonstrating Ruby patterns:

| Concept        | What It Is                            | Ruby Features                           |
| -------------- | ------------------------------------- | --------------------------------------- |
| **Stone**      | A Ruby file that changed              | `Struct`, `Comparable`, endless methods |
| **Pond**       | Your project directory                | `Enumerable`, `method_missing`          |
| **Wave**       | The ripple carrying context to Claude | Lambdas as strategy objects             |
| **Reflection** | What comes back                       | `tap`, `then`, immutable state          |

---

## A Tour of Ruby, Through Koipond

Every feature of Koipond exists to showcase something about Ruby. Here is the tour.

### 1. Refinements — Polite Metamorphosis

Most languages lock their core types. Ruby opens them — and Refinements let you open them _politely_, scoped to wherever you say `using`:

```ruby
module Koipond::StringSwims
  refine String do
    def ripple!(style: :gentle)
      to_stone.throw!(style: style)
    end
  end
end

# Later, in your code:
using Koipond::StringSwims
"app/models/user.rb".ripple!
```

The String class gains `.ripple!` only where you ask for it. Everywhere else, strings are still just strings. It is monkey-patching that learned manners.

### 2. Struct — Ceremony-Free Objects

When a full class is too much and a Hash is too little:

```ruby
Stone = Struct.new(:path, :pond, keyword_init: true) do
  include Comparable

  def <=>(other)
    path.heartbeat <=> other.path.heartbeat
  end
end
```

One line gives you `initialize`, `==`, `to_a`, `members`, `[]`, `each_pair`, and more. Then you open the block and add only what's unique. Ruby believes you shouldn't write the same boilerplate twice.

### 3. Comparable — Define One Method, Get Six

Include `Comparable` and define `<=>`. Ruby gives you `<`, `<=`, `==`, `>=`, `>`, `between?`, and `clamp`. For free. Forever.

Stones sort by modification time. The most recently touched file rises to the top. We wrote one method. Ruby wrote the rest.

### 4. Enumerable — Define One Method, Get Sixty

The Pond includes `Enumerable` and defines `each`. Now the Pond responds to `map`, `select`, `reduce`, `sort`, `min`, `max`, `flat_map`, `group_by`, `tally`, `any?`, `none?`, `count`, `take`, `zip`, `chunk`, `each_slice`, `each_cons`... roughly sixty methods, all from one.

This is Ruby's philosophy of generosity. You do the minimum. Ruby multiplies it.

### 5. method_missing — The Living Object

When you call a method that doesn't exist, Ruby doesn't just crash. It asks the object: _"Do you want to handle this?"_

```ruby
pond = Koipond.pond
pond.user_model          # finds user_model.rb
pond.user_model.kin      # its relatives
pond.user_model.throw!   # reimagine its world
```

Three words. Reads like English. The Pond intercepts unknown method names, searches its stones, and returns the matching file. The pond _feels alive_.

(Always pair with `respond_to_missing?` — that's the contract.)

### 6. Lambdas as Strategy Objects

Wave styles are stored as lambdas in a frozen Hash:

```ruby
STYLES = {
  gentle:   ->(stone, kin) { "..." },
  radical:  ->(stone, kin) { "..." },
  poignant: ->(stone, kin) { "..." },
}.freeze
```

Lambdas are objects. You can store them, pass them, call them later. They close over their environment. They _are_ the environment, preserved in amber.

This is functional programming hidden inside an object-oriented language. Ruby doesn't make you choose.

### 7. Blocks — Ruby's Soul

Every method in Koipond that accepts a block uses `&block` or `yield`:

```ruby
stone.throw!(style: :gentle) do |wave|
  wave.style = :radical   # change your mind mid-throw
end
```

Blocks are Ruby's most important feature. They let the caller customize behavior without subclassing, without config objects, without ceremony. Just pass a block. The method decides when to call it.

### 8. Lazy Enumerators — Infinite Patience

`deep_kin` returns a lazy enumerator that crawls the relationship graph breadth-first:

```ruby
stone.deep_kin(depth: 5).first(3)
```

Nothing executes until you ask for values. It could traverse the entire project graph, but it only does the work you need. `.lazy` is the magic word.

### 9. TracePoint — The Nature Documentary

```ruby
Koipond.narrate!
```

TracePoint lets you observe method calls as they happen — live, without modifying any code. Koipond uses it to narrate its own execution like a nature documentary:

```
  🐟 the pond remembers who moved last
  🐟 reading the stone's inscription
  🐟 searching for family in the water
  🐟 a stone arcs through the air
  🐟 whispering to Claude across the wire
  🐟 ripples spreading outward
```

Most languages need AOP frameworks for this. Ruby has it built in.

### 10. The Grand Trick — Library and Program in One

```ruby
if __FILE__ == $0
  # this only runs when the file is executed directly
end
```

`koipond.rb` is both a library (require it) and a program (run it). Ruby doesn't mind. Ruby never minds.

### 11. Symbol#to_proc — The Tiny Miracle

```ruby
stones.map(&:to_s)
```

`&:to_s` is shorthand for `{ |x| x.to_s }`. It works because `Symbol#to_proc` returns a Proc that sends that message to whatever it receives. Found everywhere in Ruby. Invisible once you see it.

### 12. ObjectSpace — The Hidden Census

```ruby
ObjectSpace.each_object(Koipond::Stone).count
```

Every object that exists in Ruby's heap can be found through ObjectSpace. Every Stone you've ever created is there — alive in memory until the garbage collector decides otherwise.

Like memories. Present until forgotten. Never on purpose.

---

## Prism Integration (v0.2)

When Prism is available (Ruby 3.3+ or the `prism` gem), Koipond gains structural understanding:

- **Shape extraction**: AST-powered analysis of classes, methods, attributes, includes
- **Semantic diffs**: Instead of "file changed," Claude learns "added `<=>` method, now includes Comparable"
- **Deep kin discovery**: Find relatives through constant references, superclass relationships, shared includes
- **Error tolerance**: Parse broken code mid-edit without stopping the ripple

Instead of telling Claude "this file changed," Koipond now explains _what_ changed:

```
+ Added: public fetch(key, default = nil)
~ Changed: initialize
    was: (name)
    now: (name, options = {})
- Removed: private legacy_load

Magnitude: 8 (structural)
```

See [PRISM.md](PRISM.md) for the full story.

---

## Usage

### CLI

```bash
# Gentle ripple from the most recently changed file
koi

# Radical reimagining
koi --radical

# In _why's spirit
koi --poignant

# Watch the internal narration
koi --trace

# Specify a project
koi ~/projects/my_app --radical --trace
```

### As a Library

```ruby
require 'koipond'

pond = Koipond.pond('~/projects/my_app')
pond                          #=> 🌊 Pond(my_app, 14 stones)
pond.last_touched             #=> #<Stone user.rb touched=14:32:07>
pond.user                     #=> #<Stone user.rb touched=14:32:07>  (method_missing magic)
pond.user.kin                 #=> [#<Stone auth.rb>, #<Stone profile.rb>]
pond.user.deep_kin.first(5)   #=> lazy traversal, 5 relatives deep

# Throw and preview
pond.user.throw!(style: :poignant).preview

# Throw and apply
pond.user.throw!(style: :radical).apply!

# Narrate everything
Koipond.narrate!
pond.throw!
```

### Using Refinements

```ruby
require 'koipond'
using Koipond::StringSwims

# Now strings can become stones
"app/models/user.rb".ripple!(style: :gentle)
```

---

## Examples

The `examples/` directory contains demonstrations:

```bash
# A garden that grows (Seed → Flower → Basket)
ls examples/garden/

# Prism vs old AST comparison
ruby examples/prism_features.rb

# Interactive session replay
ruby examples/sim.rb
```

---

## Installation

```bash
gem install koipond
```

Or just drop `lib/koipond.rb` anywhere and `require` it. It's one file. \_why would approve.

### Requirements

- Ruby >= 3.1 (3.3+ for native Prism support)
- [Claude CLI](https://github.com/anthropics/claude-cli) installed and in PATH

---

## In the Spirit Of

**\_why the lucky stiff** taught us that programming is not just engineering. It is expression. It is play. It is writing a letter to your future self, and maybe to a fox or two along the way.

He gave us Camping (a web framework in 4KB), Shoes (a GUI toolkit for beginners), and Hpricot (an HTML parser that was fast and friendly). He wrote _Why's (Poignant) Guide to Ruby_, which is the only programming book that has a soundtrack.

Then he disappeared. All his code, gone from the internet. Because maybe the point was never the code. Maybe the point was the feeling you got when you read it.

Koipond is a small attempt to chase that feeling.

> _"For now, put your code in a safe. Go play outside."_
>
> — \_why

---

## License

MIT. Take it. Change it. Make it yours. That's what Ruby is for.
