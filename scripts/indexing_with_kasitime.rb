#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'groonga'
require 'date'

dbpath = ARGV.shift
htmldir = ARGV.shift
if dbpath.nil? or htmldir.nil?
  puts "usage: #{$PROGRAM_NAME} [DB_PATH] [SOURCE_PATH]"
  exit 0
end

if File.exist?(dbpath)
  @database = Groonga::Database.open(dbpath)
else
  @database = Groonga::Database.create(:path => dbpath)
  Groonga::Schema.define do |schema|  
    schema.create_table("Sites",
                        :type => :hash, 
                        :key_type => "ShortText") do |table|
      table.text("title")
    end

    schema.create_table("Entries", :type => :array) do |table|
      table.text("permalink")
      table.text("title")
      table.text("body")
      table.text("image")
      table.time("created_at")
      table.reference("site", "Sites")
    end

    schema.create_table("Terms",
                        :type => :patricia_trie,
                        :key_type => "ShortText",
                        :default_tokenizer => "TokenBigram",
                        :key_normalize => true) do |table|
      table.index("Entries.body")
      table.index("Sites._key")  
    end
  end
end  

def find_site_or_insert(permalink, title)
  site = Groonga['Sites'][permalink]
  if site.nil?
    Groonga['Sites'][permalink] = { 'title' => title }
  end
  Groonga['Sites'][permalink]
end

def add_entry(entry)
  Groonga['Entries'].add entry
end

Dir.glob("#{htmldir}/*.html").each do |html|
  id = File.basename(html, '.html')

  doc = Nokogiri::HTML.parse(open(html).read)
  title = doc.xpath('//h1').text
  site_title = "歌詞タイム"
  site_permalink = "http://www.kasi-time.com"
  permalink = "#{site_permalink}/item-#{id}.html"
  content = open("#{htmldir}/#{id}.txt").read

  site = find_site_or_insert(site_permalink, site_title)
  entry = {
    'permalink' => permalink,
    'title' => title,
    'image' => nil,
    'body' => "#{title} #{content}",
    'site' => site,
    'created_at' => nil
  }
  add_entry entry

  puts "add #{title}"
end

