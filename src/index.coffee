
# Mine Games 0.0  
# (c) 2012-2012 Matthew Steedman

require('./lib/extend')
#cards = require('./cards')
irc = require 'irc'

players = []
player_nicks = []
started = false
mine = []
shop = []
turn = 0
monster = 
  hp:0
  card: {}

class Player
  constructor: (@name) ->
    @deck =   []
    @hp = 100
    @level = 1
    @attack = 3
    @defense = 0
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

  draw: (i = 1) ->
    for j in [1..i]
      card = @deck.pop()
      @hand.push card
      @stats.mine += card.mine
      @stats.value += card.value

  discard: (c) ->
    card = @hand.splice(@hand.indexOf(c), 1)[0]
    @deck.push card
    @stats.mine -= card.mine
    @stats.value -= card.value

  deal: ->
    @draw(5)

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
    @description = ""
    @action = ->
      msg "That card has no action."

    @init(options)

class Gem extends Card
  init: (options) ->
    @type = 'gem'
    @value = options.value
    @description = options.description ? "Used at the shop to buy more cards."

class Weapon extends Card
  init: (options) ->
    @type = 'weapon'
    @attack = options.attack
    @cost = options.cost
    @action = options.action
    @description = options.description ? "Can be used to attack Monsters or other Players."

class Armor extends Card
  init: (options) ->
    @type = 'armor'
    @defense = options.defense
    @cost = options.cost
    @description = options.description ? "Used to defend against attacks."

class Item extends Card
  init: (options) ->
    @type = 'item'
    @cost = options.cost
    @mine = options.mine
    @action = options.action
    @description = options.description

class Monster extends Card
  init: (options) ->
    @type = 'monster'
    @level = options.level
    @hp = options.hp
    @attack = options.attack
    @description = options.description
    @loot = options.loot ? []

cards =

  find: (text) ->
    for key, value of @
      if @[key].name.toLowerCase() is text
        return @[key]


  # Gems

  rock: new Gem
    name: 'Rock'
    value: 0

  copper: new Gem
    name: 'Copper'
    value: 1

  silver: new Gem
    name: 'Silver'
    value: 2

  gold: new Gem
    name: 'Gold'
    value: 3

  diamond: new Gem
    name: 'Diamond'
    value: 5


  # Weapons

  dagger: new Weapon
    name: 'Dagger'
    attack: 3
    cost: 3
    action: (player, discard) ->
      attack(player, @attack + player.attack, discard)


  # Items

  pickaxe: new Item
    name: 'Pickaxe'
    cost: 3
    mine: 1
    description: "Used to draw cards from the Mine."
    action: (player, discard) ->
      if monster.hp > 0 
        msg 'You cannot mine while there is a monster on the table.'
      else
        mine_card(player)
        discard()

  potion: new Item
    name: 'Potion'
    cost: 3
    description: "Restores 5 HP."
    action: (player) ->
      msg "Program me!"


  #Monsters

  goblin: new Monster
    name: 'Goblin'
    level: 1
    hp: 6
    attack: 3
    description: "Cretins with big ears and fangs. Strong and stupid."
    loot: [
      ['rock', 2]
      ['copper', 5]
      ['potion', 1]
      [0, 2]
    ]


# Game Actions
# -------------

generate_cards = ->
  # Populate the Mine
  mine.push(cards.rock) for i in [1..10]
  mine.push(cards.copper) for i in [1..15]
  mine.push(cards.goblin) for i in [1..50]
  mine.push(cards.silver) for i in [1..10]
  mine.push(cards.gold) for i in [1..7]
  mine.push(cards.diamond) for i in [1..5]
  mine.shuffle()

  # Populate the Shop
  shop.push(cards.pickaxe) for i in [1..10]
  shop.push(cards.potion) for i in [1..10]
  shop.push(cards.dagger) for i in [1..10]

  for player in players
    player.deck.push(cards.copper) for i in [1..5]
    player.deck.push(cards.dagger) for i in [1..2]
    player.deck.push(cards.pickaxe) for i in [1..3]
    player.deck.shuffle()
    player.deal()

next_turn = ->
  turn++
  turn = 0 if turn >= players.length

  if players[turn].dead
    next_turn()
  else
    msg "#{players[turn].name}: It's your turn!"
    list_hand(players[turn].name)

check_turn = (player,cb) ->
  if turn is players.indexOf(player) and started
    cb()

monster_attack = ->
  if monster.hp > 0
    player = players[turn]
    msg "the #{monster.card.name} attacks dealing #{monster.card.attack - player.defense} damage."
    player.hp -= monster.card.attack - player.defense


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
  else if started
    msg "The game's already started."

list_hand = (nick) ->
  if started
    player = players[player_nicks.indexOf(nick)]
    card_list = "" # TODO: shadowed variable

    for card in player.hand
      do (card) ->
        card_list = "#{card_list} [#{card.name}]"

    msg "#{nick}'s hand: " + card_list
    msg "#{nick}'s stats: " +
      "[Lv: #{player.stats.level}] " +
      "[HP: #{player.hp}] " +
      "[Attack: #{player.stats.attack}] " +
      "[Mines: #{player.stats.mine}] " +
      "[Money: #{player.stats.value}]"
  else
    msg "#{nick}, the game hasn't started yet."

use = (text, nick) ->
  player = players[player_nicks.indexOf(nick)]
  check_turn player, ->
    text = text.toLowerCase()
    for card in player.hand
      if card.name.toLowerCase() is text
        card.action player, ->
          player.discard card
        break

end_turn = (nick) ->
  player = players[player_nicks.indexOf(nick)]
  check_turn player, ->
    player.discard card for card in player.hand
    player.deck.shuffle()
    player.draw(5)
    next_turn()


card_info = (text) ->
  text = text.toLowerCase()
  for key, value of cards
    if cards[key].name.toLowerCase() is text
      card = cards[key]
      info_text = "#{card.name}: [\"#{card.description}\"] [type: #{card.type}]"
      for key, value of card
        if typeof value is 'number' and value isnt 0
          info_text += " [#{key}: #{value}]"
      msg info_text

help = ->
  msg "Available commands: "
  msg "!join: Join the game if it's not already in progress."
  msg "!start: Start the game."
  msg "!hand: View your current hand."
  msg "!info [card name]: View details of a particular card."
  msg "!use [card name]: Use a particular card in your hand."
  msg "!end: End your turn."

# Card Actions
# -------------

mine_card = (player) ->
  card = mine.pop()
  msg "You drew a #{card.name} from the Mine!"
  if card.type is 'gem'
    msg "Putting it in your deck."
    player.deck.push card
  else
    monster.card = card
    monster.hp = card.hp
    if Math.floor Math.random() * 2
      msg "Preemptive strike! You attack first"
    else
      msg "Back attack!"
      monster_attack()
    #   msg "You attack first, dealing #{player.stats.attack} damage."
    #   if player.stats.attack >= card.hp
    #     msg "The #{card.name} perishes."
    #   else
    #     msg "The #{card.name} counter-attacks for #{card.attack - player.stats.defense} damage."
    #     msg "Discarding."
    #     player.hp -= card.attack - player.stats.defense
    # else
    #   msg "The #{card.name} attacks first, dealing #{card.attack} damage."
    #   msg "Discarding."
    #   player.hp -= card.attack - player.stats.defense

attack = (player, dmg, discard) ->
  if monster.hp > 0
    msg "You attack the #{monster.card.name}, dealing #{dmg - monster.card.defense} damage."
    monster.hp -= dmg - monster.card.defense
    discard()
    if monster.hp < 1
      msg "The #{monster.card.name} perishes."
      drops = []
      odds = 0
      for card in monster.card.loot
        for i in [1..card[1]]
          drops.push card[0]
        odds += card[1]

      card_index = Math.floor Math.random() * (odds + 1)
      drop = drops[card_index]
      if drop
        drop = cards.find drop
        msg "The #{monster.card.name} dropped a #{drop.name}! Putting it in your deck."
        player.deck.push drop

      monster.hp = 0
      monster.card = {}
      #TODO: add exp and loot
    else
      monster_attack()
  else
    msg "There is no Monster on the table."




# IRC Config
# -------------

config =
  channels: ['##mine_games']
  server: 'irc.freenode.net'
  botName: 'MineGames'

bot = new irc.Client config.server, config.botName,
  channels: config.channels

msg = (text) ->
  bot.say config.channels[0], text

bot.addListener "message", (from, to, text, message) ->
  if /^[!](.*)$/.test text
    switch text.match(/^[!](\S*).*$/)[1]
      when 'join' then join(from)
      when 'start' then start()
      when 'hand' then list_hand(from)
      when 'mine' then mine_card(from)
      when 'info' then card_info(text.match(/^[!](\S*)\s?(.*)$/)[2])
      when 'use' then use(text.match(/^[!](\S*)\s?(.*)$/)[2], from)
      when 'end' then end_turn(from)
      when 'help' then help()
