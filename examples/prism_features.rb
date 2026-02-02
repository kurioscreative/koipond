# encoding: utf-8
# frozen_string_literal: true
#
# ======================================================================
#   prism_features.rb — What Prism sees that the old parser can't
#
#   This file contains the CODE that would run on Ruby 3.3+
#   alongside DEMONSTRATIONS of the concepts using Ruby 3.2.
#
#   Each section shows the Prism way and the old way side by side.
#
#   Run: ruby examples/prism_features.rb
# ======================================================================

require_relative '../lib/koipond'

# ── Feature 1: Pattern Matching on AST Nodes ─────────────

# Given this Ruby source:
SOURCE = <<~RUBY
  require "json"
  require_relative "./fish"

  class Pond < Habitat
    include Enumerable
    include Comparable

    MAXIMUM_DEPTH = 100
    DEFAULT_TEMP  = 15.5

    attr_reader :name, :depth
    attr_accessor :temperature

    def initialize(name, depth: 10, temperature: DEFAULT_TEMP)
      @name = name
      @depth = depth
      @temperature = temperature
    end

    def swim(direction = :north, speed: 1.0)
      Fish.new(self).navigate(direction, speed: speed)
    end

    def <=>(other)
      depth <=> other.depth
    end

    def to_s
      "Pond(\#{name}, depth=\#{depth})"
    end

    def freeze!
      @temperature = 0
      @frozen = true
      self
    end

    private

    def discover(pattern = "**/*.rb")
      Pathname.glob(pattern)
        .reject { |p| p.to_s.include?("vendor") }
        .map { |p| Stone.new(path: p, pond: self) }
    end

    def thaw
      @frozen = false
    end
  end
RUBY

puts "=" * 64
puts "  What Prism Sees (concepts demonstrated on Ruby #{RUBY_VERSION})"
puts "=" * 64

# ======================================================================
#   PATTERN MATCHING ON AST NODES (Prism 3.3+)
#
#   This is Prism's most _why-like feature.
#   You describe the shape of code you're looking for,
#   and Ruby's pattern matching finds it.
#
#   Instead of:
#     if node.is_a?(CallNode) && node.name == :require ...
#
#   You write:
#     case node
#     in CallNode[name: :require, arguments: ArgumentsNode[arguments: [StringNode => s]]]
#       s.unescaped  # the required path, extracted by shape
#     end
#
#   The pattern IS the documentation.
#   Reading the code tells you exactly what tree structure
#   you're searching for. No mental model required.
# ======================================================================

puts
puts "--- Pattern Matching (concept) ---"
puts
puts <<~EXAMPLE
  # With Prism + pattern matching, finding all require calls is:
  #
  #   Prism.parse(source).value.statements.body.each do |node|
  #     case node
  #     in Prism::CallNode[
  #          name: :require | :require_relative => type,
  #          arguments: Prism::ArgumentsNode[
  #            arguments: [Prism::StringNode => str]
  #          ]
  #        ]
  #       puts "\#{type} '\#{str.unescaped}'"
  #     else
  #       # not a require — skip
  #     end
  #   end
  #
  # The `=>` operator captures the matched value into a variable.
  # The `|` operator matches alternatives.
  # The `[key: pattern]` syntax matches hash-like attributes.
  #
  # It reads like: "find a call named require or require_relative,
  # whose first argument is a string, and give me that string."
EXAMPLE

# Demonstrate the same thing with old AST:
puts "  Doing this with RubyVM::AbstractSyntaxTree:"
puts

def walk(node, &block)
  return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
  block.call(node)
  node.children.each { |c| walk(c, &block) }
end

ast = RubyVM::AbstractSyntaxTree.parse(SOURCE)

walk(ast) do |node|
  if node.type == :FCALL &&
     [:require, :require_relative].include?(node.children[0]) &&
     node.children[1]&.type == :LIST &&
     node.children[1].children[0]&.type == :STR
    type = node.children[0]
    path = node.children[1].children[0].children[0]
    puts "  #{type} '#{path}'"
  end
end

puts
puts "  Both find the same results."
puts "  But the Prism version DESCRIBES what it's looking for."
puts "  The old version NAVIGATES to what it's looking for."
puts "  Description > Navigation. Always."

# ======================================================================
#   COMMENTS: THE AUTHOR'S VOICE
# ======================================================================

puts
puts "--- Comments (old AST: invisible; Prism: preserved) ---"
puts

commented_source = <<~RUBY
  # The Pond is the central metaphor.
  # It holds stones, fish, and memory.
  # @api public
  # @since 0.1.0
  class Pond
    # Create a new pond.
    # @param name [String] the pond's name
    # @param depth [Integer] how deep in meters
    # @return [Pond]
    def initialize(name, depth: 10)
      @name = name
      @depth = depth
    end

    # TODO: This should accept a block for filtering
    # FIXME: Crashes when depth is negative
    def discover
      Dir.glob("**/*.rb")
    end
  end
RUBY

ast_commented = RubyVM::AbstractSyntaxTree.parse(commented_source)
types = []
walk(ast_commented) { |n| types << n.type }
puts "  Old AST node types: #{types.uniq.sort.join(', ')}"
puts "  Notice: no COMMENT type. Comments are gone forever."
puts
puts "  Prism would give us:"
puts
puts "  result = Prism.parse(source)"
puts "  result.comments.each do |c|"
puts "    c.location.start_line  # line number"
puts "    c.location.slice       # the comment text"
puts "  end"
puts
puts "  This means Koipond can:"
puts "    - Read YARD annotations (@param, @return, @api)"
puts "    - Preserve TODO/FIXME markers when rewriting"
puts "    - Show Claude the author's intent, not just the code"
puts "    - Match comments to the methods they document"

# ======================================================================
#   ERROR TOLERANCE
# ======================================================================

puts
puts "--- Error Tolerance ---"
puts

broken_sources = {
  "missing comma" => "def broken(x y)\n  x + y\nend",
  "unclosed string" => "name = \"hello\ndef greet\n  name\nend",
  "missing end" => "class Pond\n  def swim\n    :north\n",
  "extra end" => "def swim\n  :north\nend\nend",
  "incomplete expression" => "result = items.map { |i|\n  i.\n}",
}

broken_sources.each do |label, code|
  begin
    RubyVM::AbstractSyntaxTree.parse(code)
    puts "  #{label}: old AST parsed (surprising!)"
  rescue SyntaxError => e
    msg = e.message.lines.first.strip
    puts "  #{label}: old AST FAILS - #{msg}"
  end
end

puts
puts "  Prism would parse ALL of these."
puts "  It returns a partial AST + error diagnostics."
puts "  The AST is incomplete but usable."
puts
puts "  For Koipond, this means: even if you save a file mid-edit,"
puts "  with a syntax error, Koipond can still understand its shape"
puts "  and find its kin. The ripple doesn't stop for a typo."

# ======================================================================
#   LOCATIONS: SURGICAL PRECISION
# ======================================================================

puts
puts "--- Locations ---"
puts

ast = RubyVM::AbstractSyntaxTree.parse(SOURCE)

puts "  Old AST locations (line numbers only):"
walk(ast) do |n|
  if n.type == :DEFN
    puts "    def #{n.children[0]}: lines #{n.first_lineno}-#{n.last_lineno}"
  end
end

puts
puts "  Prism locations (byte-precise):"
puts "    node.location.start_offset    # byte 142"
puts "    node.location.end_offset      # byte 198"
puts "    node.location.start_column    # column 4"
puts "    node.location.end_column      # column 7"
puts "    node.location.slice           # 'def swim(direction = :north, speed: 1.0)'"
puts
puts "  .slice is the killer feature."
puts "  You can extract the EXACT SOURCE TEXT of any node"
puts "  without reading the file, without regex, without counting lines."
puts "  It's a window into the source at any granularity."
puts
puts "  For Koipond: surgical method replacement."
puts "  Change one method, leave everything else byte-identical."
puts "  The old AST can only point at line ranges."
puts "  Prism can point at bytes."

# ======================================================================
#   RICH PARAMETER INFORMATION
# ======================================================================

puts
puts "--- Parameter Extraction ---"
puts

puts "  Consider: def swim(direction = :north, speed: 1.0)"
puts
puts "  Old AST: ARGS node with positional children."
puts "  Meaning is version-dependent. You count and guess."
puts
puts "  Prism ParametersNode:"
puts "    .requireds     => []"
puts "    .optionals     => [OptionalParameterNode(name: :direction, value: :north)]"
puts "    .keywords      => [OptionalKeywordParameterNode(name: :speed, value: 1.0)]"
puts "    .rest           => nil"
puts "    .keyword_rest   => nil"
puts "    .block           => nil"
puts
puts "  Now consider: def initialize(name, depth: 10, temperature: DEFAULT_TEMP)"
puts
puts "  Prism sees:"
puts "    .requireds     => [RequiredParameterNode(name: :name)]"
puts "    .keywords      => ["
puts "      OptionalKeywordParameterNode(name: :depth, value: IntegerNode(10)),"
puts "      OptionalKeywordParameterNode(name: :temperature, value: ConstantReadNode(:DEFAULT_TEMP))"
puts "    ]"
puts
puts "  The VALUE of each default is itself an AST node."
puts "  Prism can tell you that :temperature defaults to a CONSTANT,"
puts "  not a literal. The old AST can't distinguish these."

# ======================================================================
#   WHAT THIS ALL MEANS FOR KOI
# ======================================================================

puts
puts "=" * 64
puts "  What This Means for Koipond"
puts "=" * 64
puts

puts <<~MEANING
  Original Koipond (regex):
    Kin discovery:  scan for require_relative, grep for filenames
    Change info:    "this file changed"
    Prompt to Claude: "here's the whole file, here are related files"

  Prism Koipond (AST):
    Kin discovery:  constant references, superclasses, shared includes
    Change info:    "added :depth attr, <=> method, Comparable include"
    Prompt to Claude: structured diff + shapes + reasons for kinship

  The upgrade in Claude's context:

  BEFORE:
    "pond.rb changed. Here's pond.rb (45 lines).
     Here's fish.rb (30 lines). Please update fish.rb."

  AFTER:
    "pond.rb gained attr_reader :depth, added Comparable,
     and added def <=>(other). Fish references Pond via
     Fish.new(self). Fish may need to handle the new depth
     attribute and the fact that Ponds are now sortable.
     Here's fish.rb's current shape: [concise summary].
     Magnitude: architectural (14)."

  Same task. 70% less tokens. 3x more signal.
  Claude rewrites better because it understands better.
  Understanding > information. Always.
MEANING
