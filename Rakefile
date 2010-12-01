require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'lib/xupa_emec/version'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  
  gem.name = "xupa_emec"
  gem.homepage = "http://github.com/bernardo/xupa_emec"
  gem.license = "MIT"
  gem.summary = %Q{Puxa dados sobre instituições de ensino superior do site do MEC para o formato CSV.}
  gem.description = %Q{Puxa dados sobre instituições de ensino superior do site do MEC para o formato CSV.}
  gem.email = "berpasan@gmail.com"
  gem.authors = ["Bernardo de Pádua"]
  gem.executables = ['xupa_emec']
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'activesupport', '~> 3.0'
  gem.add_runtime_dependency 'mechanize', '~> 1.0'
  gem.add_runtime_dependency 'trollop', '~> 1.16'
  gem.add_runtime_dependency 'fastercsv', '~> 1.5'
  gem.add_runtime_dependency 'nokogiri', '~> 1.4'
  gem.version = XupaEmec::Version::STRING
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "xupa_emec #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
