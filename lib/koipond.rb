# frozen_string_literal: false  # because some strings want to change
#
# ╔═══════════════════════════════════════════════════════════╗
# ║  🐟 Koipond — throw a stone, watch the pond rewrite itself  ║
# ╚═══════════════════════════════════════════════════════════╝
#
# A file changes. Its neighbors feel it.
# Claude reimagines what the water touches.
#
# This is not a production tool.
# This is a love letter to Ruby,
# hand-delivered by a large language model.
#
# _why once wrote: "when you don't create things,
# you become defined by your tastes rather than ability."
#
# So we create.
#
# ── What Ruby Teaches ───────────────────────────────────
#
# 1. Everything is an object. Even nothing (nil).
# 2. Trust the programmer. Give them sharp tools.
# 3. There should be more than one way to do it,
#    and at least one of those ways should be beautiful.
# 4. Code is read more than it is written.
# 5. Joy is not a luxury in programming. It is the point.
#

require 'pathname'
require 'open3'
require 'json'
require_relative 'koipond/version'

# We conditionally require Prism — it ships natively with Ruby >= 3.3.
# If unavailable, we fall back to RubyVM::AbstractSyntaxTree.
PRISM_AVAILABLE = begin
  require 'prism'
  true
rescue LoadError
  false
end

module Koipond
  # ╔═══════════════════════════════════════════════════════╗
  # ║  Refinements                                         ║
  # ║                                                      ║
  # ║  Ruby lets you reshape the world —                   ║
  # ║  but only within your own scope.                     ║
  # ║  Refinements are polite metamorphosis.               ║
  # ║                                                      ║
  # ║  Other languages call this "extension methods"       ║
  # ║  and make you write decorators and wrappers.         ║
  # ║  Ruby says: just refine the class.                   ║
  # ║  It'll only matter where you say `using`.            ║
  # ╚═══════════════════════════════════════════════════════╝

  module StringSwims
    refine String do
      # Any string can become a stone. In Ruby,
      # objects are not locked into their birth type.
      # They can always become something more.
      def to_stone
        Stone.new(path: Pathname.new(self))
      end

      # One word. One method. That's all it takes.
      def ripple!(style: :gentle)
        to_stone.throw!(style: style)
      end

      # Who is related to this file?
      # Ask the string. It knows.
      def kin
        to_stone.kin
      end
    end

    refine Pathname do
      def alive?
        exist? && extname == '.rb'
      end

      # A file's heartbeat is its modification time.
      # Dead files have no pulse.
      def heartbeat
        alive? ? mtime : Time.at(0)
      end
    end
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Stone                                               ║
  # ║                                                      ║
  # ║  The file that just changed.                         ║
  # ║  The inciting incident of every story.               ║
  # ║                                                      ║
  # ║  Built with Struct — Ruby's gift for when            ║
  # ║  a full class is too much ceremony                   ║
  # ║  and a hash is too little meaning.                   ║
  # ║                                                      ║
  # ║  Struct gives you:                                   ║
  # ║    • initialize    • ==       • to_a                 ║
  # ║    • members       • []       • each_pair            ║
  # ║  All free. All correct. All because Ruby             ║
  # ║  believes you shouldn't have to write                ║
  # ║  the same boilerplate twice.                         ║
  # ╚═══════════════════════════════════════════════════════╝

  Stone = Struct.new(:path, :pond, keyword_init: true) do
    using StringSwims   # refinements only live where you invite them

    include Comparable  # include one module, gain a universe:

    #   <, <=, ==, >=, >, between?, clamp
    # All from defining a single method: <=>

    def initialize(path:, pond: nil)
      super(path: Pathname.new(path).expand_path, pond: pond)
    end

    # ── Comparable ─────────────────────────────────────
    # Define <=> and Ruby gives you the rest.
    # Stones sort by how recently they were touched.
    # The freshest wound floats to the top.
    def <=>(other)
      return nil unless other.is_a?(Stone)

      path.heartbeat <=> other.path.heartbeat
    end

    # ── Essence ────────────────────────────────────────
    # What does this file say? Read it. Just read it.
    # In Ruby, reading a file is one method call.
    # No streams, no buffers, no ceremony.
    def essence
      @essence ||= path.read
    rescue Errno::ENOENT
      ''
    end

    # ── Acquaintances ──────────────────────────────────
    # Parse the requires. They're a stone's address book.
    #
    # .scan returns all matches as an array.
    # .flatten collapses nested captures.
    # .filter_map maps and discards nils in one pass.
    #
    # This is Ruby's pipeline style:
    # each method returns something the next can use.
    # No temp variables. No mutation. Just flow.
    def acquaintances
      return [] unless pond

      essence
        .scan(/require(?:_relative)?\s+['"]([^'"]+)['"]/)
        .flatten
        .filter_map { |r| pond.resolve(r, relative_to: path) }
    end

    # ── Mentioned By ───────────────────────────────────
    # Who speaks your name?
    # The files that reference you are your kin
    # whether they know it or not.
    def mentioned_by
      return [] unless pond

      name_stem = path.basename('.rb').to_s
      pond.stones.select { |s|
        s.path != path && s.essence.include?(name_stem)
      }
    end

    # ── Kin ────────────────────────────────────────────
    # All relatives. Union of both directions.
    # Set ensures no duplicates — because in Ruby,
    # Set#| is the union operator, and that's beautiful.
    def kin
      seen = Set.new
      (acquaintances + mentioned_by).each_with_object([]) { |k, acc|
        key = k.path.to_s
        unless seen.include?(key)
          seen.add(key)
          acc << k
        end
      }
    end

    # ── Deep Kin ───────────────────────────────────────
    # Kin of kin of kin. A lazy breadth-first crawl.
    #
    # Enumerator.new takes a block with a "yielder."
    # Each time you call yielder << value, the enumerator
    # pauses and gives that value to whoever asked.
    # It only resumes when they ask for more.
    #
    # .lazy makes it truly lazy — nothing executes
    # until someone calls .first, .take, or .each.
    #
    # This is Ruby's take on generators.
    # No async. No promises. Just a block that pauses.
    def deep_kin(depth: 3)
      Enumerator.new do |yielder|
        seen = Set.new([path.to_s])
        frontier = kin.dup

        depth.times do
          next_frontier = []
          frontier.each do |k|
            next if seen.include?(k.path.to_s)

            seen.add(k.path.to_s)
            yielder << k
            next_frontier.concat(k.kin)
          end
          frontier = next_frontier
          break if frontier.empty?
        end
      end.lazy # the .lazy is the magic word
    end

    # ── Throw ──────────────────────────────────────────
    # The main event. Throw the stone into the pond.
    # Claude catches the ripples on the other side.
    #
    # Note the &block — Ruby's most important feature.
    # Blocks let the caller customize behavior
    # without subclassing, without config objects,
    # without any of the ceremony other languages demand.
    #
    # Just pass a block. It's that simple.
    def throw!(style: :gentle, &block)
      effective_pond = pond || Pond.here
      wave = Wave.new(stone: self, style: style, pond: effective_pond)
      block&.call(wave)   # &. is the safe navigation operator
      wave.propagate!     # call the block if it exists, skip if nil
    end

    # ── to_s and inspect ───────────────────────────────
    # Every object controls how it appears as text.
    # Ruby calls to_s for string interpolation
    # and inspect for debugging.
    #
    # The endless method syntax (def name = expr)
    # arrived in Ruby 3.0. One line. No `end`.
    # For small methods, it's a gift.
    def to_s = "🪨 #{path.basename}"
    def inspect = "#<Stone #{path.basename} touched=#{path.mtime.strftime('%H:%M:%S')}>"
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Pond                                                ║
  # ║                                                      ║
  # ║  Your project. Your little ecosystem.                ║
  # ║  Every .rb file is a fish. Some swim together.       ║
  # ║                                                      ║
  # ║  The Pond includes Enumerable — Ruby's most          ║
  # ║  generous module. Define `each`, and you receive:    ║
  # ║    map, select, reject, reduce, sort, min, max,     ║
  # ║    flat_map, zip, chunk, tally, group_by, any?,     ║
  # ║    all?, none?, count, first, take, drop,           ║
  # ║    each_with_object, each_slice, each_cons...        ║
  # ║  ~60 methods. All from defining one.                 ║
  # ║                                                      ║
  # ║  This is Ruby's philosophy of generosity.            ║
  # ╚═══════════════════════════════════════════════════════╝

  class Pond
    include Enumerable

    attr_reader :root

    def initialize(root = Dir.pwd)
      @root = Pathname.new(root).expand_path
    end

    # ── Class method with endless syntax ───────────────
    def self.here = new(Dir.pwd)

    # ── Enumerable's one requirement ───────────────────
    def each(&)
      stones.each(&)
    end

    # Because Enumerable gives us `max`, and Stone
    # includes Comparable, this just works.
    # No ceremony. No glue code. Just Ruby.
    def last_touched
      max
    end

    # ── method_missing ─────────────────────────────────
    # This is where Ruby gets philosophical.
    #
    # When you call a method that doesn't exist,
    # Ruby doesn't just crash. It asks the object:
    # "Do you want to handle this?"
    #
    # We say yes — if the method name matches a file.
    # This makes the Pond feel alive:
    #
    #   pond.user_model          # finds user_model.rb
    #   pond.user_model.kin      # its relatives
    #   pond.user_model.throw!   # reimagine its neighbors
    #
    # Three words that read like English.
    # That's not an accident. That's Ruby.
    def method_missing(name, *args, &)
      found = stones.find { |s|
        s.path.basename('.rb').to_s == name.to_s
      }
      return found if found

      super # if we can't handle it, let Ruby's normal error kick in
    end

    # Always pair method_missing with respond_to_missing?
    # This is the contract. Break it, and introspection breaks.
    # .respond_to?, .method, Object#methods — they all ask here.
    def respond_to_missing?(name, include_private = false)
      stones.any? { |s| s.path.basename('.rb').to_s == name.to_s } || super
    end

    # ── Resolve requires ───────────────────────────────
    # Turn a require string ("./helper") into a real Stone.
    # Try every possible location. Return the first that exists.
    #
    # .find is Enumerable's "first match" — it stops
    # as soon as it finds one. No wasted work.
    def resolve(req, relative_to: root)
      candidates = [
        relative_to.dirname.join("#{req}.rb"),
        relative_to.dirname.join(req.to_s),
        root.join('lib', "#{req}.rb"),
        root.join("#{req}.rb"),
      ]
      found = candidates.find(&:exist?)
      found && Stone.new(path: found, pond: self)
    end

    # ── Throw the last stone ───────────────────────────
    # Delegate to the most recently touched file.
    # Delegation in Ruby is just a method call.
    # No patterns. No proxies. Just trust.
    def throw!(style: :gentle, &)
      stone = last_touched
      return puts('🌊 The pond is empty. No stones to throw.') unless stone

      stone.throw!(style: style, &)
    end

    # ── Summary ────────────────────────────────────────
    # The tally method (Ruby 2.7+) counts occurrences.
    # Here we tally file extensions — just because we can.
    def census
      stones
        .map { |s| s.path.extname }
        .tally
        .sort_by { |_, count| -count }
        .to_h
    end

    def stones
      @stones ||= Pathname.glob(root.join('**/*.rb'))
                          .reject { |p| p.to_s =~ /vendor|node_modules|\.bundle|\.git/ }
                          .map { |p| Stone.new(path: p, pond: self) }
                          .sort # Comparable does the rest
    end

    def to_s = "🌊 Pond(#{root.basename}, #{stones.size} stones)"
    def inspect = "#<Pond root=#{root} stones=#{stones.size}>"
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Wave                                                ║
  # ║                                                      ║
  # ║  The ripple that carries meaning to Claude.          ║
  # ║                                                      ║
  # ║  Styles are stored as lambdas in a frozen hash.      ║
  # ║  In Ruby, lambdas are first-class objects.           ║
  # ║  You can store them, pass them, call them later.     ║
  # ║  They close over their environment.                  ║
  # ║  They ARE the environment, preserved in amber.       ║
  # ║                                                      ║
  # ║  This is the essence of functional programming       ║
  # ║  hidden inside an object-oriented language.          ║
  # ║  Ruby doesn't make you choose.                       ║
  # ╚═══════════════════════════════════════════════════════╝

  class Wave
    # ── Lambdas as strategy objects ────────────────────
    # Each style is a lambda that builds a prompt.
    # Lambdas enforce arity (argument count).
    # Procs don't. That's the only real difference.
    # Choose lambdas when you want discipline.
    # Choose procs when you want freedom.
    STYLES = {
      gentle: lambda { |stone, kin_text|
        <<~PROMPT
          I just changed #{stone.path.basename}. Here is its current content:

          ```ruby
          #{stone.essence}
          ```

          #{kin_text}

          Gently improve the related files to harmonize with my changes.
          Keep the spirit. Refine the letter.
          Preserve method signatures and public interfaces.
          Return each file as:
          === FILEPATH ===
          (file content)
        PROMPT
      },

      radical: lambda { |stone, kin_text|
        <<~PROMPT
          #{stone.path.basename} has changed. It now reads:

          ```ruby
          #{stone.essence}
          ```

          #{kin_text}

          Radically reimagine the related files.
          Make them sing in the same key as the changed file,
          but find harmonies nobody expected.
          Rethink the architecture if it serves clarity.
          Return each file as:
          === FILEPATH ===
          (file content)
        PROMPT
      },

      # The poignant style. For when you want Claude
      # to channel something deeper.
      poignant: lambda { |stone, kin_text|
        <<~PROMPT
          A file has changed. As _why once said,
          "when you don't create things, you become defined
          by your tastes rather than ability."

          The changed file (#{stone.path.basename}):
          ```ruby
          #{stone.essence}
          ```

          #{kin_text}

          Rewrite the related files with the curiosity of a fox
          and the precision of a cartoonist. Make the code more Ruby.
          More alive. More itself. Favor elegance over cleverness.
          Favor clarity over brevity. Favor joy over everything.
          Return each file as:
          === FILEPATH ===
          (file content)
        PROMPT
      },
    }.freeze # .freeze makes the hash immutable.
    # The past is frozen. Only the future is mutable.

    attr_accessor :stone, :style, :pond

    def initialize(stone:, style: :gentle, pond: Pond.here)
      @stone = stone
      @style = style
      @pond  = pond
    end

    def propagate!
      kin = stone.kin
      return Reflection.empty("#{stone} has no kin. It ripples alone.") if kin.empty?

      # If Prism is available, use structured prompts
      if defined?(Koipond::Parser) && defined?(Koipond::PrismPrompts)
        diff = compute_shape_diff
        prompt = PrismPrompts.build(stone: stone, kin: kin, diff: diff, style: style)
      else
        # Original STYLES lambda approach
        kin_text = kin.map { |k|
          "Related file (#{k.path.basename}):\n```ruby\n#{k.essence}\n```"
        }.join("\n\n")

        prompt = STYLES
                 .fetch(style) { STYLES[:gentle] } # fetch with default block
                 .call(stone, kin_text) # call the lambda
      end

      response = ask_claude(prompt)

      Reflection.new(
        stone: stone,
        kin: kin,
        response: response,
        rewrites: parse_rewrites(response)
      )
    end

    private

    # ── Compute shape diff for Prism-powered prompts ───
    def compute_shape_diff
      return nil unless defined?(Koipond::Parser)

      # For now, return nil (no "before" shape available)
      # A full implementation would cache shapes and diff against prior version
      nil
    end

    # ── Ask Claude ─────────────────────────────────────
    # Open3.capture3 runs a command and captures
    # stdout, stderr, and the exit status.
    # Three values, returned as three variables.
    # Multiple return values without tuples or wrappers.
    # Ruby just lets you.
    CLAUDE_SYSTEM_PROMPT = <<~SYSTEM
      You rewrite Ruby files. Output ONLY in this format:

      === path/to/file.rb ===
      (complete file content)

      === another/file.rb ===
      (complete file content)

      RULES:
      1. Output ONLY === FILEPATH === blocks
      2. No prose, no explanations, no markdown, no analysis
      3. If no changes needed, output exactly: === NO CHANGES ===
      4. Never explain your reasoning
    SYSTEM

    def ask_claude(prompt)
      stdout, stderr, status = Open3.capture3(
        'claude', '-p', prompt,
        '--system-prompt', CLAUDE_SYSTEM_PROMPT,
        '--output-format', 'text'
      )

      raise ClaudeUnreachable, "Claude couldn't hear us: #{stderr}" unless status.success?

      stdout
    end

    # ── Parse ──────────────────────────────────────────
    # .split with a regex that has captures returns
    # the separators too. This is subtle and powerful.
    # .each_slice(2) groups pairs: [filepath, content].
    # .to_h turns pairs into a hash.
    #
    # Claude sometimes adds markdown fences or explanations.
    # We strip those to get clean Ruby.
    def parse_rewrites(text)
      # Handle explicit "no changes" marker
      return {} if text.include?('=== NO CHANGES ===')

      parts = text.split(/^===\s*(.+?)\s*===$/)
      return {} if parts.size < 3

      parts
        .drop(1)
        .each_slice(2)
        .filter_map { |filepath, content|
          next unless filepath && content
          next if filepath.strip.upcase == 'NO CHANGES'

          clean = content
                  .sub(/\A\s*```\w*\n/, '') # opening markdown fence
                  .sub(/\n```\s*\z/, '')        # closing markdown fence
                  .sub(/\n---\n.*/m, '')        # trailing explanation after ---
                  .strip
          [filepath.strip, clean]
        }
        .to_h
    end
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Reflection                                          ║
  # ║                                                      ║
  # ║  What came back from the water.                      ║
  # ║  The pond's answer to the stone.                     ║
  # ║                                                      ║
  # ║  Again a Struct — lightweight, transparent,          ║
  # ║  with just enough behavior bolted on.                ║
  # ║                                                      ║
  # ║  Notice .tap — it executes a block and returns       ║
  # ║  the original object. It's for side effects          ║
  # ║  in the middle of a chain:                           ║
  # ║    result.tap { |r| log(r) }.transform.save          ║
  # ║                                                      ║
  # ║  And .then (alias: yield_self) — it passes           ║
  # ║  the object into a block and returns the result:     ║
  # ║    path.then { |p| File.read(p) }.then { |s| parse(s) } ║
  # ╚═══════════════════════════════════════════════════════╝

  Reflection = Struct.new(:stone, :kin, :response, :rewrites, keyword_init: true) do
    def self.empty(reason)
      new(stone: nil, kin: [], response: reason, rewrites: {})
    end

    def empty? = rewrites.empty?

    # Preview what Claude would change.
    # Don't touch the files. Just look.
    # .tap returns self, so you can chain:
    #   reflection.preview.apply!
    def preview
      rewrites.each do |filepath, content|
        puts "\n#{'═' * 60}"
        puts "  📝 #{filepath}"
        puts '═' * 60

        # Show first 25 lines, hint at the rest.
        lines = content.lines
        puts lines.first(25).join
        puts "  ... (#{lines.size} total lines)" if lines.size > 25
      end
      self # return self for chaining
    end

    # Apply the rewrites. Let the ripples land.
    #
    # .freeze makes `before` immutable.
    # The past cannot be edited. This is not a technical
    # constraint — it's a philosophical one.
    # Ruby lets you express philosophy in code.
    def apply!
      rewrites.each do |filepath, content|
        target = Pathname.new(filepath)
        target.dirname.mkpath

        before = target.exist? ? target.read.freeze : nil
        target.write(content)

        if before
          puts "  ♻️  Rewrote #{filepath} (was #{before.lines.size} lines, now #{content.lines.size})"
        else
          puts "  ✨ Created #{filepath}"
        end
      end
      self
    end

    def reach = rewrites.size

    def to_s
      if empty?
        if response.to_s.strip.empty? || response.include?('NO CHANGES')
          '🔮 the pond is still. no changes needed.'
        else
          "🔮 #{response}"
        end
      else
        "🔮 Reflection: #{reach} files reimagined from #{stone}"
      end
    end
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Narrate                                             ║
  # ║                                                      ║
  # ║  TracePoint is Ruby's introspection superpower.      ║
  # ║  It lets you observe method calls, class             ║
  # ║  definitions, exceptions, and more — live,           ║
  # ║  as they happen, without modifying any code.         ║
  # ║                                                      ║
  # ║  Most languages need AOP frameworks for this.        ║
  # ║  Ruby has it built in. Because Ruby trusts you       ║
  # ║  with the sharp tools.                               ║
  # ║                                                      ║
  # ║  Here we use it to narrate what Koipond is doing,    ║
  # ║  like a nature documentary for your code.            ║
  # ╚═══════════════════════════════════════════════════════╝

  module Narrate
    TALES = {
      'last_touched' => 'the pond remembers who moved last',
      'kin' => 'searching for family in the water',
      'deep_kin' => 'following the current deeper...',
      'throw!' => 'a stone arcs through the air',
      'propagate!' => 'ripples spreading outward',
      'ask_claude' => 'whispering to Claude across the wire',
      'apply!' => 'the future takes shape',
      'preview' => 'peering into what might be',
      'acquaintances' => 'reading the address book',
      'mentioned_by' => 'who speaks this name?',
      'essence' => 'reading the stone\'s inscription',
    }.freeze

    def self.on!
      @trace = TracePoint.new(:call) do |tp|
        next unless tp.defined_class.to_s.include?('Koipond')

        tale = TALES[tp.method_id.to_s]
        # Named methods get narrated. Others appear randomly.
        # Randomness is _why's favorite spice.
        if tale
          puts "  🐟 #{tale}"
        elsif rand < 0.15
          puts "  🐟 #{tp.method_id} stirs beneath the surface"
        end
      end
      @trace.enable
      puts '  🐟 Narration enabled. Watch the fish.'
    end

    def self.off!
      @trace&.disable
      puts '  🐟 The pond falls silent.'
    end
  end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  The Module-Level DSL                                ║
  # ║                                                      ║
  # ║  class << self opens the eigenclass —                ║
  # ║  Ruby's secret room where singleton methods live.    ║
  # ║  Every object has one. Most people never visit.      ║
  # ║                                                      ║
  # ║  Defining methods here means you call:               ║
  # ║    Koipond.pond      not   Koipond.new.pond          ║
  # ║    Koipond.ripple!   not   koipond_instance.ripple!  ║
  # ║                                                      ║
  # ║  It's Ruby's way of saying:                          ║
  # ║  modules can be both namespaces AND objects.         ║
  # ╚═══════════════════════════════════════════════════════╝

  class << self
    def pond(root = Dir.pwd)
      Pond.new(root)
    end

    # The whole gem in one method call.
    def ripple!(root: Dir.pwd, style: :gentle, &)
      pond(root).throw!(style: style, &)
    end

    def narrate!  = Narrate.on!
    def silence!  = Narrate.off!
  end

  # ── Custom Error ─────────────────────────────────────
  # Because even errors deserve a good name.
  class ClaudeUnreachable < StandardError; end

  # ╔═══════════════════════════════════════════════════════╗
  # ║  Easter Egg                                          ║
  # ║                                                      ║
  # ║  _why always hid things in his code.                 ║
  # ║                                                      ║
  # ║  In IRB, after playing with Koipond for a while:     ║
  # ║                                                      ║
  # ║    ObjectSpace.each_object(Koipond::Stone).count     ║
  # ║    => 42  (or however many you've touched)           ║
  # ║                                                      ║
  # ║  Every Stone that ever existed still lives in        ║
  # ║  Ruby's heap, until the garbage collector            ║
  # ║  decides otherwise. Like memories:                   ║
  # ║  present until forgotten, never on purpose.          ║
  # ║                                                      ║
  # ║  Also try:                                           ║
  # ║    Koipond::Stone.ancestors                          ║
  # ║    => [Koipond::Stone, Comparable, Struct, ...]      ║
  # ║                                                      ║
  # ║  .ancestors shows the full inheritance chain.        ║
  # ║  In Ruby, every object knows where it came from.     ║
  # ║  Do you?                                             ║
  # ╚═══════════════════════════════════════════════════════╝

  # ════════════════════════════════════════════════════════════════
  #
  #   PRISM INTEGRATION
  #
  #   When Prism is available, Koipond gains structural understanding.
  #   It sees code not as text but as shapes, relationships, and diffs.
  #
  # ════════════════════════════════════════════════════════════════

  # Data.define creates frozen (immutable) value objects.
  # Once created, they cannot be changed.
  # Like a photograph of your code at a moment in time.
  #
  # Data was added in Ruby 3.2 as the immutable counterpart to Struct.
  # It gives you: initialize, ==, hash, inspect, to_h, members, deconstruct_keys.
  # All free. All frozen. All correct.
  #
  # The philosophical difference:
  #   Struct = a living thing that can change
  #   Data   = a memory of a thing, preserved exactly

  Requirement = Data.define(:type, :path, :location) {
    def to_s = "#{type} '#{path}'"
  }

  Inclusion = Data.define(:type, :name, :location) {
    def to_s = "#{type} #{name}"
  }

  Attribute = Data.define(:kind, :name, :location) {
    def to_s = "#{kind} :#{name}"
  }

  Params = Data.define(:required, :optional, :rest, :keywords, :keyword_rest, :block) {
    def self.empty
      new(required: [], optional: [], rest: nil, keywords: [], keyword_rest: nil, block: nil)
    end

    def signature
      parts = []
      parts.concat(required.map(&:to_s))
      parts.concat(optional.map { |o| "#{o} = ..." })
      parts << "*#{rest}" if rest
      parts.concat(keywords.map { |k| "#{k}:" })
      parts << "**#{keyword_rest}" if keyword_rest
      parts << "&#{block}" if block
      "(#{parts.join(', ')})"
    end

    def arity
      required.size
    end

    def to_s = signature
  }

  Method = Data.define(:name, :visibility, :params, :location, :class_name, :class_method) {
    def public?    = visibility == :public
    def private?   = visibility == :private
    def protected? = visibility == :protected

    def signature
      prefix = class_method ? 'self.' : ''
      "#{visibility} #{prefix}#{name}#{params}"
    end

    def to_s = signature
  }

  Comment = Data.define(:text, :line, :yard) {
    def yard? = yard
    def to_s = text
  }

  MethodChange = Data.define(:name, :before, :after) {
    def signature_changed?
      before.params.signature != after.params.signature
    end

    def visibility_changed?
      before.visibility != after.visibility
    end

    def to_s
      parts = []
      parts << "signature: #{before.params} -> #{after.params}" if signature_changed?
      parts << "visibility: #{before.visibility} -> #{after.visibility}" if visibility_changed?
      "#{name}: #{parts.join(', ')}"
    end
  }

  # ── The Shape itself ─────────────────────────────────
  # A Struct, not a Data, because shapes are assembled
  # incrementally by the Visitor. They're alive while
  # being built, frozen when done.
  #
  Shape = Struct.new(
    :requires, :includes, :attrs, :methods,
    :classes, :modules, :superclasses,
    :constant_refs, :comments,
    keyword_init: true
  ) do
    def initialize(**)
      super(
        requires: [],
        includes: [],
        attrs: [],
        methods: [],
        classes: [],
        modules: [],
        superclasses: {},
        constant_refs: [],
        comments: [],
        **
      )
    end

    # ── Who do I depend on? ────────────────────────────
    # External constants are the ones we reference
    # but don't define ourselves.
    def external_constants
      defined = Set.new(classes + modules)
      included = Set.new(includes.map(&:name))
      Set.new(constant_refs.map(&:to_s)) - defined - included
    end

    # ── My public interface ────────────────────────────
    # What the outside world can call.
    # This is what kin files care about.
    def public_interface
      public_methods = methods.select(&:public?)
      readable_attrs = attrs.select { |a| %i[attr_reader attr_accessor].include?(a.kind) }
      writable_attrs = attrs.select { |a| %i[attr_writer attr_accessor].include?(a.kind) }
      {
        methods: public_methods,
        readable: readable_attrs.map(&:name),
        writable: writable_attrs.map(&:name),
        includes: includes.map(&:name),
      }
    end

    # ── Summary for Claude ─────────────────────────────
    # A compact description of this file's structure.
    def describe
      lines = []
      lines << "Classes: #{classes.join(', ')}" unless classes.empty?
      lines << "Modules: #{modules.join(', ')}" unless modules.empty?
      superclasses.each do |c, s|
        lines << "  #{c} < #{s}"
      end
      lines << "Includes: #{includes.map(&:to_s).join(', ')}" unless includes.empty?
      lines << "Attributes: #{attrs.map(&:to_s).join(', ')}" unless attrs.empty?
      lines << 'Methods:' unless methods.empty?
      methods.each do |m|
        lines << "  #{m.signature}"
      end
      lines << "References: #{external_constants.to_a.join(', ')}" unless external_constants.empty?
      lines.join("\n")
    end

    # Freeze the shape once we're done building it.
    # The past is immutable. Only the future is open.
    def solidify!
      constant_refs.uniq!
      requires.freeze
      includes.freeze
      attrs.freeze
      methods.freeze
      classes.freeze
      modules.freeze
      constant_refs.freeze
      freeze
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   ShapeDiff — The Delta Between What Was and What Is
  #
  #   Instead of telling Claude "this file changed" (vague),
  #   we tell Claude exactly what happened (precise):
  #
  #     "Pond gained :depth and :temperature attributes,
  #      now includes Comparable, added a <=> method,
  #      swim's signature changed from () to (direction = :north),
  #      and there's a new drain! method."
  #
  # ════════════════════════════════════════════════════════════════

  class ShapeDiff
    attr_reader :before, :after

    def initialize(before:, after:)
      @before = before
      @after  = after
    end

    # ── Methods ──────────────────────────────────────
    def methods_added
      after_names = Set.new(after.methods.map(&:name))
      before_names = Set.new(before.methods.map(&:name))
      (after_names - before_names).map { |n| after.methods.find { |m| m.name == n } }
    end

    def methods_removed
      before_names = Set.new(before.methods.map(&:name))
      after_names  = Set.new(after.methods.map(&:name))
      (before_names - after_names).map { |n| before.methods.find { |m| m.name == n } }
    end

    def methods_changed
      shared = Set.new(before.methods.map(&:name)) & Set.new(after.methods.map(&:name))
      shared.filter_map { |name|
        bm = before.methods.find { |m| m.name == name }
        am = after.methods.find  { |m| m.name == name }
        next if bm.params.signature == am.params.signature && bm.visibility == am.visibility

        MethodChange.new(name: name, before: bm, after: am)
      }
    end

    # ── Attributes ─────────────────────────────────────
    def attrs_added
      before_names = Set.new(before.attrs.map(&:name))
      after.attrs.reject { |a| before_names.include?(a.name) }
    end

    def attrs_removed
      after_names = Set.new(after.attrs.map(&:name))
      before.attrs.reject { |a| after_names.include?(a.name) }
    end

    # ── Constants ──────────────────────────────────────
    def constants_added
      after.external_constants - before.external_constants
    end

    def constants_removed
      before.external_constants - after.external_constants
    end

    # ── Includes ───────────────────────────────────────
    def includes_added
      before_names = Set.new(before.includes.map(&:name))
      after.includes.reject { |i| before_names.include?(i.name) }
    end

    def includes_removed
      after_names = Set.new(after.includes.map(&:name))
      before.includes.reject { |i| after_names.include?(i.name) }
    end

    # ── Significance ───────────────────────────────────
    # How much did the shape change?
    # This helps Koipond decide how aggressively to ripple.
    def magnitude
      counts = [
        methods_added.size * 3,     # new methods are significant
        methods_removed.size * 3,
        methods_changed.size * 2,   # changed signatures ripple outward
        attrs_added.size * 2,
        attrs_removed.size * 2,
        constants_added.size,       # new dependencies are interesting
        constants_removed.size,
        includes_added.size * 2,    # new capabilities
      ]
      counts.sum
    end

    def trivial?    = magnitude.zero?
    def minor?      = magnitude.between?(1, 3)
    def significant? = magnitude.between?(4, 8)
    def major? = magnitude > 8

    # ── Describe for Claude ────────────────────────────
    # A structured, semantic description of what changed.
    # This replaces "here's the whole file, figure it out."
    #
    def describe
      return '(no structural changes)' if trivial?

      lines = methods_added.map { |m|
        "+ Added: #{m.signature}"
      }
      methods_removed.each do |m|
        lines << "- Removed: #{m.signature}"
      end
      methods_changed.each do |mc|
        lines << "~ Changed: #{mc.name}"
        lines << "    was: #{mc.before.signature}"
        lines << "    now: #{mc.after.signature}"
      end
      attrs_added.each do |a|
        lines << "+ Added: #{a}"
      end
      attrs_removed.each do |a|
        lines << "- Removed: #{a}"
      end
      includes_added.each do |i|
        lines << "+ Now includes: #{i.name}"
      end
      includes_removed.each do |i|
        lines << "- No longer includes: #{i.name}"
      end
      constants_added.each do |c|
        lines << "+ Now references: #{c}"
      end
      constants_removed.each do |c|
        lines << "- No longer references: #{c}"
      end
      lines << "\nMagnitude: #{magnitude} (#{severity})"
      lines.join("\n")
    end

    def severity
      if trivial?
        'no change'
      elsif minor?
        'cosmetic'
      elsif significant?
        'structural'
      elsif major?
        'architectural'
      end
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   ShapeVisitor — Prism-powered AST traversal
  #
  #   Only defined when Prism is available.
  #
  # ════════════════════════════════════════════════════════════════

  if PRISM_AVAILABLE

    class ShapeVisitor < Prism::Visitor
      attr_reader :shape

      def initialize
        @shape = Shape.new
        @visibility_stack = [:public] # stack because classes nest
        @current_class = nil
        super
      end

      # ── Requires ──────────────────────────────────────
      def visit_call_node(node)
        case node.name
        when :require, :require_relative
          if node.arguments&.arguments&.first.is_a?(Prism::StringNode)
            @shape.requires << Requirement.new(
              type: node.name,
              path: node.arguments.arguments.first.unescaped,
              location: node.location
            )
          end

        when :include, :extend, :prepend
          if node.arguments&.arguments&.first
            arg = node.arguments.arguments.first
            name = extract_constant_path(arg)
            if name
              @shape.includes << Inclusion.new(
                type: node.name,
                name: name,
                location: node.location
              )
            end
          end

        when :attr_reader, :attr_accessor, :attr_writer
          node.arguments&.arguments&.each do |arg|
            next unless arg.is_a?(Prism::SymbolNode)

            @shape.attrs << Attribute.new(
              kind: node.name,
              name: arg.unescaped.to_sym,
              location: node.location
            )
          end

        when :private, :protected, :public
          @visibility_stack[-1] = node.name if node.arguments.nil?
        end

        super
      end

      # ── Method definitions ────────────────────────────
      def visit_def_node(node)
        @shape.methods << Method.new(
          name: node.name,
          visibility: @visibility_stack.last,
          params: extract_params(node),
          location: node.location,
          class_name: @current_class,
          class_method: false
        )
        super
      end

      # ── Class and Module definitions ──────────────────
      def visit_class_node(node)
        name = extract_constant_path(node.constant_path)
        @shape.classes << name if name

        parent = @current_class
        @current_class = name
        @visibility_stack.push(:public)

        if node.superclass
          sc = extract_constant_path(node.superclass)
          @shape.superclasses[name] = sc if sc
        end

        super

        @visibility_stack.pop
        @current_class = parent
      end

      def visit_module_node(node)
        name = extract_constant_path(node.constant_path)
        @shape.modules << name if name

        parent = @current_class
        @current_class = name
        @visibility_stack.push(:public)
        super
        @visibility_stack.pop
        @current_class = parent
      end

      # ── Constant reads ────────────────────────────────
      def visit_constant_read_node(node)
        @shape.constant_refs << node.name
        super
      end

      def visit_constant_path_node(node)
        full_path = extract_constant_path(node)
        @shape.constant_refs << full_path if full_path
        super
      end

      private

      def extract_constant_path(node)
        case node
        when Prism::ConstantReadNode
          node.name.to_s
        when Prism::ConstantPathNode
          parent = node.parent ? extract_constant_path(node.parent) : nil
          child  = node.name.to_s
          parent ? "#{parent}::#{child}" : child
        end
      end

      def extract_params(node)
        return Params.empty unless node.parameters

        p = node.parameters
        Params.new(
          required: p.requireds.map { |r| r.respond_to?(:name) ? r.name : r.to_s },
          optional: p.optionals.map(&:name),
          rest: p.rest&.name,
          keywords: p.keywords.map(&:name),
          keyword_rest: p.keyword_rest.respond_to?(:name) ? p.keyword_rest.name : nil,
          block: p.block&.name
        )
      end
    end

  end

  # ════════════════════════════════════════════════════════════════
  #
  #   Parser — Unified interface for shape extraction
  #
  #   Falls back to old AST if Prism isn't available.
  #
  # ════════════════════════════════════════════════════════════════

  module Parser
    module_function

    def parse_shape(source, path: '(unknown)')
      if PRISM_AVAILABLE
        parse_with_prism(source, path: path)
      else
        parse_with_old_ast(source, path: path)
      end
    end

    def parse_with_prism(source, path: '(unknown)')
      result = Prism.parse(source)

      unless result.success?
        result.errors.each do |err|
          warn "  [prism] #{path}:#{err.location.start_line}: #{err.message}"
        end
      end

      visitor = ShapeVisitor.new
      result.value.accept(visitor)

      result.comments.each do |comment|
        text = comment.location.slice.sub(/^#\s?/, '')
        visitor.shape.comments << Comment.new(
          text: text,
          line: comment.location.start_line,
          yard: text.start_with?('@')
        )
      end

      visitor.shape.solidify!
      visitor.shape
    end

    def parse_with_old_ast(source, path: '(unknown)')
      shape = Shape.new
      begin
        ast = RubyVM::AbstractSyntaxTree.parse(source)
      rescue SyntaxError => e
        warn "  [ast] #{path}: #{e.message}"
        return shape.solidify!
      end

      private_line = nil
      walk_old_ast(ast) do |n|
        private_line = n.first_lineno if n.type == :VCALL && n.children[0] == :private

        case n.type
        when :DEFN
          vis = private_line && n.first_lineno > private_line ? :private : :public
          shape.methods << Method.new(
            name: n.children[0],
            visibility: vis,
            params: Params.empty,
            location: nil,
            class_name: nil,
            class_method: false
          )
        when :CONST
          shape.constant_refs << n.children[0].to_s
        when :FCALL
          method_name = n.children[0]
          args = n.children[1]
          case method_name
          when :require, :require_relative
            if args&.type == :LIST && args.children[0]&.type == :STR
              shape.requires << Requirement.new(
                type: method_name, path: args.children[0].children[0], location: nil
              )
            end
          when :include, :extend
            if args&.type == :LIST && args.children[0]&.type == :CONST
              shape.includes << Inclusion.new(
                type: method_name, name: args.children[0].children[0].to_s, location: nil
              )
            end
          when :attr_reader, :attr_accessor, :attr_writer
            if args&.type == :LIST
              args.children.compact.each do |c|
                shape.attrs << Attribute.new(kind: method_name, name: c.children[0], location: nil) if c.type == :LIT
              end
            end
          end
        when :CLASS
          shape.classes << n.children[0].children.last.to_s if n.children[0]&.type == :COLON2
        when :MODULE
          shape.modules << n.children[0].children.last.to_s if n.children[0]&.type == :COLON2
        end
      end

      shape.solidify!
      shape
    end

    def walk_old_ast(node, &block)
      return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

      block.call(node)
      node.children.each { |c| walk_old_ast(c, &block) }
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   PrismPrompts — Structured prompts for Claude
  #
  #   Instead of sending raw file contents, send shapes and diffs.
  #
  # ════════════════════════════════════════════════════════════════

  module PrismPrompts
    module_function

    def build(stone:, kin:, diff:, style: :gentle)
      diff_text = diff ? diff.describe : '(first analysis, no prior shape)'

      kin_text = kin.map { |k|
        shape = Parser.parse_shape(k.essence, path: k.path.to_s)
        <<~KIN
          --- #{k.path.basename} ---
          Shape:
          #{shape.describe}

          Full source:
          ```ruby
          #{k.essence}
          ```
        KIN
      }.join("\n")

      case style
      when :gentle
        <<~PROMPT
          A Ruby file has been modified. Here is a structural analysis of the change:

          ## What Changed in #{stone.path.basename}
          #{diff_text}

          ## Current Source
          ```ruby
          #{stone.essence}
          ```

          ## Related Files That May Need Updates
          #{kin_text}

          Please make minimal, harmonious updates to the related files.
          Focus on:
          - New attributes or methods that related files should know about
          - Changed method signatures that callers need to match
          - New includes/modules that create new capabilities
          - Preserving existing comments and documentation
          Return each file as:
          === FILEPATH ===
          (content)
        PROMPT

      when :radical
        <<~PROMPT
          A Ruby file has evolved. Here's the structural delta:

          ## Mutation Report: #{stone.path.basename}
          #{diff_text}
          Severity: #{diff&.severity || 'unknown'}

          ## The Evolved Source
          ```ruby
          #{stone.essence}
          ```

          ## The Affected Ecosystem
          #{kin_text}

          Reimagine the related files. The mutation is #{diff&.severity || 'significant'}.
          Don't just patch — reconsider. If the architecture wants to move,
          let it move. Preserve tests and public contracts where possible.
          Return each file as:
          === FILEPATH ===
          (content)
        PROMPT

      when :poignant
        <<~PROMPT
          A file has changed, and its neighbors felt the tremor.

          _why once said: "See, it could just be the way the universe
          works, that a change in one place changes everything."

          ## The Tremor
          #{diff_text}

          ## The Source, in its new form
          ```ruby
          #{stone.essence}
          ```

          ## The Neighbors
          #{kin_text}

          Rewrite the neighbors so they sing in tune.
          Be gentle with comments — they are the author's voice.
          Be bold with structure — the code wants to evolve.
          Favor Ruby's intrinsic beauty: blocks, enumerables,
          pattern matching, and names that read like English.
          Return each file as:
          === FILEPATH ===
          (content)
        PROMPT
      end
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   DeepKin — AST-Aware Relationship Discovery
  #
  #   Finds kin through structural analysis, not just text matching.
  #
  # ════════════════════════════════════════════════════════════════

  module DeepKin
    module_function

    def discover(stone:, pond_stones:)
      my_shape = Parser.parse_shape(stone.essence, path: stone.path.to_s)
      my_classes = Set.new(my_shape.classes + my_shape.modules)

      kin = {}

      pond_stones.each do |other|
        next if other.path == stone.path

        other_shape = Parser.parse_shape(other.essence, path: other.path.to_s)

        reasons = []

        # 1. Direct require
        other_shape.requires.each do |req|
          reasons << "requires #{req.path}" if req.path.include?(stone.path.basename('.rb').to_s)
        end
        my_shape.requires.each do |req|
          reasons << "required by #{stone.path.basename}" if req.path.include?(other.path.basename('.rb').to_s)
        end

        # 2. Constant references
        other_consts = other_shape.external_constants
        my_consts    = my_shape.external_constants
        other_defines = Set.new(other_shape.classes + other_shape.modules)

        shared_outward = my_classes & other_consts
        shared_outward.each do |c|
          reasons << "#{other.path.basename} references #{c}"
        end

        shared_inward = other_defines & my_consts
        shared_inward.each do |c|
          reasons << "#{stone.path.basename} references #{c}"
        end

        # 3. Shared includes
        my_includes    = Set.new(my_shape.includes.map(&:name))
        other_includes = Set.new(other_shape.includes.map(&:name))
        shared = my_includes & other_includes
        shared.each do |i|
          reasons << "both include #{i}"
        end

        # 4. Superclass relationships
        other_shape.superclasses.each do |cls, superclass|
          reasons << "#{cls} inherits from #{superclass}" if my_classes.include?(superclass)
        end
        my_shape.superclasses.each do |cls, superclass|
          reasons << "#{cls} inherits from #{superclass}" if other_defines.include?(superclass)
        end

        kin[other] = reasons unless reasons.empty?
      end

      kin
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   ShapeCache — Lazy, mtime-aware shape caching
  #
  # ════════════════════════════════════════════════════════════════

  class ShapeCache
    def initialize
      @cache = {}
    end

    def shape_for(stone)
      key = stone.path.to_s
      entry = @cache[key]

      if entry && entry[:mtime] == stone.path.mtime
        entry[:shape]
      else
        shape = Parser.parse_shape(stone.essence, path: key)
        @cache[key] = { mtime: stone.path.mtime, shape: shape }
        shape
      end
    end

    def invalidate(stone)
      @cache.delete(stone.path.to_s)
    end

    def stats
      { entries: @cache.size, memory_estimate: "~#{@cache.size * 2}KB" }
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   CLI
  #
  #   Extracted from the original `if __FILE__ == $0` block.
  #
  # ════════════════════════════════════════════════════════════════

  def self.cli!(argv = ARGV)
    # NOTE: StringSwims refinements can't be used here (Module#using not permitted in methods)
    # The CLI works through the Koipond module API directly

    # ── Early exit for swim mode ─────────────────────────
    if argv.first == 'swim'
      root = argv[1] || Dir.pwd
      return swim!(root)
    end

    # ── Pattern matching on ARGV ─────────────────────────
    style = case argv
            in [*, '--radical',  *] then :radical
            in [*, '--poignant', *] then :poignant
            else :gentle
            end

    trace = argv.include?('--trace')
    root  = argv
            .reject { |a| a.start_with?('--') }
            .first
            .then { |r| r || Dir.pwd }

    narrate! if trace

    pond  = pond(root)
    stone = pond.last_touched

    puts pond
    puts "Last touched: #{stone&.inspect || 'nothing'}"
    puts "Kin: #{stone&.kin&.map(&:to_s)&.join(', ')&.then { |s| s.empty? ? '(solitary)' : s } || 'n/a'}"

    puts

    return unless stone

    reflection = stone.throw!(style: style)
    puts reflection
    reflection.preview

    return unless reflection.reach.positive?

    print "\nApply these changes? (y/n) "
    if $stdin.gets&.chomp&.downcase == 'y'
      reflection.apply!
      puts "\n  🐟 The pond settles. For now."
    else
      puts "\n  🐟 The stone skipped. Nothing changed."
    end
  end

  # ════════════════════════════════════════════════════════════════
  #
  #   swim! — Interactive REPL
  #
  #   A _why the lucky stiff flavored REPL where users enter
  #   the pond world. lowercase prompts. poetic narration.
  #   fish guide you through the water.
  #
  # ════════════════════════════════════════════════════════════════

  def self.swim!(root = Dir.pwd)
    pond = Pond.new(root)

    # Welcome scene
    puts <<~WELCOME

      ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿
         you are standing at the edge
         of a small pond. #{pond.count} stones
         rest beneath the surface.
    WELCOME

    stone = pond.last_touched
    if stone
      ago = time_ago(stone.path.mtime)
      puts '       the water remembers:'
      puts "         #{stone.path.basename} touched the shore"
      puts "         #{ago}."
    end

    puts "    ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿\n\n"

    # Show commands
    show_swim_help

    # REPL loop
    style = :gentle
    loop do
      print '  🐟 '
      input = $stdin.gets&.chomp&.strip&.downcase
      break if input.nil?

      case input.split.first
      when 'throw'
        handle_throw(pond, style)
      when 'look'
        handle_look(pond)
      when 'kin'
        handle_kin(pond, input)
      when 'style'
        style = handle_style(input)
      when 'trace'
        toggle_trace
      when 'help', '?'
        show_swim_help
      when 'leave', 'exit', 'quit', 'q'
        puts "  🐟 the pond settles. for now.\n\n"
        break
      when '', nil
        next
      else
        puts "  🐟 the water doesn't understand."
        puts "     try: throw, look, kin, leave\n\n"
      end
    end
  end

  # ── Swim helpers ─────────────────────────────────────

  def self.time_ago(time)
    seconds = (Time.now - time).to_i
    return 'just now' if seconds.negative? # future mtime (clock skew)

    case seconds
    when 0..59 then "#{seconds} seconds ago"
    when 60..3599 then "#{seconds / 60} minutes ago"
    when 3600..86_399 then "#{seconds / 3600} hours ago"
    else "#{seconds / 86_400} days ago"
    end
  end

  def self.show_swim_help
    puts <<~HELP
      what would you like to do?

      > throw        (watch the ripples)
      > look         (peer into the water)
      > kin          (who swims together?)
      > style        (gentle, radical, poignant)
      > trace        (toggle narration)
      > leave        (the pond stays still)

    HELP
  end

  def self.handle_throw(pond, style)
    stone = pond.last_touched
    unless stone
      puts "  🐟 the pond is empty. no stones to throw.\n\n"
      return
    end

    puts "  🪨 throwing #{stone.path.basename}...\n"
    reflection = stone.throw!(style: style)
    puts "  #{reflection}\n"

    if reflection.reach.positive?
      reflection.preview
      print "\n  apply these changes? (y/n) "
      if $stdin.gets&.chomp&.downcase == 'y'
        reflection.apply!
        puts "\n  🐟 the pond settles. changes applied.\n\n"
      else
        puts "\n  🐟 the stone skipped. nothing changed.\n\n"
      end
    else
      puts "\n"
    end
  end

  def self.handle_look(pond)
    stone = pond.last_touched
    puts "\n  #{pond}"
    if stone
      puts "  last touched: #{stone.inspect}"
      puts "  kin: #{stone.kin.map(&:to_s).join(', ').then { |s| s.empty? ? '(solitary)' : s }}"
    end
    puts "\n"
  end

  def self.handle_kin(pond, input)
    parts = input.split
    stone = if parts[1]
              pond.stones.find { |s| s.path.basename('.rb').to_s == parts[1].sub(/\.rb$/, '') }
            else
              pond.last_touched
            end

    unless stone
      puts "  🐟 no stone found.\n\n"
      return
    end

    puts "\n  #{stone} knows:"
    kin = stone.kin
    if kin.empty?
      puts '    (no one. it swims alone.)'
    else
      kin.each { |k| puts "    #{k}" }
    end
    puts "\n"
  end

  def self.handle_style(input)
    parts = input.split
    new_style = parts[1]&.to_sym

    if %i[gentle radical poignant].include?(new_style)
      puts "  🐟 style set to #{new_style}.\n\n"
      new_style
    else
      puts "  🐟 styles: gentle, radical, poignant\n\n"
      :gentle
    end
  end

  def self.toggle_trace
    if @trace_on
      Narrate.off!
      @trace_on = false
    else
      Narrate.on!
      @trace_on = true
    end
    puts "\n"
  end
end

# ╔═══════════════════════════════════════════════════════════╗
# ║  The Grand Trick                                         ║
# ║                                                          ║
# ║  if __FILE__ == $0                                       ║
# ║                                                          ║
# ║  This line means: "if this file was run directly."       ║
# ║  A file that is both library AND program.                ║
# ║  Require it, and only the module loads.                  ║
# ║  Run it, and it becomes a CLI.                           ║
# ║                                                          ║
# ║  Ruby doesn't mind. Ruby never minds.                    ║
# ╚═══════════════════════════════════════════════════════════╝

Koipond.cli! if __FILE__ == $PROGRAM_NAME
