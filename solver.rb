# frozen_string_literal: true

class Danish
  def self.frequencies
    {
      "E": 16.7, "R": 7.61, "N": 7.55, "D": 7.24, "T": 7.03, "A": 6.01,
      "S": 5.67, "I": 5.55, "L": 4.85, "G": 4.56, "O": 4.14, "M": 3.40,
      "K": 3.07, "V": 2.88, "F": 2.27, "H": 1.88, "U": 1.85, "B": 1.41,
      "P": 1.33, "J": 1.11, "Å": 1.03, "Æ": 0.93, "Ø": 0.84, "Y": 0.72,
      "C": 0.29, "W": 0.02, "X": 0.02, "Z": 0.02, "Q": 0.01
    }
  end

  def self.words
    File.read('dansk').split.map(&:upcase)
  end
end

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
    File.read('english').split.map(&:upcase)
  end
end

class Prompt
  def initialize(language)
    @wordlist    = language.words
    @frequencies = language.frequencies

    @count = 0

    # Letters not in the word
    @exclude  = []

    # Letters in the correct place in the word
    @placed   = { 0 => nil, 1 => nil, 2 => nil, 3 => nil, 4 => nil }

    # Letters in the word, but NOT in this place
    @unplaced = { 0 => [], 1 => [], 2 => [], 3 => [], 4 => [] }
  end

  def inspect
    "Excluded: #{@exclude}, Unplaced: #{@unplaced}, Placed: #{@placed}"
  end

  def call
    choose_action
  end

  private

  def choose_action
    clear!
    if @count > 0
      puts "Top Guesses:"
      puts list_guesses
      puts ''
    end

    if @exclude.any?
      puts "Excluded: \"#{@exclude.join('", "')}\"" 
      puts ''
    end

    if @unplaced.values.reject(&:empty?).any?
      puts "Included, but unplaced:"
      puts @unplaced.map { |k, v| "#{k+1}: \"#{v.join('", "')}\""}.join("\n")
      puts ''
    end

    if @placed.values.compact.any?
      puts "Placed:"
      puts @placed.map { |k, v| v || '_' }.join(" ")
      puts ''
    end

    puts "Current Possibilities: #{possibilities.count}"
    puts ''
    puts '1: Add Excluded Letters'
    puts '2: Add Included Letters'
    puts '9: Exit'
    puts '0: Debug Console (type "c" to resume)'
    print '> '

    case gets.chomp.to_i
    when 1 then add_excluded_letter
    when 2 then add_included_letter
    when 9 then exit
    when 0 then require("debug") ? debugger : debugger
    end

    @count += 1
  end

  def list_guesses
    possibilities
      .map { [_1.chars.uniq.sum { |char| @frequencies[char.upcase.to_sym] || 0 }, _1] }
      .max(10)
      .map { " - \"#{_2}\" (Score: #{_1.round(2)})" }
  end

  def add_excluded_letter
    clear!
    get_input('What letters? (no delimeter)').chars.each { @exclude << _1.upcase }
  end

  def add_included_letter
    clear!
    letter   = get_input('What letter?').upcase
    position = get_input('What Position? (1-5)').to_i - 1

    case get_input('Was the position correct? (y/n)')
    when 'n'
      @unplaced[position] << letter
    when 'y'
      @placed[position] = letter
    end

    true
  end

  protected

  def clear! = puts(`clear`)

  def get_input(text)
    puts text
    print '> '

    gets.chomp
  end

  # Filter
  def possibilities
    possibilities = @wordlist
    possibilities = reject_words_with_excluded_letters(possibilities)
    possibilities = reject_words_with_letters_in_the_wrong_place(possibilities)
    select_words_with_letters_in_correct_place(possibilities)
  end

  # Rejects words that contain any letters that have been marked
  # as 'Excluded'
  def reject_words_with_excluded_letters(possibilities)
    return possibilities if @exclude.empty?

    possibilities.reject { _1.match? /(#{@exclude.join('|')})/ }
  end

  # Rejects words that contain a valid letter but in the wrong position
  def reject_words_with_letters_in_the_wrong_place(possibilities)
    possibilities.reject do |word|
      @unplaced.reject { _2.empty? }.any? { |i, letters| letters.include? word[i] }
    end
  end

  # Selects words that have valid letters in _correct_ position
  def select_words_with_letters_in_correct_place(possibilities)
    return possibilities if @placed.compact.none?

    possibilities.select do |word|
      @placed.compact.all? { |position, letter| word[position] == letter }
    end
  end
end

puts `clear`
puts "What Language?"
puts "1: English"
puts "2: Danish"
print '> '

language = case gets.chomp.to_i
           when 1 then English
           when 2 then Danish
           end

prompt = Prompt.new(language)

puts `clear`
loop { prompt.call }
