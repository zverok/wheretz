Gem::Specification.new do |s|
  s.name     = 'wheretz'
  s.version  = '0.0.5'
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/wheretz'

  s.summary = 'Fast and precise time zone by geo coordinates lookup'
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.travis.yml
    )$/x
  end
  s.require_paths = ["lib"]
  s.bindir = 'bin'
  s.executables << 'wheretz'

  s.add_development_dependency 'georuby', '~> 2.5'

  s.add_development_dependency 'tzinfo'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'saharspec'

  s.add_development_dependency 'rubocop', '~> 0.85'
  s.add_development_dependency 'rubocop-rspec'

  s.add_development_dependency 'rmagick'
  s.add_development_dependency 'dbf'
end
