
# Mine Games 0.0  
# (c) 2012-2012 Matthew Steedman

require('./lib/extend.js')

players = []
player_nicks = []
started = false
mine = []
turn = 0

class Player
  constructor: (@name) ->
    @deck =   []
    @hp = 100
    @level = 1
    @attack = 3
    @dead = false
    @hand = []
    @stats =
      level: @level
      attack: @attack
      mine: 0
      value: 0
      defense: 0

  addCards: (cards) ->
    if cards.length
      @deck.push card for card in cards
    else
      @deck.push cards

  draw: ->
    card = @deck.pop()
    @hand.push card
    @stats.attack += card.attack
    @stats.mine += card.mine
    @stats.value += card.value

  discard: (i) ->
    @deck.push @hand.splice(i, 1)

  deal: ->
    @draw() for i in [1..5]

# Cards
# -------------

class Card
  constructor: (options) ->

    @name = options.name or 'No name'
    @cost = 0
    @value = 0
    @actions = []
    @attack = 0
    @defense = 0
    @mine = 0
    @level = 0

    @init(options)

class Gem extends Card
  init: (options) ->
    @type = 'gem'
    @value = options.value

class Weapon extends Card
  init: (options) ->
    @type = 'weapon'
    @attack = options.attack
    @cost = options.cost

class Armor extends Card
  init: (options) ->
    @type = 'armor'
    @defense = options.defense
    @cost = options.cost

class Item extends Card
  init: (options) ->
    @type = 'item'
    @cost = options.cost
    @mine = options.mine

class Monster extends Card
  init: (options) ->
    @type = 'monster'
    @level = options.level
    @hp = options.hp
    @attack = options.attack

cards =
  silver: new Gem
    name: 'Silver'
    value: 1

  emerald: new Gem
    name: 'Emerald'
    value: 2

  gold: new Gem
    name: 'Gold'
    value: 3

  ruby: new Gem
    name: 'Ruby'
    value: 4

  diamond: new Gem
    name: 'Diamond'
    value: 5

  dagger: new Weapon
    name: 'Dagger'
    attack: 3
    cost: 3

  stone_pick: new Item
    name: 'Stone Pickaxe'
    cost: 3
    mine: 1

  goblin: new Monster
    name: 'Goblin'
    level: 1
    hp: 6
    attack: 3

# Game Actions
# -------------

generate_cards = ->
  mine.push(cards.silver) for i in [1..40]
  mine.push(cards.goblin) for i in [1..40]
  mine.push(cards.emerald) for i in [1..30]
  mine.push(cards.gold) for i in [1..20]
  mine.push(cards.ruby) for i in [1..10]
  mine.push(cards.diamond) for i in [1..5]
  mine.shuffle()
  for player in players
    do (player) ->
      player.deck.push(cards.silver) for i in [1..5]
      player.deck.push(cards.dagger) for i in [1..2]
      player.deck.push(cards.stone_pick) for i in [1..3]
      player.deck.shuffle()
      player.deal()

next_turn = ->
  turn++
  turn = 0 if turn >= players.length

  if players[turn].dead
    next_turn()
  else
    msg "#{players[turn].name}: It's your turn!"

check_turn = (player,cb) ->
  if turn is players.indexOf(player) and started
    cb()

# Player Actions
# -------------

join = (nick) ->
  unless nick in player_nicks
    players.push(new Player nick)
    player_nicks.push nick
    msg "#{nick} joined the game!"

start = ->
  if players.length > 0 and !started
    generate_cards()
    msg "Starting game!"
    started = true
    next_turn()

list_hand = (nick) ->
  if started
    player = players[player_nicks.indexOf(nick)]
    card_list = "" # TODO: shadowed variable

    for card in player.hand
      do (card) ->
        card_list = "#{card_list} [#{card.name}]"

    msg "#{nick}'s hand: " + card_list
    msg "
      #{nick}'s stats: 
      [Lv: #{player.stats.level}] 
      [HP: #{player.hp}] 
      [Attack: #{player.stats.attack}] 
      [Mines: #{player.stats.mine}] 
      [Money: #{player.stats.value}]
    "
  else
    msg "#{nick}, the game hasn't started yet."

mine_card = (nick) ->
  player = players[player_nicks.indexOf(nick)]
  check_turn player, ->
    if started and player.stats.mine > 0
      player.stats.mine--
      card = mine.pop()
      msg "You drew a #{card.name} from the Mine!"
      if card.type is 'gem'
        msg "Putting it in your deck."
        player.deck.push card
      else
        if Math.floor Math.random()
          msg "You attack first, dealing #{player.stats.attack} damage."
          if player.stats.attack >= card.hp
            msg "The #{card.name} perishes."
          else
            msg "The #{card.name} counter-attacks for #{card.attack - player.stats.defense} damage."
            msg "Discarding."
            player.hp -= card.attack - player.stats.defense
        else
          msg "The #{card.name} attacks first, dealing #{card.attack} damage."
          msg "Discarding."
          player.hp -= card.attack - player.stats.defense

card_info = (text) ->
  text = text.toLowerCase()
  for key, value of cards
    if name.toLowerCase() is text
      card = cards[card]


# IRC Config
# -------------

config =
  channels: ['##mine_games']
  server: 'irc.freenode.net'
  botName: 'MineGames'

irc = require 'irc'

bot = new irc.Client config.server, config.botName,
  channels: config.channels

msg = (text) ->
  bot.say config.channels[0], text

bot.addListener "message", (from, to, text, message) ->
  if /^[!](.*)$/.test text
    switch text.match(/^[!](.*)$/)[1]
      when 'join' then join(from)
      when 'start' then start()
      when 'hand' then list_hand(from)
      when 'mine' then mine_card(from)
      when 'info' then card_info(text.match(/^[!](\S*)\s?(.*)$/)[2])
