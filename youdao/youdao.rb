#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'colorize'

FILENAME = File.expand_path '../dictionary', __FILE__

# get youdao fanyi api key from url: http://fanyi.youdao.com/openapi?path=data-mode
KEYFROM = #key form
KEY = #key

def translate(words)
  words = words.to_s
  url = "http://fanyi.youdao.com/openapi.do?keyfrom=#{KEYFROM}&key=#{KEY}&type=data&doctype=json&version=1.1&q=" + words
  res = Net::HTTP.get_response URI url
  if res.code == "200"
    data = JSON.parse(res.body)
    parse_data data
  else
    raise "network failure"
  end

  store_words(words, data) if not stored?(words)
end


def parse_data(data)
  case data["errorCode"]
  when 0
    print_data(data)
  when 20
    puts "要翻译的文本过长"
  when 30
    puts "无法进行有效的翻译"
  when 40
    puts "不支持的语言类型"
  when 50
    puts "无效的API key"
  when 60
    puts "无词典结果，仅在获取词典结果生效"
  else
    puts "不能释义的 errorCode"
  end
end

def print_data(data)
  basic = data["basic"]
  web = data["web"]
  puts "/#{basic["phonetic"]}/  uk: /#{basic["uk-phonetic"]}/  us: /#{basic["us-phonetic"]}/".red if basic
  puts "翻译:\t#{data["translation"].join(" | ")}".yellow if data["translation"]
  puts "词典:\t#{basic["explains"].join(" | ")}".blue if basic
  puts "网义:"
  web.each {|e|
    puts "\t#{e["key"]}: #{e["value"].join(" | ")}"
  } if web
end

def store_words(words, data)
  print "\nStore #{words} to dictionary? Yy\t".red

  begin
    system("stty raw echo")
    input = STDIN.getc.chomp
  ensure
    system("stty -raw echo")
  end

  if input  =~ /y/i
    File.open(FILENAME, 'a') do |f|
      f.write "#{words}:"
      f.write "\t/#{data["basic"]["phonetic"]}/" if data["basic"] and data["basic"]["phonetic"]
      f.write  "\t#{data["translation"].join(" | ")}" if data["translation"]
      # f.write  "\t #{data["basic"]["explains"].join(" | ")}" if data["basic"]["explains"]
      f.write "\t#{Time.now.to_s.split(" +").first}\n"
    end
  end
end

def stored?(words)
  word_dict = []
  File.open(FILENAME, "r") do |f|
    f.readlines.each do |e|
      word_dict << e.split(":", 2).first
    end
  end

  if word_dict.include? words
    true
  else
    false
  end
end


translate ARGV.join(" ")
