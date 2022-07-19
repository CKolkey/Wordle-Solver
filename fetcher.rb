require 'nokogiri'
require 'faraday'
require 'debug'

def url(letter) = "https://www.krydsordbog.dk/ordbog/ord-med-#{letter}/5-bogstaver"

File.open('dansk', 'a') do |f|
  letters = ('a'..'z').to_a + %w[å ø æ]

  letters.each do |letter|
    page   = Faraday.get url(letter)
    parsed = Nokogiri.parse(page.body)
    words  = parsed.css(".word").map(&:text).uniq.join(" ")

    f.write "#{words} "
  rescue
    next
  end
end
