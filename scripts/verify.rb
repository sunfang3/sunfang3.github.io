#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

ROOT = File.expand_path("..", __dir__)
Dir.chdir(ROOT)

def fail!(message)
  warn "FAIL: #{message}"
  exit 1
end

def ok(message)
  puts "ok  #{message}"
end

def public_path(*parts)
  File.join("public", *parts)
end

graph, status = Open3.capture2("hugo", "mod", "graph")
fail!("hugo mod graph failed") unless status.success?
graph.include?("github.com/pgsty/oink@v1.0.0") || fail!("OINK is not pinned to v1.0.0")
ok("oink@v1.0.0")

build = [
  "hugo",
  "--cleanDestinationDir",
  "--gc",
  "--minify",
  "--environment", "production",
  "--printPathWarnings",
  "--panicOnWarning"
]
fail!("hugo production build failed") unless system(*build)
ok("production build")

{
  "index.html" => true,
  "en/index.html" => true,
  "notes/index.html" => true,
  "en/notes/index.html" => true,
  "papers/index.html" => true,
  "en/papers/index.html" => true,
  "about/index.html" => true,
  "en/about/index.html" => true,
  "llms.txt" => true,
  "robots.txt" => true,
  "docs/index.html" => false,
  "blog/index.html" => false,
  "book/index.html" => false,
  "fr/index.html" => false
}.each do |rel, should_exist|
  exists = File.exist?(public_path(rel))
  if should_exist
    exists ? ok(rel) : fail!("missing #{rel}")
  else
    exists ? fail!("should not exist #{rel}") : ok("absent #{rel}")
  end
end

%w[zh en].each do |lang|
  hits = Dir.glob(public_path("offline-search-index.#{lang}*.json"))
  hits.empty? ? fail!("missing offline-search-index.#{lang}*.json") : ok(hits.join(", "))
end

needles = {
  "index.html" => "孙方",
  "en/index.html" => "Fang Sun",
  "about/index.html" => "sunfang3",
  "en/about/index.html" => "Fang Sun"
}
needles.each do |rel, text|
  File.read(public_path(rel)).include?(text) ? ok("#{rel} has #{text}") : fail!("#{rel} missing #{text.inspect}")
end

["Project Name", "example.org", "PROJECT-DOCS"].each do |banned|
  hits = Dir.glob("public/**/*.{html,xml,txt,json}").select do |path|
    File.file?(path) && File.read(path).include?(banned)
  end
  fail!("placeholder #{banned.inspect} in #{hits.join(', ')}") unless hits.empty?
end
ok("no starter placeholders")

File.read(public_path("robots.txt")).include?("Allow: /") || fail!("robots.txt is not Allow: /")
ok("robots.txt")

puts "PASS"
