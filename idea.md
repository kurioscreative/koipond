> Explore a gem that rewrote the related code to the most recently changed file using the intrinsic qualities of ruby and the Claude Code CLI. This is in the spirit of why the lucky stiff exploration of ruby, rather than a real production or development tool.
> 2:57 PM

6 steps

The gemspec — minimal, with personality
koi.gemspec

An example session showing Koi in IRB — the playground where Ruby and \_why's spirit feel most at home
garden.rb
Now let me create the README — the exploration narrative, written in \_why's spirit:

2 steps

Presented 5 files

Thought process
I've created all the files. Let me write a concise summary that captures the spirit of the exploration without over-explaining, since the user can read the files themselves.
Koi — the gem
The whole thing lives in one file (lib/koi.rb), ~400 lines. \_why would approve of the density.
What it does: Detects your most recently changed .rb file, discovers its relatives through require statements and name references, sends the context to claude -p with a style-specific prompt, and parses back a set of rewrites. Three styles: --gentle, --radical, --poignant.
The Ruby features it showcases as first-class design elements, not incidental syntax:
Feature Where it lives Why it matters
Refinements StringSwims — "user.rb".ripple! Scoped monkey-patching. Open classes with manners.
Struct Stone, Reflection Zero-boilerplate value objects that you can extend inline.
Comparable Stone#<=> — define one, get six operators The pond sorts files by mtime automatically.
Enumerable Pond#each — define one, get ~60 methods pond.select, .max, .tally all work for free.
method_missing pond.user_model.kin.throw! Files become methods on the Pond. Reads like English.
Lambdas in a Hash Wave::STYLES — strategy pattern in 3 lines First-class functions stored as data. FP inside OOP.
Blocks stone.throw! { |w| w.style = :radical } Caller-side customization with zero ceremony.
Lazy Enumerator stone.deep_kin(depth: 5).first(3) Breadth-first graph traversal that only does the work you ask for.
TracePoint Koi.narrate! — nature documentary mode Live method-call observation without touching any code.
**FILE** == $0 Bottom of koi.rb Same file is both library and CLI.
Symbol#to_proc stones.map(&:to_s) The tiny miracle hiding in every Ruby codebase.
ObjectSpace Easter egg — count every Stone that ever existed Ruby's live heap introspection. Memories before garbage collection.
The examples/garden.rb file gives you three small classes (Seed → Flower → Basket) to throw stones at and watch ripple.
Speculative thought: This pattern — a single changed file triggering context-aware AI rewrites of its neighborhood — could be a genuinely interesting interaction model if extended with AST diffing (what specifically changed, not just that it changed) and git-aware co-change history (files that historically change together are deeper kin than require alone reveals). The current version uses textual require parsing; a version using Prism (Ruby 3.3's built-in parser) for full AST awareness would be a natural next step.
Readme
Document · MD
Koi
RB
koi

Koi
GEMSPEC
Garden
RB
Explore using Prism
3:11 PM

26 steps

Run the fixed AST diff engine

Architected comprehensive Prism exploration with educational demonstrations.
Now let me build the full Prism-powered evolution of Koi:

4 steps

Build a demonstration showing what Prism-specific features look like in practice — pattern matching on AST, comments, error tolerance, locations
prism_features.rb

Run the Prism features demonstration
Now let me write the exploration README that ties it all together:

1 step

Copy new files to outputs

Presented 3 files
Three files, three layers of the exploration:
PRISM.md is the narrative — the full \_why-style walkthrough of what Prism gives Ruby and how it transforms Koi from text-matching to structural understanding.
prism_pond.rb (~550 lines) is the working code. It builds three new abstractions on top of the original Koi:
Abstraction What it does Ruby feature showcased
Shape A file's structural fingerprint — classes, methods, attrs, constants, includes, visibility Data.define (immutable value objects, Ruby 3.2), Struct (mutable builder), Set
ShapeDiff Compares two Shapes and produces a semantic changelog with magnitude scoring Computed properties, filter_map, the Data.define MethodChange type
ShapeVisitor Prism's Visitor pattern — typed dispatch to named node types instead of manual tree walking Prism::Visitor (or fallback to recursive walk on old AST)
DeepKin Finds relationships through constant references, superclasses, and shared module includes — not just require Set algebra (union, intersection, difference)
PrismPrompts Generates prompts from diffs and shapes instead of raw source Lambdas, heredocs, structural templating
ShapeCache Memoizes parsed shapes by path+mtime Hash as lazy cache
prism_features.rb is the live demonstration — runs on Ruby 3.2 and shows the seven gifts of Prism side by side with the old AST's limitations: pattern matching on nodes, error tolerance (all 5 broken code samples crash the old parser), comment preservation, byte-precise locations, and rich parameter extraction.
The key insight this exploration surfaces: Prism lifts the conversation with Claude from Layer 1 (raw text) to Layer 2 (structural understanding). The prompt shrinks from "here's 200 lines, something changed" to "here's a semantic diff: 2 methods added, 1 signature changed, magnitude = architectural." Claude gets understanding instead of information, and the rewrites become surgical instead of wholesale.
Prism
Document · MD
Prism pond
RB
Prism features
RB
Simulate the desired experience playing with koi.rb
3:24 PM

4 steps

The soil — a dependency of seed, a foundation layer
soil.rb

The gardener — the orchestrator, references everything
gardener.rb
Now let me touch seed.rb most recently to simulate the "just changed" scenario, then build the full simulation:

7 steps

Check the final acts of the simulation — the throw, apply, and easter eggs

Validated simulation execution and prepared deliverables for user.
Now let me capture the clean rendered output:

1 step

Copy simulation files and garden project to outputs

Presented 2 files
SESSION.txt is the full 670-line rendered playthrough. sim.rb runs it live (with typing animation and color when FAST isn't set). Here's the shape of the experience:
12 acts. 37 IRB prompts. Everything except the Claude CLI call runs live against real files.
Act What Fires Ruby Feature Showcased

1. Enter the Pond Koi.pond('./garden') → discovers 5 .rb files Enumerable, Comparable, Pathname globbing
2. method_missing pond.seed, pond.flower, pond.basket method_missing + respond_to_missing? contract
3. Kin Discovery stone.acquaintances (requires) + stone.mentioned_by (references) .scan, .filter_map, Set union
4. Deep Kin stone.deep_kin(depth: 3).first(5) Lazy Enumerator, breadth-first graph traversal that only does work you ask for
5. Shapes Koi::Parser.parse_shape(stone.essence) → classes, methods, attrs, external constants AST walking, the Shape struct, .external_constants via Set algebra
6. The Diff ShapeDiff.new(before:, after:) → +soil attr, +viable?, +expired?, magnitude 8 Data.define for MethodChange, computed severity scoring
7. Narration Koi.narrate! → fish swim visibly during pond.last_touched.kin TracePoint observing live method calls
8. Throw! pond.seed.throw!(style: :poignant) → 4 files reimagined Wave propagation, mock Claude response based on actual AST analysis
9. Apply reflection.apply! → soil, flower, gardener rewritten File I/O, .freeze on the "before" (the past is immutable)
10. Small Miracles "seed.rb".kin, "seed.rb".ripple! Refinements (StringSwims), Symbol#to_proc (&:to_s)
11. Easter Egg ObjectSpace.each_object(Koi::Stone).count → 6 stones in the heap ObjectSpace introspection, .ancestors chain
12. Census pond.any?, pond.select, pond.census Enumerable's 60 free methods from defining each, .tally
    The mock Claude response isn't random — it actually analyzes the garden files via AST and generates plausible changes: Flower gains :variety and rare?, Gardener validates varieties before planting, Basket learns by_variety and varieties, Soil gains supports?(variety). The ripples make structural sense because the simulation uses the real shape analysis to inform what Claude "would" write.
    The narration output during Act 7-8 looks like this:
    🐟 the pond remembers who moved last
    🐟 reading the stone's inscription
    🐟 searching for family in the water
    🐟 reading the address book
    🐟 who speaks this name?
    🐟 a stone arcs through the air
    🐟 ripples spreading outward
    🐟 the shape speaks
    Every one of those lines is a real TracePoint firing on a real method call. The fish swim because Ruby lets you watch its own execution in real time.
    Session
    TXT
    Sim
    RB
