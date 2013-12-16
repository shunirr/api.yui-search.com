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
  doc = Nokogiri::HTML.parse(open(html).read)
  title, site_title = doc.xpath('//title').text.split('｜')
  site_permalink = doc.xpath('//link[@rel="start"]').first[:href]
  permalink = doc.xpath('//p[@id="pankuzu"]/a').last[:href]
  content = doc.xpath('//div[@id="article"]')
  d = doc.xpath('//h2/span').first.text.gsub(' ', '').split(/[年月日:]/).map {|a| a.to_i }
  date = Date.new(d[0], d[1], d[2])
  image_node = content.xpath('//img')
  image = nil
  image_node.each do |i|
    if i[:src].include? 'jpg'
      image = i[:src]
      break
    end
  end

  bodies = []
  content.children.each do |child|
    id = child.attribute('id')
    next if id and id[0] == 'link' 
    next if child.name == 'script'
    bodies << child.text
  end
  body = bodies.join

  next unless body.include? '小倉唯' and body.include? 'ゆいかおり' 

  site = find_site_or_insert(site_permalink, site_title)
  entry = {
    'permalink' => permalink,
    'title' => title,
    'image' => image,
    'body' => "#{title} #{body}",
    'site' => site,
    'created_at' => date.to_time.to_i
  }
  add_entry entry

  puts "add #{title}"
end

