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
    @description = "Used at the shop to buy more cards."

class Weapon extends Card
  init: (options) ->
    @type = 'weapon'
    @attack = options.attack
    @cost = options.cost
    @description = "Can be used to attack Monsters or other Players."

class Armor extends Card
  init: (options) ->
    @type = 'armor'
    @defense = options.defense
    @cost = options.cost
    @description = "Used to defend against attacks."

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
    action: (nick) ->
      mine_card(nick)

  goblin: new Monster
    name: 'Goblin'
    level: 1
    hp: 6
    attack: 3
    description: "Cretins with big ears and fangs. Strong and stupid."

for key, value of cards
  exports[key] = value