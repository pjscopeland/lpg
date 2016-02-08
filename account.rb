require 'sinatra'
require 'json'

set bind: 'localhost', # Default is 0.0.0.0, but we don't want connections from any other server in this case
    port: 4568
set members: [
  {id: 1, name: 'Patrick', card: '6014355731786694', points: 154},
  {id: 2, name: 'Sam',     card: '6014355731755590', points: 597},
  {id: 3, name: 'Evie',    card: '6014355731725686', points: 4512},
]

def members
  settings.members
end

def id
  params[:id].to_i
end

def amount
  params[:amount].to_i
end

def member
  members.select { |m| m[:id] == id }.first
end

post '/members/validate' do
  # The correct card number has to be entered
  candidates = members.select { |m| m[:name].downcase == params[:name].downcase && m[:card] == params[:card] }
  if candidates.one?
    candidates.first.reject { |k, v| k == :card }.to_json
  else
    status 401
    nil
  end
end

# Increase a member's account (amount must be over 0)
post '/members/:id/credit' do
  if amount > 0
    member[:points] += amount
  else
    status 400
  end
  member.reject { |k, v| k == :card }.to_json
end

# Decrease account
post '/members/:id/debit' do
  if amount > 0
    member[:points] -= amount
  else
    status 400
  end
  member.reject { |k, v| k == :card }.to_json
end


