file "template/_install_gems.rb", <<~CODE
  # Hint to avoid duplicates:
  # gem "oj", "~> 3.16" if needs_gem?("oj")
  def install_gems

  end
CODE

file "template/#{name}.rb", <<~CODE
  say "Hey! Let's start withe the #{human_name} installation"
  <%%= include "helpers" %>
  <%%= include "facts" %>
  <%%= include "git_setup" %>
  <%%= include "install_gems" %>
  <%%= include "core" %>
  <%%= include "extras" %>
  <%%= include "launch" %>


CODE

file "Gemfile", <<~CODE
  # frozen_string_literal: true

  source "https://rubygems.org"

  gem "debug"

  gem "rbytes", github: "rolling-space/rbytes"

  gem "rake"

  gem "minitest"
  gem "minitest-focus"
  gem "minitest-reporters"

CODE

file "template/_helpers.rb", <<-'CODE'
# frozen_string_literal: true

require 'uri'
require 'open-uri'
require 'fileutils'
# DEV_MODE=true rails new rvmd --database=postgresql --css=tailwind --skip-javascript --skip-sprockets --template="rails_prototype/template.rb" --skip-kamal

# TODO: add business specs foe existing operations
def source_paths
  [File.expand_path(__dir__)]
end
# plugins = []
# base_configs = []
# extensions = []
# gems = []
#
# specs = []
# deps = []

if Rails.version < '8.0.0'
  fail 'please use rails 8.0.0 or above'
end

def in_root(&block)
  inside Rails.application.root, &block
end

def do_bundle
  # Custom bundle command ensures dependencies are correctly installed
  Bundler.with_unbundled_env { run "bundle install" }
end

def bundle_add(*packages)
  packages.each do |package|
    say_status :info, "Adding #{package} to Gemfile"
    run "bundle add #{package}"
  end
end

def yarn(*packages)
  run("yarn add #{packages.join(" ")}")
end

def ruby_version
  in_root do
    if File.file?("Gemfile.lock")
      bundler_parser = Bundler::LockfileParser.new(Bundler.read_file("Gemfile.lock"))
      specs = bundler_parser.specs.map(&:name)
      locked_version = bundler_parser.ruby_version.match(/(\d+\.\d+\.\d+)/)&.[](1) if bundler_parser.ruby_version
      # ruby_version = Gem::Version.new(locked_version).segments[0..1].join(".") if locked_version
      # maybe_ruby_version = bundler_parser.ruby_version&.match(/ruby (\d+\.\d+\.\d+)./i)&.[](1)
      Gem::Version.new(locked_version).segments[0..1].join(".")
    end
  end
end

def specs
  in_root do
    if File.file?("Gemfile.lock")
      bundler_parser = Bundler::LockfileParser.new(Bundler.read_file("Gemfile.lock"))
      bundler_parser.specs.map(&:name)
    end
  end
end

def deps
  in_root do
    if File.file?("Gemfile")
      bundler_parser = Bundler::Dsl.new
      bundler_parser.eval_gemfile("Gemfile")
      bundler_parser.dependencies.map(&:name)
    end
  end
end

def has_gem?(name)
  deps.include?(name) || specs.include?(name)
end

def needs_gem?(name)
  !has_gem?(name)
end

def has_rails
  ((specs | deps) & %w[activerecord actionpack rails]).any?
end

def has_rspec
  in_root do
    ((specs | deps) & %w[rspec-core]).any? && File.directory?("spec")
  end
end


def download_file(from_path, to_path = from_path)
  if ENV['DEV_MODE']
    # for local development and upgrades
    copy_file from_path, to_path
  else
    base_url = 'https://raw.githubusercontent.com/OrestF/rails_prototype/rails_api'
    get([base_url, from_path].join('/'), to_path)
  end
end

def gem_add(gem_name, **args)
  if Gem.loaded_specs.key?(gem_name)
    say_status :info, "Ruby gem #{gem_name} already loaded"
  else
    gem gem_name, **args
  end

end


def app_name
  Rails.application.class.name.partition('::').first.parameterize
end

def root_dir
  Dir.pwd
end

def name
  root_dir.rpartition("/").last
end

def human_name
  name.split(/[-_]/).map(&:capitalize).join(" ")
end

def find_and_replace_in_file(file_name, old_content, new_content)
  text = File.read(file_name)
  new_contents = text.gsub(old_content, new_content)
  File.open(file_name, 'w') { |file| file.write new_contents }
end

CODE

file "template/_facts.rb", <<-'CODE'
## Gathered Facts
def say_facts
  say "Gathering facts..."
  say "=================="
  say "Ruby version: #{ruby_version}"
  say "Gemspecs: #{specs.join(", ")}"
  say "=================="
  say "App name: #{app_name}"
  say "Human name: #{human_name}"
  say "Root dir: #{root_dir}"
  say "Original Name: #{name}"
  say "=================="
  say "Git Base Config:"
  say "Git user name: #{git config: 'get user.name'}"
  say "Git user email: #{git config: 'get user.email'}"
end

CODE

file "template/_git_setup.rb", <<-'CODE'
def git_setup
  if File.exist?('/.dockerenv')
    say_status :info, "Setting up git..."
    say_status :info, "Setup git user info..."
    git config: "--global user.email '#{git_email}'"
    git config: "--global user.name '#{git_username}'"
    say_status :info, "Setup git global config..."
    say_status :info, "Setup the editor to vim..."
    git config: "--global core.editor 'vim -w'"
    say_status :info, "Set the global gitignore..."
    git config: "--global core.excludesfile '~/.gitignore_global'"
    say_status :info, "Set the default branch..."
    git config: "--global init.defaultBranch main"
    say_status :info, "Set the global pull options..."
    git config: "--global pull.rebase true"
    say_status :info, "Set the pull ff strategy..."
    git config: "--global pull.ff only"
    say_status :info, "Set the safe directories..."
    git config: "--global safe.directory /project"
    git config: "--global safe.directory /bench"

  end
end

CODE

file "template/_launch.rb", <<-'CODE'
say "_launch.rb"
say "Launching...!"
say_facts
git_setup
install_gems

after_bundle do
  add_core

end

CODE

file "template/_core.rb", <<-'CODE'
say "_core.rb"
def add_core

end

CODE


file "Rakefile", <%= code 'Rakefile' %>
file "README.md", <%= code 'README.md' %>
file ".gitignore", <%= code '.gitignore' %>
