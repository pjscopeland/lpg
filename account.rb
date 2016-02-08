require 'sinatra'
require 'json'

set port: 4568
set members: {
  1 => {id: 1, name: 'Patrick', card: '6014355731786694', points: 154},
  2 => {id: 2, name: 'Sam',     card: '6014355731755590', points: 597},
  3 => {id: 3, name: 'Evie',    card: '6014355731725686', points: 4512},
}

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
  members[id]
end

post '/members/:id/validate' do
  p params
  if member[:card] == params[:card]
    p member.to_json
  else
    status 401
    p nil.to_json
  end
end

get '/members/:id' do
  p member.to_json
end

post '/members/:id/credit' do
  member[:points] += amount
  p member.to_json
end

post '/members/:id/debit' do
  member[:points] -= amount
  p member.to_json
end


