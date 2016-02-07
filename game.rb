require 'sinatra'
require 'sinatra/base'

class Array
  def to_sentence(options = {})
    options[:word] ||= 'and'
    case length
    when 1 then self[0].to_s.dup
    when 2 then self.join " #{options[:word]} "
    else [self[0..-2].join(', '), self[-1]].join " #{options[:word]} "
    end
  end
end

get '/' do
  erb :'index.html'
end

post '/play' do
  @roll = rand(6) + 1
  @amount = params['game']['amount'].to_i
  @bets = params['game']['bet_on'].keys.map(&:to_i)
  @odds = Rational(@bets.count, 6)
  @return = (@amount / @odds).to_i - @amount
  @success = @bets.include? @roll
  erb :'roll.html'
end
