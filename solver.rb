# frozen_string_literal: true
#

require 'debug'

class Prompt
  FREQUENCIES = {
    'E': 56.88,
    'A': 43.31,
    'R': 38.64,
    'I': 38.45,
    'O': 36.51,
    'T': 35.43,
    'N': 33.92,
    'S': 29.23,
    'L': 27.98,
    'C': 23.13,
    'U': 18.51,
    'D': 17.25,
    'P': 16.14,
    'M': 15.3,
    'H': 15.3,
    'G': 12.5,
    'B': 10.5,
    'F': 9.24,
    'Y': 9.06,
    'W': 6.57,
    'K': 5.61,
    'V': 5.13,
    'X': 1.48,
    'Z': 1.39,
    'J': 1.00,
    'Q': 1.00,
  }

  def initialize
    @wordlist = File.read('wordlist').split

    # Letters not in the word
    @exclude  = []

    # Letters in the correct place in the word
    @placed   = { 0 => nil, 1 => nil, 2 => nil, 3 => nil, 4 => nil }

    # Letters in the word, but NOT in this place
    @unplaced = { 0 => [], 1 => [], 2 => [], 3 => [], 4 => [] }
  end

  def inspect
    "Excluded: #{@exclude}, Included: #{@include}, Placed: #{@placed}"
  end

  def call
    choose_action
  end

  private

  def choose_action
    puts "Current Possibilities: #{possibilities.count}"
    puts ''
    puts '1: Add Excluded Letters'
    puts '2: Add Included Letters'
    puts '3: List 10 Best Guesses'
    puts '9: Exit'
    puts '0: Debug Console'
    print '> '

    case gets.chomp.to_i
    when 1 then add_excluded_letter
    when 2 then add_included_letter
    when 3 then list_guesses
    when 9 then exit
    when 0 then binding.b
    end
  end

  # TODO: Weight words by how common they are
  def list_guesses
    puts possibilities.map { [_1.chars.uniq.sum { |c| FREQUENCIES[c.to_sym]} , _1] }.max(10).map { "#{_2} (#{_1.round(2)})" }
    puts ''
  end

  def add_excluded_letter
    get_input('What letters?').split.each { @exclude << _1.upcase }
    p @exclude
    puts ''
  end

  def add_included_letter
    letter   = get_input('What letter?').upcase
    position = get_input('What Position? (1-5)').to_i - 1

    case get_input('Was the position correct? (y/n)')
    when 'n'
      @unplaced[position] << letter
      p @unplaced
    when 'y'
      @placed[position] = letter
      p @placed.values
    end

    puts ''
  end

  protected

  def get_input(text)
    puts ''
    puts text
    print '> '

    gets.chomp
  end

  def possibilities
    possibilities = @wordlist
    possibilities = reject_words_with_excluded_letters(possibilities)
    possibilities = reject_words_with_letters_in_the_wrong_place(possibilities)
    possibilities = select_words_with_letters_in_correct_place(possibilities)

    # include = @unplaced.values.flatten
    # if include.any?
    #   possibilities = possibilities.select { _1.match? /(#{include.join('|')})/ }

    #   possibilities = possibilities.reject do |word|
    #     @unplaced.reject { _2.empty? }.any? { |i, letters| letters.include? word[i] }
    #   end
    # end

    # if @placed.compact.any?
    #   possibilities = possibilities.select do |word|
    #     @placed.compact.all? { |position, letter| word[position] == letter }
    #   end
    # end

    possibilities
  end

  def reject_words_with_excluded_letters(possibilities)
    return possibilities if @exclude.empty?

    possibilities.reject { _1.match? /(#{@exclude.join('|')})/ }
  end

  def reject_words_with_letters_in_the_wrong_place(possibilities)
    possibilities.reject do |word|
      @unplaced.reject { _2.empty? }.any? { |i, letters| letters.include? word[i] }
    end
  end

  def select_words_with_letters_in_correct_place(possibilities)
    return possibilities if @placed.compact.none?

    possibilities = possibilities.select do |word|
      @placed.compact.all? { |position, letter| word[position] == letter }
    end
  end
end

prompt = Prompt.new
loop { prompt.call }
