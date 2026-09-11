#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "base64"
require "open3"
require "thread"
require "yaml"

ROOT = File.expand_path("..", __dir__)
CATALOG = YAML.load_file(File.join(ROOT, "data/catalog.yaml"))
CHECK_ONLY = ARGV.delete("--check")
PUBLISH = ARGV.delete("--publish")
README_CACHE = {}

abort "usage: ruby scripts/sync_catalog.rb [--check | --publish]" unless ARGV.empty? && !(CHECK_ONLY && PUBLISH)

def run_gh(*args)
  output, error, status = Open3.capture3("gh", *args)
  return output if status.success?

  warn error
  abort "GitHub CLI command failed: gh #{args.join(' ')}"
end

def page_sites(owner)
  raw = run_gh("api", "--paginate", "--slurp", "user/repos?per_page=100&affiliation=owner")
  repositories = JSON.parse(raw).flatten

  queue = Queue.new
  repositories.each { |repo| queue << repo }
  sites = Queue.new
  failures = Queue.new
  workers = Array.new(8) do
    Thread.new do
      loop do
        repo = queue.pop(true)
        attempts = 0
        loop do
          output, error, status = Open3.capture3("gh", "api", "repos/#{owner}/#{repo.fetch('name')}/pages")
          if status.success?
            page = JSON.parse(output)
            sites << repo.merge("page_url" => page.fetch("html_url")) if page["public"] && page["html_url"]
            break
          end
          break if error.include?("HTTP 404")

          attempts += 1
          if attempts == 3
            failures << "#{repo.fetch('name')}: #{error.strip}"
            break
          end
          sleep attempts
        end
      rescue ThreadError
        break
      rescue JSON::ParserError => error
        failures << "#{repo.fetch('name')}: #{error.message}"
      end
    end
  end
  workers.each(&:join)
  unless failures.empty?
    errors = []
    errors << failures.pop until failures.empty?
    abort "Could not inspect GitHub Pages:\n#{errors.join("\n")}"
  end
  results = []
  results << sites.pop until sites.empty?
  results
end

def category_for(repo, catalog)
  entry = catalog.fetch("entries").fetch(repo.fetch("name"), {})
  return entry.fetch("category") if entry["category"]

  topics = repo.fetch("topics", [])
  catalog.fetch("topics").each do |category, topic|
    return category if topics.include?(topic)
  end
  nil
end

def readme_metadata(owner, repo)
  name = repo.fetch("name")
  return README_CACHE[name] if README_CACHE.key?(name)

  output, error, status = Open3.capture3("gh", "api", "repos/#{owner}/#{name}/readme")
  unless status.success?
    warn "Could not read README for #{name}: #{error.strip}" unless error.include?("HTTP 404")
    return README_CACHE[name] = { "text" => "", "title" => nil }
  end

  text = Base64.decode64(JSON.parse(output).fetch("content"))
  title = text[/^\s*#\s+(.+?)\s*$/m, 1]&.gsub(/\s+/, " ")
  README_CACHE[name] = { "text" => text, "title" => title }
rescue JSON::ParserError, ArgumentError => error
  warn "Could not parse README for #{name}: #{error.message}"
  README_CACHE[name] = { "text" => "", "title" => nil }
end

def score(text, signals)
  signals.sum { |pattern, weight| text.scan(pattern).length * weight }
end

def inferred_category_for(repo, owner)
  metadata = readme_metadata(owner, repo)
  text = [repo.fetch("name").tr("-_", " "), repo["description"], metadata.fetch("text")].compact.join(" ").downcase
  papers = score(text, [[/论文/, 2], [/\bpapers?\b/, 1], [/manuscripts?/, 2], [/精读/, 2], [/文献/, 1], [/literature/, 1]])
  notes = score(text, [[/教材/, 2], [/伴读/, 2], [/companions?/, 2], [/textbooks?/, 2], [/习题/, 1], [/solutions?/, 1], [/学习笔记/, 2], [/study notes/, 2]])

  return nil if [papers, notes].max < 2 || papers == notes

  category = papers > notes ? "papers" : "notes"
  { "category" => category, "inferred_title" => metadata.fetch("title"), "confidence" => [papers, notes].max }
end

def label_for(repo, catalog, locale)
  entry = catalog.fetch("entries").fetch(repo.fetch("name"), {})
  entry[locale] || repo["inferred_title"] || repo.fetch("name")
end

def marker_block(items, catalog, locale)
  lines = items.map do |repo|
    "- [#{label_for(repo, catalog, locale)}](#{repo.fetch('page_url')})"
  end
  ["<!-- catalog:begin -->", *lines, "{.cards}", "<!-- catalog:end -->"].join("\n")
end

def replace_catalog(path, block)
  source = File.read(path)
  replacement = source.sub(/<!-- catalog:begin -->.*?<!-- catalog:end -->/m, block)
  abort "missing catalog markers in #{path}" if replacement == source && !source.include?(block)

  [source, replacement]
end

sites = page_sites(CATALOG.fetch("owner"))
entries = CATALOG.fetch("entries")
priority = entries.keys.each_with_index.to_h
selected = sites.filter_map do |repo|
  category = category_for(repo, CATALOG)
  if category
    repo.merge("category" => category)
  elsif CATALOG.fetch("ignored", []).include?(repo.fetch("name"))
    nil
  else
    inferred = inferred_category_for(repo, CATALOG.fetch("owner"))
    if inferred
      warn "Auto-classified #{repo.fetch('name')} as #{inferred.fetch('category')} (confidence #{inferred.fetch('confidence')})"
      repo.merge(inferred)
    end
  end
end

selected.sort_by! { |repo| [repo.fetch("category"), priority.fetch(repo.fetch("name"), Float::INFINITY), repo.fetch("name").downcase] }

known = selected.map { |repo| repo.fetch("name") }
unknown = sites.reject { |repo| known.include?(repo.fetch("name")) || CATALOG.fetch("ignored", []).include?(repo.fetch("name")) }
warn "Skipping unclassified Pages: #{unknown.map { |repo| repo.fetch('name') }.join(', ')}" unless unknown.empty?

targets = {
  "notes" => ["content/notes/_index.md", "zh"],
  "papers" => ["content/papers/_index.md", "zh"],
  "notes-en" => ["content/notes/_index.en.md", "en"],
  "papers-en" => ["content/papers/_index.en.md", "en"]
}

changed = false
targets.each_value do |relative_path, locale|
  category = relative_path.include?("/notes/") ? "notes" : "papers"
  block = marker_block(selected.select { |repo| repo.fetch("category") == category }, CATALOG, locale)
  source, replacement = replace_catalog(File.join(ROOT, relative_path), block)
  next if source == replacement

  changed = true
  if CHECK_ONLY
    puts "out of date: #{relative_path}"
  else
    File.write(File.join(ROOT, relative_path), replacement)
    puts "updated: #{relative_path}"
  end
end

abort "catalog is out of date" if CHECK_ONLY && changed

puts(changed ? "Catalog synchronized." : "Catalog already up to date.") unless CHECK_ONLY

if PUBLISH
  branch = `git -C #{ROOT} branch --show-current`.strip
  abort "--publish is only allowed from main (current branch: #{branch})" unless branch == "main"
  abort "production verification failed" unless system("ruby", File.join(ROOT, "scripts/verify.rb"))

  paths = %w[
    data/catalog.yaml
    content/notes/_index.md
    content/notes/_index.en.md
    content/papers/_index.md
    content/papers/_index.en.md
  ]
  abort "could not stage catalog files" unless system("git", "-C", ROOT, "add", *paths)

  unless system("git", "-C", ROOT, "diff", "--cached", "--quiet", "--", *paths)
    abort "could not commit catalog files" unless system(
      "git", "-C", ROOT, "commit", "-m", "chore: synchronize academic catalog", "--", *paths
    )
    abort "could not push catalog commit" unless system("git", "-C", ROOT, "push", "origin", "main")
  end
end
