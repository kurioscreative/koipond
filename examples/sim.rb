# encoding: utf-8
# frozen_string_literal: false
#
# ═══════════════════════════════════════════════════════════════
#
#  sim.rb — A simulated IRB session with Koi
#
#  This is the experience of playing with Koi.
#  Every Ruby feature fires live. The only mock is Claude's
#  response (because we don't have the CLI here).
#  Everything else — the parsing, the kin discovery,
#  the shapes, the diffs, the narration — is real.
#
#  Run:  ruby examples/sim.rb
#
# ═══════════════════════════════════════════════════════════════

require_relative '../lib/koi'

# ── ANSI Colors ────────────────────────────────────────────

module C
  def self.cyan(s)    = "\e[36m#{s}\e[0m"
  def self.green(s)   = "\e[32m#{s}\e[0m"
  def self.yellow(s)  = "\e[33m#{s}\e[0m"
  def self.magenta(s) = "\e[35m#{s}\e[0m"
  def self.red(s)     = "\e[31m#{s}\e[0m"
  def self.dim(s)     = "\e[2m#{s}\e[0m"
  def self.bold(s)    = "\e[1m#{s}\e[0m"
  def self.italic(s)  = "\e[3m#{s}\e[0m"
end

# ── Simulated IRB ──────────────────────────────────────────

$prompt_num = 0

def irb_prompt
  $prompt_num += 1
  C.bold("irb(koi):#{format('%03d', $prompt_num)}> ")
end

def irb_result(s)
  C.green("=> #{s}")
end

def irb_puts(s)
  puts "   #{s}"
end

def type(text, speed: 0.018)
  print irb_prompt
  text.each_char do |ch|
    print C.cyan(ch)
    sleep(speed) unless ENV['FAST']
  end
  puts
  sleep(0.3) unless ENV['FAST']
end

def pause(seconds = 1.0)
  sleep(seconds) unless ENV['FAST']
end

def narrator(text)
  puts
  puts C.dim(C.italic("  # #{text}"))
  puts
  pause(0.5)
end

def section(title)
  puts
  puts C.bold(C.magenta("  ═══ #{title} ═══"))
  puts
  pause(0.8)
end

def fish(text)
  puts "  #{C.cyan('🐟')} #{C.dim(text)}"
  pause(0.2)
end

# ═══════════════════════════════════════════════════════════════
#  Override Koi's Wave to mock Claude's response
# ═══════════════════════════════════════════════════════════════

module Koi
  class Wave
    # Override propagate! to use mock response
    def propagate!
      kin = stone.kin
      if kin.empty?
        return Reflection.empty("#{stone} has no kin. It ripples alone.")
      end

      mock_response = generate_mock_response(kin)

      Reflection.new(
        stone:    stone,
        kin:      kin,
        response: mock_response,
        rewrites: parse_rewrites(mock_response),
      )
    end

    private

    def generate_mock_response(kin)
      response = ""

      kin.each do |k|
        new_content = k.essence.dup

        case k.path.basename.to_s
        when 'flower.rb'
          new_content.sub!(
            'def initialize(seed, color: nil)',
            'def initialize(seed, color: nil, variety: seed.name)'
          )
          new_content.sub!(
            "@color = color || PALETTES.fetch(seed.name, :white)\n    @bloomed_at = Time.now",
            "@color = color || PALETTES.fetch(seed.name, :white)\n    @variety = variety\n    @bloomed_at = Time.now"
          )
          new_content.sub!(
            'attr_reader :seed, :color, :bloomed_at',
            'attr_reader :seed, :color, :variety, :bloomed_at'
          )
          new_content.sub!(
            "  def to_s\n    \"\#{color} \#{seed.name}\"\n  end",
            "  def to_s\n    \"\#{color} \#{variety}\"\n  end\n\n  def rare?\n    !Seed::VARIETIES.include?(variety)\n  end"
          )
        when 'gardener.rb'
          new_content.sub!(
            "  def plant(seed_name)\n    Seed.new(seed_name, soil: soil)\n  end",
            "  def plant(seed_name)\n    raise ArgumentError, \"Unknown variety: \#{seed_name}\" unless Seed::VARIETIES.include?(seed_name)\n    Seed.new(seed_name, soil: soil)\n  end\n\n  def plant_rare(name, variety:)\n    Seed.new(name, soil: soil)\n  end"
          )
          new_content.sub!(
            '  def to_s',
            "  def available_varieties\n    Seed::VARIETIES\n  end\n\n  def to_s"
          )
        when 'basket.rb'
          new_content.sub!(
            "  def bouquet\n    group_by(&:color).transform_values(&:size)\n  end",
            "  def bouquet\n    group_by(&:color).transform_values(&:size)\n  end\n\n  def by_variety\n    group_by(&:variety)\n  end\n\n  def varieties\n    map(&:variety).uniq.sort\n  end"
          )
        when 'soil.rb'
          new_content.sub!(
            "  def to_s\n    \"Soil(n=\#{nutrients}, m=\#{moisture}, ph=\#{ph})\"\n  end",
            "  def supports?(variety)\n    case variety\n    when :lavender then ph > 6.0\n    when :foxglove then moisture > 0.4\n    else fertile?\n    end\n  end\n\n  def to_s\n    \"Soil(n=\#{nutrients}, m=\#{moisture}, ph=\#{ph})\"\n  end"
          )
        end

        response += "=== #{k.path} ===\n#{new_content}\n"
      end

      response
    end
  end

  # Override narrate to use our fish helper
  TALES = {
    'last_touched' => 'the pond remembers who moved last',
    'kin'          => 'searching for family in the water',
    'deep_kin'     => 'following the current deeper...',
    'throw!'       => 'a stone arcs through the air',
    'propagate!'   => 'ripples spreading outward',
    'apply!'       => 'the future takes shape',
    'preview'      => 'peering into what might be',
    'acquaintances'=> 'reading the address book',
    'mentioned_by' => 'who speaks this name?',
    'essence'      => "reading the stone's inscription",
    'resolve'      => 'tracing a path through the pond',
    'external_constants' => 'who do I reach for at runtime?',
    'describe'     => 'the shape speaks',
  }.freeze

  @trace = nil

  def self.narrate!
    @trace = TracePoint.new(:call) do |tp|
      next unless tp.defined_class.to_s.include?('Koi')
      tale = TALES[tp.method_id.to_s]
      if tale
        fish(tale)
      elsif rand < 0.08
        fish("#{tp.method_id} stirs beneath the surface")
      end
    end
    @trace.enable
  end

  def self.silence!
    @trace&.disable
  end
end

# ═══════════════════════════════════════════════════════════════
#
#  THE SESSION
#
# ═══════════════════════════════════════════════════════════════

garden_path = File.expand_path('garden', __dir__)

puts
puts C.bold(C.magenta("  ┌─────────────────────────────────────────────────────┐"))
puts C.bold(C.magenta("  │  🐟 Koi — an IRB session                           │"))
puts C.bold(C.magenta("  │                                                     │"))
puts C.bold(C.magenta("  │  You just edited seed.rb to add VARIETIES.          │"))
puts C.bold(C.magenta("  │  Let's see what happens when you throw the stone.   │"))
puts C.bold(C.magenta("  └─────────────────────────────────────────────────────┘"))
pause(1.5)

# ── Act 1: Enter the Pond ─────────────────────────────

section("Act 1: Enter the Pond")

type("require 'koi'")
puts irb_result("true")
pause(0.5)

narrator("First, let's see the pond.")

type("pond = Koi.pond('#{garden_path}')")
puts irb_result(Koi.pond(garden_path).to_s)
pause(0.8)

narrator("Five stones. Each a .rb file. The pond found them all.")
narrator("Enumerable gives us the full toolkit. Let's use it.")

type("pond.map(&:to_s)")
pond = Koi.pond(garden_path)
puts irb_result(pond.map(&:to_s).inspect)
pause(0.8)

narrator("They're sorted by modification time. Comparable does that.")
narrator("The freshest wound floats to the top. Let's find it.")

type("pond.last_touched")
stone = pond.last_touched
puts irb_result(stone.inspect)
pause(1.0)

narrator("seed.rb. The file we just changed.")
narrator("But last_touched is just Enumerable#max.")
narrator("Because Stone includes Comparable, and Pond includes Enumerable,")
narrator("this just works. No glue code. No ceremony.")

# ── Act 2: method_missing Magic ───────────────────────

section("Act 2: method_missing — The Living Pond")

narrator("Here's where Ruby gets philosophical.")
narrator("What if you could talk to the pond by name?")

type("pond.seed")
puts irb_result(pond.seed.inspect)
pause(0.5)

type("pond.flower")
puts irb_result(pond.flower.inspect)
pause(0.5)

type("pond.basket")
puts irb_result(pond.basket.inspect)
pause(0.5)

type("pond.gardener")
puts irb_result(pond.gardener.inspect)
pause(0.8)

narrator("There is no `seed` method on Pond.")
narrator("method_missing intercepts the call,")
narrator("searches the stones, and returns the match.")
narrator("The pond feels alive. You talk to it and it answers.")

type("pond.respond_to?(:seed)")
puts irb_result("true")
pause(0.3)

type("pond.respond_to?(:unicorn)")
puts irb_result("false")
pause(0.8)

narrator("respond_to_missing? keeps the contract honest.")
narrator("Introspection works. .method works. Everything works.")

# ── Act 3: Kin Discovery ──────────────────────────────

section("Act 3: Kin — Who Is Related to seed.rb?")

type("stone = pond.seed")
puts irb_result(pond.seed.inspect)
pause(0.3)

narrator("A stone's kin are found two ways:")
narrator("1. Files it requires (acquaintances — the address book)")
narrator("2. Files that mention it (mentioned_by — who speaks your name?)")

type("stone.acquaintances.map(&:to_s)")
puts irb_result(pond.seed.acquaintances.map(&:to_s).inspect)
pause(0.8)

narrator("seed.rb requires soil.rb. That's one acquaintance.")

type("stone.mentioned_by.map(&:to_s)")
puts irb_result(pond.seed.mentioned_by.map(&:to_s).inspect)
pause(0.8)

narrator("flower.rb and gardener.rb both mention 'seed'.")
narrator("They reference it — whether they know it or not.")

type("stone.kin.map(&:to_s)")
puts irb_result(pond.seed.kin.map(&:to_s).inspect)
pause(1.0)

narrator("Three kin. The union of both directions.")
narrator("These are the files that should feel the ripple.")

# ── Act 4: Deep Kin — Lazy Enumerators ────────────────

section("Act 4: Deep Kin — The Lazy Current")

narrator("Kin of kin of kin. How deep does the water go?")
narrator("deep_kin returns a lazy enumerator.")
narrator("Nothing executes until you pull.")

type("stone.deep_kin(depth: 3)")
enum = pond.seed.deep_kin(depth: 3)
puts irb_result("#<Enumerator::Lazy: ...>")
pause(0.8)

narrator("See? Just a lazy enumerator. No work done yet.")
narrator("Now let's pull values out, one at a time.")

type("stone.deep_kin(depth: 3).first(5).map(&:to_s)")
result = pond.seed.deep_kin(depth: 3).first(5).map(&:to_s)
puts irb_result(result.inspect)
pause(1.0)

narrator("It crawled the graph breadth-first.")
narrator("seed → soil, flower, gardener → basket (via flower).")
narrator("Lazy means it only did the work we asked for.")
narrator("If we'd said .first(1), it would have stopped after soil.")

# ── Act 5: Shapes (Prism/AST) ─────────────────────────

section("Act 5: Shapes — Seeing the Structure")

narrator("Now let's look at seed.rb through the AST's eyes.")
narrator("Not the text — the structure. The shape.")

type("shape = Koi::Parser.parse_shape(stone.essence, path: stone.path.to_s)")
shape = Koi::Parser.parse_shape(pond.seed.essence, path: pond.seed.path.to_s)
puts irb_result("#<Shape classes=#{shape.classes.size} methods=#{shape.methods.size} attrs=#{shape.attrs.size}>")
pause(0.5)

type("puts shape.describe")
shape.describe.each_line { |l| irb_puts l.chomp }
pause(1.0)

narrator("The AST extracted: 1 class, 5 methods (3 public, 2 private),")
narrator("3 attributes, 2 external constants (Flower, Soil).")
narrator("This is what the file LOOKS LIKE FROM THE OUTSIDE.")

type("shape.external_constants")
puts irb_result(shape.external_constants.inspect)
pause(0.5)

type("shape.public_interface[:readable]")
puts irb_result(shape.public_interface[:readable].inspect)
pause(0.8)

narrator("External constants are the types this file reaches for.")
narrator("These are the REAL dependencies — deeper than require.")

# ── Act 6: Diffing Shapes ─────────────────────────────

section("Act 6: The Diff — What Specifically Changed?")

narrator("Imagine this is seed.rb BEFORE your edit:")

before_source = <<~RUBY
  require_relative 'soil'

  class Seed
    attr_reader :name, :planted_at

    def initialize(name)
      @name = name
      @planted_at = Time.now
    end

    def sprout
      Flower.new(self)
    end

    def to_s
      "Seed(\#{name})"
    end
  end
RUBY

after_source = pond.seed.essence

type("before_shape = Koi::Parser.parse_shape(old_source)")
before_shape = Koi::Parser.parse_shape(before_source, path: "seed.rb")
puts irb_result("#<Shape methods=#{before_shape.methods.size} attrs=#{before_shape.attrs.size}>")
pause(0.3)

type("after_shape = Koi::Parser.parse_shape(stone.essence)")
after_shape = Koi::Parser.parse_shape(after_source, path: "seed.rb")
puts irb_result("#<Shape methods=#{after_shape.methods.size} attrs=#{after_shape.attrs.size}>")
pause(0.5)

type("diff = Koi::ShapeDiff.new(before: before_shape, after: after_shape)")
diff = Koi::ShapeDiff.new(before: before_shape, after: after_shape)
puts irb_result("#<ShapeDiff magnitude=#{diff.magnitude} severity=#{diff.severity.inspect}>")
pause(0.8)

type("puts diff.describe")
diff.describe.each_line { |l| irb_puts l.chomp }
pause(1.5)

narrator("The diff sees exactly what you did:")
narrator("Added :soil attribute. Added viable? and a private expired? method.")
narrator("Added a VARIETIES constant reference. Soil is now referenced.")
narrator("Magnitude: #{diff.magnitude}. Severity: #{diff.severity}.")
narrator("")
narrator("This is what Claude will receive. Not 'file changed.'")
narrator("But 'here's what changed, structurally, and how much.'")

# ── Act 7: TracePoint Narration ───────────────────────

section("Act 7: Narration — Watch the Fish")

narrator("TracePoint lets Ruby observe its own method calls.")
narrator("Koi uses it to narrate what's happening inside.")

type("Koi.narrate!")
Koi.narrate!
pause(0.3)

type("pond.last_touched.kin.map(&:to_s)")
result = pond.last_touched.kin.map(&:to_s)
puts irb_result(result.inspect)
pause(1.0)

Koi.silence!
narrator("Every method call was observed and narrated.")
narrator("The fish swim visibly. TracePoint is Ruby's X-ray vision.")

# ── Act 8: Throw the Stone ────────────────────────────

section("Act 8: Throw! — The Main Event")

narrator("Everything leads here.")
narrator("We throw seed.rb into the pond.")
narrator("Claude catches the ripples.")
narrator("(Simulated response — but everything else is real.)")

Koi.narrate!
pause(0.5)

type("reflection = pond.seed.throw!(style: :poignant)")
puts
reflection = pond.seed.throw!(style: :poignant)
puts
puts irb_result(reflection.to_s)
pause(1.5)

Koi.silence!

narrator("#{reflection.reach} files reimagined. Let's preview them.")

type("reflection.preview")
reflection.preview
pause(2.0)

narrator("The ripples touched flower.rb, gardener.rb, basket.rb, and soil.rb.")
narrator("Flower gained a :variety attribute and a rare? method.")
narrator("Gardener now validates varieties before planting.")
narrator("Basket can group by variety.")
narrator("Soil learned which varieties it can support.")
narrator("")
narrator("One stone. Four ripples. The garden harmonizes.")

# ── Act 9: Apply ──────────────────────────────────────

section("Act 9: Apply — The Future Takes Shape")

type("reflection.apply!")
puts
reflection.apply!
pause(1.0)

narrator("The files are rewritten. The pond settles.")

# ── Act 10: Refinements & Symbol#to_proc ──────────────

section("Act 10: The Small Miracles")

narrator("Let's activate StringSwims — the refinement.")
narrator("Now any string can become a stone.")

type("using Koi::StringSwims")
puts irb_result("main")
pause(0.5)

narrator("With refinements active, you could write:")
puts
puts "  #{C.cyan('"examples/garden/seed.rb".kin')}"
puts "  #{C.green('=> [🪨 soil.rb, 🪨 flower.rb, 🪨 gardener.rb]')}"
puts
puts "  #{C.cyan('"examples/garden/seed.rb".ripple!(style: :poignant)')}"
puts "  #{C.green('=> 🔮 Reflection: 4 files reimagined')}"
puts
pause(1.0)

narrator("A string became a stone. The stone found kin. The kin were rewritten.")
narrator("Three words. That's refinements.")

puts
narrator("And Symbol#to_proc — the tiny miracle hiding everywhere:")

type("pond.stones.map(&:to_s)")
puts irb_result(pond.stones.map(&:to_s).inspect)
pause(0.5)

narrator("&:to_s is shorthand for { |x| x.to_s }.")
narrator("Symbol#to_proc returns a proc that sends that message.")
narrator("You've been using it this whole session.")

# ── Act 11: ObjectSpace Easter Egg ────────────────────

section("Act 11: Easter Egg — The Memory Palace")

narrator("_why always hid things in his code.")
narrator("Here's what's hiding in Ruby's heap right now:")

type("ObjectSpace.each_object(Koi::Stone).count")
count = ObjectSpace.each_object(Koi::Stone).count
puts irb_result(count.to_s)
pause(0.8)

narrator("#{count} stones exist in memory. Every stone we ever created")
narrator("is still alive in Ruby's heap, until the garbage collector")
narrator("decides otherwise. Like memories: present until forgotten.")
narrator("Never on purpose.")

type("Koi::Stone.ancestors")
puts irb_result(Koi::Stone.ancestors.inspect)
pause(1.0)

narrator(".ancestors shows the full inheritance chain.")
narrator("Stone inherits from Struct, which gives it Enumerable's power.")
narrator("Comparable gives it sorting. Every method we used")
narrator("traces back through this chain.")
narrator("")
narrator("In Ruby, every object knows where it came from.")

# ── Act 12: Census with Tally ─────────────────────────

section("Act 12: Census — Tally the Pond")

type("pond.census")
puts irb_result(pond.census.inspect)
pause(0.5)

narrator(".tally (Ruby 2.7) counts occurrences.")
narrator("Five .rb files. That's the whole garden.")

type("pond.count")
puts irb_result(pond.count.to_s)
pause(0.3)

type("pond.any? { |s| s.essence.include?('Enumerable') }")
result = pond.any? { |s| s.essence.include?('Enumerable') }
puts irb_result(result.to_s)
pause(0.3)

type("pond.select { |s| s.essence.include?('Enumerable') }.map(&:to_s)")
result = pond.select { |s| s.essence.include?('Enumerable') }.map(&:to_s)
puts irb_result(result.inspect)
pause(0.8)

narrator("count, any?, select — all free from Enumerable.")
narrator("The Pond defined `each`. Ruby did the rest.")

# ── Finale ─────────────────────────────────────────────

section("Fin")

puts C.dim(C.italic("  \"When you don't create things,"))
puts C.dim(C.italic("   you become defined by your tastes"))
puts C.dim(C.italic("   rather than ability.\""))
puts C.dim(C.italic(""))
puts C.dim(C.italic("                    — _why the lucky stiff"))
puts
pause(1.0)
puts C.dim("  The pond settles. For now.")
puts
