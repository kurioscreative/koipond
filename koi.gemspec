Gem::Specification.new do |s|
  s.name        = 'koi'
  s.version     = '0.2.0.prism'
  s.summary     = 'Throw a stone, watch the pond rewrite itself.'
  s.description = <<~DESC
    Koi finds the most recently changed Ruby file in your project,
    discovers its relatives through requires and references,
    and asks Claude to reimagine the related code.

    v0.2 adds Prism integration for structural understanding:
    AST-powered kin discovery, shape diffing, and semantic prompts.

    This is not a production tool. This is a toy.
    All the best things are.
  DESC

  s.authors     = ['A Curious Fish']
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/koi-pond/koi'

  s.files       = ['lib/koi.rb']
  s.bindir      = 'bin'
  s.executables = ['koi']

  s.required_ruby_version = '>= 3.1'

  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'inspiration'           => '_why the lucky stiff',
    'mood'                  => 'poignant',
  }
end
