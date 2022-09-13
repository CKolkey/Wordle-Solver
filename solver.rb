# frozen_string_literal: true

require 'tty-box'

def clear! = puts(`clear`)

class English
  def self.frequencies
    {
      'E': 56.88, 'A': 43.31, 'R': 38.64, 'I': 38.45, 'O': 36.51, 'T': 35.43,
      'N': 33.92, 'S': 29.23, 'L': 27.98, 'C': 23.13, 'U': 18.51, 'D': 17.25,
      'P': 16.14, 'M': 15.3,  'H': 15.3,  'G': 12.5,  'B': 10.5,  'F': 9.24,
      'Y': 9.06,  'W': 6.57,  'K': 5.61,  'V': 5.13,  'X': 1.48,  'Z': 1.39,
      'J': 1.00,  'Q': 1.00
    }
  end

  def self.words
    File.read('en_wordle').split.map(&:upcase)
  end
end

class View
  def initialize(possibilities)
    @possibilities = possibilities
  end

  def call
    clear!

    print top_guesses
    print excluded
    print unplaced
    print placed
  end

  def top_guesses
    TTY::Box.frame(
      top: 0, left: 0, width: 27, height: 9, padding: [0, 1],
      title: {
        top_left: ' Top Guesses ', bottom_left: " #{@possibilities.count} Remain "
      }
    ) { @possibilities.top_guesses }
  end

  def excluded
    TTY::Box.frame(
      top: 0, left: 28, width: 72, height: 3, padding: [0, 1],
      title: {
        top_left: ' Excluded '
      }
    ) { @possibilities.print_excluded }
  end

  def unplaced
    TTY::Box.frame(
      top: 3, left: 28, width: 72, height: 3, padding: [0, 1],
      title: {
        top_left: ' Unplaced '
      }
    ) { @possibilities.print_unplaced }
  end

  def placed
    TTY::Box.frame(
      top: 6, left: 28, width: 72, height: 3, padding: [0, 1],
      title: {
        top_left: ' Placed '
      }
    ) { @possibilities.print_placed }
  end
end

class Possibilities
  attr_reader :wordlist, :exclude, :placed, :unplaced

  def initialize(language)
    @wordlist    = language.words
    @frequencies = language.frequencies

    @exclude  = []
    @placed   = { 0 => nil, 1 => nil, 2 => nil, 3 => nil, 4 => nil }
    @unplaced = { 0 => [], 1 => [], 2 => [], 3 => [], 4 => [] }
  end

  def count = wordlist.count

  def complete? = @placed.values.compact.size == 5

  def update!(guess)
    guess[:exclude].each { |letter|             exclude_letter!(letter)           }
    guess[:include].each { |(letter, position)| include_letter!(letter, position) }
    guess[:correct].each { |(letter, position)| place_letter!(letter, position)   }
  end

  def top_guesses
    wordlist.map { |word| [word.chars.uniq.sum { @frequencies[_1.upcase.to_sym] || 0 }, word] }
            .max(10)
            .map { "\"#{_2}\" (Score: #{_1.round(2)})" }
            .join("\n")
  end

  def exclude_letter!(letter)
    @exclude.push(letter)
    wordlist.reject! { _1.chars.include?(letter) }
  end

  def include_letter!(letter, position)
    @unplaced[position].push(letter)
    wordlist.select! { _1.chars.include?(letter) && _1[position] != letter }
  end

  def place_letter!(letter, position)
    @placed[position] = letter
    wordlist.select! { _1[position] == letter }
  end

  def print_excluded
    exclude.uniq.sort.join(', ')
  end

  def print_unplaced
    unplaced.values.flatten.uniq.sort.join(', ')
  end

  def print_placed
    placed.map { _2 || '_' }.join(' ')
  end
end

class Prompt
  def call
    output(*prompt)
  end

  protected

  def prompt
    puts ''
    guess = get_input('Enter Guess').chars
    puts ''
    puts '(x = Exclude, i = Include, c = Correct)'
    marks = get_input('Mark Guess').chars

    [guess, marks]
  end

  def output(guess, marks)
    output = { exclude: [], include: [], correct: [] }
    guess.zip(marks).each_with_index do |(letter, mark), position|
      case mark
      when 'x'
        output[:exclude] << letter.upcase
      when 'i'
        output[:include] << [letter.upcase, position]
      when 'c'
        output[:correct] << [letter.upcase, position]
      end
    end

    output
  end

  def get_input(text)
    puts text
    print '> '

    gets.chomp
  end
end

# PROGRAM

clear!

possibilities = Possibilities.new(English)

loop do
  View.new(possibilities).call
  raise StopIteration if possibilities.complete?

  guess = Prompt.new.call
  possibilities.update!(guess)
rescue Interrupt
  clear!
  exit
end

puts "\nNice."
