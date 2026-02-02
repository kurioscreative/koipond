# Prism Pond — When Koipond Learns to See

> _"And what is the use of a book," thought Alice, "without pictures or conversation?"_

The original Koipond found relationships through text: regex for `require`, string matching for filenames. It was like finding your family by looking at who shares your last name in the phone book. It works. But it misses stepchildren, in-laws, and the neighbor who raised you.

Prism gives Koipond eyes.

---

## What Prism Is

Prism (formerly YARP) shipped as a bundled gem in Ruby 3.3 and became the default parser in Ruby 3.4. It replaces three separate parsing systems — `parse.y`, `Ripper`, and `RubyVM::AbstractSyntaxTree` — with a single, portable, error-tolerant parser written in C with bindings for Ruby, Rust, JavaScript, and Java.

The old parsers were built for the runtime to execute code. Prism was built for tools to _understand_ code. That distinction changes everything.

---

## The Seven Gifts of Prism

### 1. Named Nodes, Not Numbered Children

**Old AST:**

```ruby
node.type          # => :FCALL
node.children[0]   # => :require      (what's at index 0? Hope you remember)
node.children[1]   # => LIST node     (what's LIST? It's... a list)
  .children[0]     # => STR node
    .children[0]   # => "json"        (three levels deep, all positional)
```

**Prism:**

```ruby
node.class         # => Prism::CallNode
node.name          # => :require
node.arguments     # => ArgumentsNode
  .arguments       # => [StringNode]
    .first         # => StringNode
      .unescaped   # => "json"        (named all the way down)
```

The difference is legibility. The old AST is a treasure map. Prism is a street address.

### 2. The Visitor Pattern — Walking With Intention

**Old AST:**

```ruby
def walk(node, &block)
  return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
  block.call(node)
  node.children.each { |c| walk(c, &block) }
end

walk(ast) do |node|
  case node.type
  when :DEFN then ...
  when :FCALL then ...
  when :CONST then ...
  end
end
```

**Prism:**

```ruby
class MyVisitor < Prism::Visitor
  def visit_def_node(node)
    # I only fire for method definitions
    node.name        # => :swim
    node.parameters  # => ParametersNode
    super            # visit my children
  end

  def visit_call_node(node)
    # I only fire for method calls
    super
  end
end

Prism.parse(source).value.accept(MyVisitor.new)
```

The Visitor knows about every node type. You override only the ones you care about. Everything else is visited silently. The old AST makes you walk the tree yourself and switch on types. Prism does the walking and dispatches to you.

This is the difference between fishing with a net (catch everything, sort later) and fishing with a fly (attract exactly what you want).

### 3. Pattern Matching — Describing the Shape of Code

```ruby
Prism.parse(source).value.statements.body.each do |node|
  case node
  in Prism::CallNode[
       name: :require | :require_relative => type,
       arguments: Prism::ArgumentsNode[
         arguments: [Prism::StringNode => str]
       ]
     ]
    puts "#{type} '#{str.unescaped}'"
  end
end
```

This reads as English: _"Find a call named `require` or `require_relative`, whose first argument is a string, and give me the type and the string."_

The pattern IS the documentation. You don't need comments explaining what the code searches for — the pattern literally describes the tree structure it matches.

This is the most \_why thing about Prism. \_why wrote code that read like stories. Pattern matching on ASTs lets you write parsers that read like descriptions.

### 4. Error Tolerance — Grace Under Syntax Errors

```ruby
broken_code = "def greet(name\n  puts name\nend"

# Old AST:
RubyVM::AbstractSyntaxTree.parse(broken_code)
# => SyntaxError! Nothing. No AST. Gone.

# Prism:
result = Prism.parse(broken_code)
result.success?    # => false
result.errors      # => [Diagnostic("expected ')'"...)]
result.value       # => ProgramNode — a PARTIAL but USABLE AST
```

Prism says: _"I see you're not finished. Let me understand what I can."_

For Koipond, this means the ripple never stops for a typo. You save mid-thought, with a missing `end` or a stray comma, and Koipond can still parse the file, understand its shape, find its kin, and know what changed. The old parser demands perfection before it'll speak to you.

### 5. Comments — The Author's Voice Preserved

```ruby
result = Prism.parse(source)
result.comments.each do |comment|
  comment.location.start_line   # which line
  comment.location.slice        # the text itself
end
```

The old AST throws comments away. They're invisible. Destroyed. As if the programmer never wrote them.

Prism preserves every comment with its exact location. This means Koipond can:

- Read YARD annotations (`@param`, `@return`, `@api public`)
- Find TODO/FIXME markers and tell Claude to respect them
- Match comments to the methods they document (by proximity)
- Instruct Claude to _update_ comments when rewriting code, not destroy them

Comments are the author's voice. Deleting them is like rewriting a letter and throwing away the signature.

### 6. Locations — Byte-Precise Coordinates

```ruby
node = ... # any Prism node
loc = node.location

loc.start_offset    # byte 142 from start of file
loc.end_offset      # byte 198
loc.start_line      # line 14
loc.start_column    # column 4
loc.end_line        # line 18
loc.end_column      # column 7
loc.slice           # "def swim(direction = :north, speed: 1.0)\n    Fish.new(self)..."
```

`.slice` is the killer feature. It returns the _exact source text_ of any node — a method, a class, an argument, a constant reference. No file reading. No regex extraction. No line-range slicing with off-by-one errors.

For Koipond, this enables **surgical replacement**: change one method body, leave every other byte identical. The old AST gives you line ranges, which is like performing surgery with oven mitts.

### 7. Rich Parameter Information

```ruby
# def initialize(name, depth: 10, temperature: DEFAULT_TEMP)

node.parameters.requireds
# => [RequiredParameterNode(name: :name)]

node.parameters.keywords
# => [
#   OptionalKeywordParameterNode(name: :depth, value: IntegerNode(10)),
#   OptionalKeywordParameterNode(name: :temperature, value: ConstantReadNode(:DEFAULT_TEMP))
# ]
```

Prism doesn't just tell you a method has parameters — it tells you their names, their types (required/optional/keyword/rest/block), and their default values _as AST nodes_. It can distinguish a literal default (`10`) from a constant default (`DEFAULT_TEMP`) from a computed default (`Time.now`).

The old AST's ARGS node is a positional array whose structure changes between Ruby versions. Even Ruby core developers have to look up what goes where.

---

## How This Transforms Koipond

### Kin Discovery: From Name-Matching to Dependency-Tracing

**v0.1 (regex):**

1. Scan for `require_relative` with a regex
2. Grep for the filename stem in other files

**v0.2 (Prism):**

1. Parse the AST → extract all constant references (`Fish`, `Stone`, `Pathname`)
2. Parse every file in the pond → find which files _define_ those constants
3. Check superclass relationships (`class Koipond < Fish` → Fish is kin)
4. Check shared module includes (both include `Comparable`? interesting.)
5. Check shared constant references (both reference `Config`? worth examining.)

The difference: v0.1 finds files that mention your name. v0.2 finds files that depend on your existence.

### Change Understanding: From "Something Changed" to "Here's What"

**v0.1:** "pond.rb was modified. Here's the full source."

**v0.2:**

```
+ Added: public <=>(other)          (3 lines)
+ Added: public drain!()            (4 lines)
~ Changed: swim() → swim(direction = :north, speed: 1.0)
+ Added: attr_reader :depth
+ Added: attr_reader :temperature
+ Now includes: Comparable
+ Now references: Pathname
- No longer references: Dir
Magnitude: 14 (architectural)
```

Claude gets a structural diff. It knows exactly what happened and can make surgical, targeted changes to kin files instead of wholesale rewrites.

### Prompt Quality: 70% Less Tokens, 3x More Signal

**Before (v0.1 prompt):**

```
Here is pond.rb (45 lines of raw source).
Here is fish.rb (30 lines of raw source).
Please update fish.rb to match.
```

**After (v0.2 prompt):**

```
pond.rb structural changes:
  + attr_reader :depth
  + include Comparable
  + def <=>(other)
  Magnitude: architectural

fish.rb shape:
  Methods: initialize(pond), dive(direction)
  References: Pond
  Relationship: Fish.new(self) — Fish takes a Pond in its constructor

Please update fish.rb to handle Pond's new :depth attribute
and sortability (Comparable/<=>).
```

Same task. The LLM receives understanding, not raw text.

---

## Running the Demonstrations

```bash
# The shape/diff system (works on Ruby 3.2+ via fallback)
ruby examples/prism_features.rb

# The interactive simulation
ruby examples/sim.rb

# The full Koipond CLI (with Claude)
koi --poignant /path/to/project
```

On Ruby 3.3+, install the Prism gem or use the bundled version:

```ruby
require 'prism'
# All ShapeVisitor, Parser, DeepKin features become live
```

---

## The Shape of Things

The `Shape` is the central abstraction. It represents what a file looks like from the outside — its promises, its handshake with the world:

```ruby
shape = Koipond::Parser.parse_shape(source)

shape.classes           # => ["Pond"]
shape.modules           # => ["Ocean"]
shape.superclasses      # => {"Pond" => "Habitat"}
shape.includes          # => [Inclusion(:include, "Enumerable"), ...]
shape.attrs             # => [Attribute(:attr_reader, :name), ...]
shape.methods           # => [Method(:initialize, :public, "(name, depth: 10)"), ...]
shape.external_constants # => Set["Fish", "Pathname", "Stone"]
shape.public_interface   # => { methods: [...], readable: [:name, :depth], ... }
```

Two Shapes can be diffed:

```ruby
diff = Koipond::ShapeDiff.new(before: old_shape, after: new_shape)
diff.methods_added       # => [Method(:drain!, :public, "()")]
diff.methods_changed     # => [MethodChange(:swim, before: "()", after: "(direction, speed:)")]
diff.attrs_added         # => [Attribute(:attr_reader, :depth)]
diff.magnitude           # => 14
diff.severity            # => "architectural"
```

The diff becomes the core of what Claude receives.

---

## Three Layers of Understanding

```
┌─────────────────────────────────────────────────┐
│  Layer 3: Intent (why)                          │
│  Comments, YARD docs, naming conventions        │
│  "This method exists because..."                │
│  → Only Prism can see this (comments preserved) │
├─────────────────────────────────────────────────┤
│  Layer 2: Structure (what)                      │
│  Classes, methods, params, constants, includes  │
│  "This file defines Pond with 5 public methods" │
│  → Prism excels, old AST partially works        │
├─────────────────────────────────────────────────┤
│  Layer 1: Text (how)                            │
│  Raw source code, line-by-line                  │
│  "Here's 45 lines of Ruby"                      │
│  → Where original Koipond lives (regex, grep)       │
└─────────────────────────────────────────────────┘
```

Prism lifts Koipond from Layer 1 to Layer 2, with glimpses into Layer 3. Each layer up means Claude needs less context to make better changes.

---

## Data.define vs Struct — Immutable Memories

This exploration introduced `Data.define` (Ruby 3.2+) alongside `Struct`:

```ruby
# Data: immutable. A photograph.
Requirement = Data.define(:type, :path, :location)
req = Requirement.new(type: :require, path: "json", location: nil)
req.frozen?  # => true, always

# Struct: mutable. A living thing.
Shape = Struct.new(:methods, :attrs, :classes, keyword_init: true)
shape = Shape.new(methods: [])
shape.methods << something  # fine, it's alive
shape.freeze                # now it's a photograph too
```

Shapes are Structs because they're built incrementally by the Visitor. Once built, we call `.solidify!` which freezes them. After that, they're as immutable as Data. The past cannot be edited. Only the future is open.

---

## What's Next

Speculative directions, flagged as such:

**AST-aware file watching.** Instead of watching file mtimes, watch for _structural_ changes. If you reformat whitespace, the AST doesn't change — no ripple needed. If you add a method, the AST changes — ripple. This eliminates noise.

**Cross-file type inference.** If `Fish.new(self)` is called inside `Pond`, and we can see `Fish#initialize` takes a `Pond`, we can infer the type relationship without explicit requires. Prism's rich parameter nodes make this feasible.

**Semantic diff visualization.** Show the user a map of their project where changed files glow, kin files pulse, and the relationships are drawn as lines. Prism's location data gives us exact coordinates for every symbol.

**Comment-as-contract.** If a YARD annotation says `@param depth [Integer]` and the code changes `depth` to accept a String, that's a contract violation. Prism can detect this; the old parser can't even see the comment.

---

> _"When you don't create things, you become defined by your tastes rather than ability."_ — \_why

Prism is Ruby's gift to the tools that understand Ruby. Koipond is a small tool that uses that gift to let Claude understand your code — not as text, but as structure, intention, and relationship.

Throw a stone. The pond has learned to see.
