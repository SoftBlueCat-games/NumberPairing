extends Node2D

#export var ROWS :int = 3
#export var  COLS :int = 3
var COLS :int = 10 #16 #18
var ROWS :int = 8 #8 #10
var BOARD_SIZE = Vector2(64 * COLS,64 * ROWS)
const SPACING :int = 2
const OFFSET_ITEM_LIST = 8
const MAX_LEVEL = 13

# associate a key to each cell (using its cell coordinates) and an ocupation value
onready var board_ :Dictionary = {} # the cells have an offset of two 64x64 cells in y axis and one 64x64 cell in x, 
									#this means that I should add 1 to ROWS and substract 1 from COLS when building the dictionary keys
onready var cells_ :Dictionary = {} # the keys are the cells and the values are the numbers placed in them
onready var numbers_ :Dictionary = {} # to keep track of how many times each number has been placed
onready var score_ :Dictionary = {} # keeps the player's name and number of occupied cells when game finished
onready var pairs_ :Dictionary = {} # the keys are the numbers from 1 to the selected level and the values are arrays where the numbers
# onready var complete_keys :Dictionary = {} # keeps the keys of the pairs_ dict that are complete
onready var complete_keys :Array = [] # keeps the keys of the pairs_ dict that are complete
									  # already paired are registered in the sequence they appear, preferably, without repetition

onready var cell_size :int = 64
onready var c :int = 0
onready var item_count :int = 0

onready var level :int = MAX_LEVEL
onready var selected_number = null  #:int = 1  # output of _number_options
onready var selected_item = null #:int  # output of _popup_mouse
onready var cursor_image = null

onready var _board = $Board # TileMap
onready var _number_options = $UserInterface/NumberOptions # OptionButton 
onready var _counter = $UserInterface/CounterContainer/Counter # Label 
onready var _item_list = $UserInterface/ItemsContainer/ItemList # ItemList 
onready var _popup_mouse = $PopupMouseControl/MenuButton/PopupMouse #PopupMenu 

var last_mouse_position
var switch_printed = false
var current_cursor = null
var array_numbers
var level_completed :bool = false

## idea to save the scores in a simplified way: get a screenshot this way (https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html?highlight=viewports)

func _ready():
	
	print("Defaults at ready before building:\n")
	print("level="+str(level))
	print("selected_number="+str(selected_number))
	print("selected_item="+str(selected_item))
	_number_options.connect("item_selected", self, "_on_NumberOptions_item_selected")
	print("On _ready when building:")
#	test[Vector2(0,0)] = 0
	print("numbers_ :"+str(numbers_))
	print("pairs_ : "+str(pairs_))
	_build_numbers_dict(level)
#	_build_Board_dict(ROWS,COLS)
	## PAIRED dict
	_build_pairs_dict(level)

	## NUMBERS dictionary
	### Node: ItemList
	#_build_ItemList()
	### Node: NumberOptions
	_build_NumberOptions(level)
	selected_number = level
	
	# var c :int = 0 already initialized as "onready"
	### Node: BOARD | tile indexes: White w. blue stroke: 0, White: 1, lighter gray: 2, light gray: 3, dark gray: 4, black: 5
	## Create board
	_build_Board(COLS,ROWS)
	# Connect to the board's input event to place the selected number on the board when the player clicks on a cell
	_board.connect("input_event", self, "_on_Board_input_event")
	
	## Build Counter
	_build_Counter()
	
	### using a for loop, we see it is perhaps not necessary to refer to the id's for our purposes in the first iteration of the game
#	var pm_limit = _on_NumberOptions_item_selected(9)
	_build_popup_mouse(level)
	# connect signal 
	_popup_mouse.connect("index_pressed", self, "_on_PopupMouse_item_pressed")
#	selected_item = 1
#	for j in range(pm_limit):
#		_popup_mouse.add_item(str(j+1),true)

	print("\nValues after building, at the end of _ready:")
	print("selected_number="+str(selected_number))
	print("selected_item="+str(selected_item))

############## ONREADY OBJECT BUILDER FUNCTIONS 

func _build_numbers_dict(n):
	for i in range(1,n+1):
		numbers_[i] = 0
	numbers_[0] = ROWS * COLS
	print(numbers_)
	
func _build_pairs_dict(n):
	for i in n:
		pairs_[i+1]  = []
		
func _build_NumberOptions(n):
	## Set the number of options in the _number_options node.
	# populate it with the numbers to choose using a for loop
	# CG: Connect the NumberOptions Button "item_selected" signal to the "_on_number_menu_item_selected" function
	# set the position
#	_number_options.rect_global_position = Vector2(OFFSET_ITEM_LIST, OFFSET_ITEM_LIST)
	_number_options.rect_position = Vector2(OFFSET_ITEM_LIST *4, OFFSET_ITEM_LIST *4)
	for i in n:
		_number_options.add_item(str(i+1))
	selected_number = n
	print("selected_number_on_build_Number_options="+str(n))
	_number_options.text = str(n)

func _build_Counter():
	# set container's position
	var cont = $UserInterface/CounterContainer
	#cont.set_position(Vector2(1280/3+32, 32)) # this is the centered configuration
	cont.set_position(Vector2(1280/3-256-64, 32))
	# set text and change counter's text color
	_counter.text = "Zahlen benutzt:  " + str(item_count)
#	_counter.add_font_override("font")
	_counter.add_color_override("font_color", Color(0,1,1,1)) # (0,1,1,1) ~cyan //  (0,0,1,1) = blue // (0,0,0,1)
	# change scale
#	_counter.anchor_right = 1
	_counter.rect_scale = Vector2(2,2)

func _build_Board(COLS,ROWS): # we can also use this loop to build the dict
	$Board.remove_child($Board)
	for x in COLS:
		if (COLS %2 ) != (ROWS %2):
			c += 1 # neccesary if the dimensions have different parity. Otherwise stripes are obtained instead of checkerboard
		for y in ROWS:
			if (c % 2 == 0): 
				$Board.set_cellv(Vector2(x, y), 0)
				board_[Vector2(x,y)] = 0
				c +=1
			else:
				$Board.set_cellv(Vector2(x, y), 0)
				board_[Vector2(x,y)] = 0
				c +=1	
	print(board_)

func _build_popup_mouse(limit):
	for j in limit:
		_popup_mouse.add_item(str(j+1), true)
		#_popup_mouse.add_item(str(j+1), 0) # or 1?
		
	# Set the size of the PopupMouse to fit the new number of items
	_popup_mouse.set_size(Vector2(_popup_mouse.rect_size.x, _popup_mouse.get_item_count() * SPACING * 2 ))
#	selected_item = null
	
	print("selected_item in PopupMouse build = "+str(selected_item))	

############## SIGNALS

#func _on_NumberOptions_item_focused(index):
#	pass # Replace with function body.
		
func _on_NumberOptions_item_selected(index): 
	### most recent attempt: 
	# get the selected number from the OptionButton
	selected_number = int(_number_options.get_item_text(index))
	# Clear the PopupMenu
	_popup_mouse.clear()
	# Add numbers to the PopupMenu based on the number selected previously

	_build_popup_mouse(int(selected_number))

	# if selected_number is smaller than the number of items in the PopupMenu, set the PopupMenu cursor to the selected number
	if selected_number <= _popup_mouse.get_item_count():
		update_PopupMouse_cursor(int(selected_number))
	
func _on_PopupMouse_item_pressed(id):
	# Get the selected number from the PopupMenu
	selected_item = int(_popup_mouse.get_item_text(id))
	print(selected_item)
	# Set the PopupMouse cursor according to selection
	update_PopupMouse_cursor(int(selected_item))

	# Connect to the board's input event to place the selected number on the board when the player clicks on a cell
	_board.connect("input_event", self, "_on_Board_input_event", [selected_item])

############################## input events
############### INPUT

func _input(event): 
	# show PopupMouse every time right mouse button is clicked, at the specific location where the click happened.
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		last_mouse_position = get_global_mouse_position()
		_popup_mouse.popup( Rect2(last_mouse_position.x, last_mouse_position.y, _popup_mouse.rect_size.x, _popup_mouse.rect_size.y) )
	# Set the PopupMouse cursor according to selection (selected_item)
	if event is InputEventMouseMotion and current_cursor != null:
		# Set the custom mouse cursor position to follow the mouse pointer
		Input.set_custom_mouse_cursor(current_cursor, Input.CURSOR_ARROW, Vector2(SPACING,SPACING)) # last entry defines de location of the "hotspot"
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		 # Clear the custom mouse cursor when the right mousr button is clicked
		Input.set_custom_mouse_cursor(null)
		selected_item = null
		update_PopupMouse_cursor(selected_item)

############## PROCESS

# idle processing:
func _process(delta):
	# check what is the current selected_item. 
	# If the mouse left button is pressed on a cell on the board, 
	# then that cell's tile on the board should 
	# be set to the tile having an index equal to selected_item
	# get the selected item from the PopupMouse  
	var cell = _board.world_to_map(get_global_mouse_position())
	cell.x -= 1 # this is needed because of the offset in the definition of the cells and their coordinates
	cell.y -= 1
	var seq_
	# get the cell under the mouse pointer and print it to console
	# check if the cell is within the bounds of the grid
	if(Input.is_action_just_pressed("leftmb") and selected_item != null):
		if cell in board_:
			print("\ncurrent CURSOR position: " + str(cell))
			# check if the cell is empty
			if board_[cell] == 0:
					# set the cell's tile to the tile in the tilemap whose index correspond to 'selected_item' if the left mouse button is pressed
					_board.set_cellv(cell, selected_item)
					# update the board_ dictionary to indicate the cell is occupied
					board_[cell] = selected_item
					# update the numbers_dictionary after placing the number in the board
					numbers_[selected_item] += 1 # the number placed gains 1
					numbers_[0] -= 1 # the zero count looses 1

					#### NEW UPDATE BLOCK: using the update_pairs function only
					# update the pairs_ dict
					pairs_ = update_pairs()


					#### BEGIN OLD UPDATE BLOCK
					# we need to update the dictionaries after this event
					# check_update_board_pairs()
					# paired(cell)
					# update_all_pairs_board()
					
					# in a new dictionary called nstate, keep only those key-value pairs in numbers_ whose value is greater than zero
					# so we can display this dictionary in _counter
					# var nstate = {}
					# for key in pairs_:
					# 	if pairs_[key] != []:
					# 		nstate[key] = pairs_[key]
					# #for key in numbers_:
					# #	if numbers_[key] != 0:
					# #		nstate[key] = numbers_[key]
					# var keycount = 0
					# for key in nstate:
					# 	if len(nstate[key]) >= selected_number-1: # if this condition is true, increase keycount by 1
					# 		keycount += 1
					
					# if keycount >= selected_number-1: # if this condition is true, then the level is complete
					# 	level_completed = true
					# 	# update the item counter label 
					# 	_counter.text = "FERTIG! Zahlen benutzt: " + str(item_count) + " Liste:"  + " " + str(nstate)
					# else:
					# # update the item counter label
					# 	_counter.text = "Zahlen benutzt: "+ str(item_count) + " Liste:"  + " " + str(nstate)
					##### end of OLD UPDATE BLOCK

					# print 
					print("\n ====== current state of the game ======:\n")
					print("numbers dictionary" + str(numbers_) + '\n') 
					#print(board_)
					#print("pairs: "+str(pairs_))  ## Solution will be more complicated, via the neighbors function
					print("updated pairs: "+str(pairs_) + '\n')
			else: # if the cell is not empty, then print a message to the console
					print("cell"+str(cell)+"occupied by"+str(selected_item))


		# check if the level is completed
		complete_keys = check_game_status_()
		# complete_keys, level_completed = check_game_status_()
		# print the complete keys
		print("complete keys, printed in event loop: " + str(complete_keys))
		if level_completed:
			var completed_level_messageEN = Label.new()
			var completed_level_messageDE = Label.new()
			completed_level_messageEN.text = "You have completed the level!\n all the numbers are paired"
			completed_level_messageDE.text = "Du hast das Level abgeschlossen!\n Alle Nummern sind gepaart."
			completed_level_messageEN.rect_position = Vector2(1280/2+64, 8)
			completed_level_messageDE.rect_position = Vector2(1280/3-64, 8)
			add_child(completed_level_messageEN)
			add_child(completed_level_messageDE)
			
	elif(Input.is_action_just_pressed("leftmb") and selected_item == null): # if the selected_item is null, then do nothing when the player clicks on the board
		pass
				
	elif(Input.is_action_just_pressed("centermb") and selected_item != null):
		# item_count -= 1
		if cell in board_ and cell != null and board_[cell] != 0:
			# set cell to the empyt one, with tile index 0
			_board.set_cellv(cell, 0)
			# update numbers_ dict before reseting the value of the cell to zero
			numbers_[board_[cell]] -= 1
			board_[cell] = 0
			# board_[cell] = 0
			numbers_[0] += 1
			pairs_ = update_pairs()
			# check game status
			complete_keys = check_game_status_()

			### BEGIN OLD UPDATE BLOCK
			# in a new dictionary called nstate, keep only those key-value pairs in numbers_ whose value is greater than zero
			# so we can display this dictionary in _counter
			# var nstate = {}
			# for key in pairs_:
			# 	if pairs_[key] != []:
			# 		nstate[key] = pairs_[key]
					
			# var keycount = 0
			# for key in nstate:
			# 	if len(nstate[key]) <= selected_number-1: # if this condition is true, decrease keycount by 1
			# 		keycount -= 1
			# # upadte the item counter
			# # item_count -= 1
			# # update the item counter label
			# # _counter.text = "Zahlen benutzt: "+ str(item_count) + " Liste:"  + " " + str(nstate)
			# # update the item count and counter label
			# if item_count > 0:
			# 	item_count -= 1
			# 	_counter.text = "Zahlen benutzt: "+ str(item_count) + " Liste:"  + " " + str(nstate)
			# elif item_count == 0:
			# 	item_count = 0
			# update the pairs_ dict
			##### end of OLD UPDATE BLOCK
			
			# check_update_board_pairs()
		# elif cell in board_ and cell == null: # 
		# 	_board.set_cellv(cell, 0)
		# 	#paired(cell)
		# 	#update_all_pairs_board()
		# 	item_count -= 1

	elif(Input.is_action_just_pressed("centermb") and selected_item == null):
		pass

#########################
###### UPDATER FUNCTIONS

## update full board
func update_all_pairs_board():
	_build_pairs_dict(selected_number) 
	for cell in board_:
		if board_[cell] != 0:
			paired(cell)
			# update the board_ dict
			board_[cell] = _board.get_cellv(cell)
			# update the pairs_ dict
			paired(cell)
	return pairs_

## game completed (alternative)
func check_game_status_():
	# take the pairs_ dict and check for each key, if the list in the values contains the key itself.
	# if so, remove it from the list
	# complete_keys = {} # we need to initialize this array here so we are always aware of the true number of complete keys
	# # fill the complete_keys dictionary with the numbers from 1 to the selected level as keys and 0 as values
	# for i in range(selected_number): #
	# 	complete_keys[i+1] = 0
	complete_keys = []
	# print the complete keys 
	print("complete keys: "+str(complete_keys))
	for key in pairs_:
		var vals = pairs_[key]
		# remove the key itself it it is contained in the array of values
		if vals.has(key):
			vals.erase(key)
		# remove 0 if it is contained in the array of values
		if vals.has(0):
			vals.erase(0)
		# now we want to check that for the current key, the numbers contained in the array are the numbers from 1 to the selected level, without repetition, excluding the key itself
		# first we need to check that the size of the array is equal to the selected level:
		if vals.size() == selected_number-1:
			# make a list with tne numbers from 1 to selected_number:
			var seq = []
			for i in range(selected_number):
				seq.append(i+1)
			# remove the current key from the list
			seq.erase(key)
			# compare seq with vals, if they are equal, then that key is complete and we can update the complete_keys (array or dict, check its declaration at the beginning of the script)
			if seq == vals:
				# complete_keys[key] = 1 # if complete_keys is a dictionary
				complete_keys.append(key) # if complete_keys is an array
	# check if the length of the array is equal to the selected level-1
	if len(complete_keys) == selected_number-1:
		print("You have completed the level!")
		level_completed = true
		# update the item counter label 
		_counter.text = "FERTIG! Zahlen benutzt: " + str(item_count) + " Liste:"  + " " + str(pairs_)
	else:
		# update the item counter label
		_counter.text = "Zahlen benutzt: "+ str(item_count) + " Liste:"  + " " + str(pairs_)
	return complete_keys#, level_completed


func update_pairs():# build the current dictionary pairs_ in the board. 
	# This function runs after an action is taken and completed in the game, right before updating the score and the counter
	# the keys are the numbers from 1 to the selected level and the values are arrays where the numbers 
	# already paired are registered mwithout repetition and without the key itself
	# the function should be called after each action in the game, so it is updated
	# first we rebuild the pairs_ dict 
	var pairs_new = {}
	print("updated pairs (rebuilt): ", pairs_new)
	# now we get the keys in numbers_ whose values are greater than zero to be used as keys in pairs_new
	for key in numbers_: 
		# if the value of the key is greater than zero, and the key is not zero, then we add it to pairs_new with an empty array as value
		if numbers_[key] > 0 and int(key) != 0:
			pairs_new[key] = []
		# now we fill the values of pairs_new with the numbers paired to the key, excluding the key itself
		# to this end, we need to iterate over the board_ dict and check if the value of the cell is equal to the key
		# if it is, then we need to check the neighbors of the cell and append them to the value of the key in pairs_new
		# if the value of the cell is not equal to the key, then we do nothing
		for cell in board_:
			if board_[cell] == key and int(key) != 0: # board_[cell] returns the value of the cell in the board
				# get the neighbors of the cell
				#var neigh = neighbors_(cell) # neighbors_ returns an array of the neighbors of the cell
				# append the neighbors to the value of the key in pairs_new
				#for i in unique(neigh): # unique returns an array with unique elements
				for i in unique(neighbors_(cell)):
					pairs_new[key].append(i) # we append only the unique elements
				# remove the key itself it it is contained in the array of values
				if pairs_new[key].has(key): # has returns true if the array contains the element
					pairs_new[key].erase(key) # erase removes the element from the array
				# remove 0 if it is contained in the array of values
				if pairs_new[key].has(0):
					pairs_new[key].erase(0)
				# make sure to remove duplicates
				pairs_new[key] = unique(pairs_new[key])

	# now we need to replace the old pairs_ dict with the new one pairs_new
	pairs_ = pairs_new
	return pairs_

#func get_game_status(): #
#	pass


func unique(array):
	var unique_array = []
	for i in array:
		if !unique_array.has(i) and i != 0:
			unique_array.append(i)
	return unique_array

func neighbors_(cell):
	var cols = COLS-1
	var rows = ROWS-1
	# declare the neighbor variables
	print("cell input of neighbors: ")
	print(cell)
	var up_  = 0
	var right_ = 0
	var down_  = 0 
	var left_ = 0
	# get cell's coordinates
	var x = cell.x
	var y = cell.y
	var neigh :Array = []
	# avoid the boundary
	if x != null or y!= null: 
		if x == 0 and y == 0:
			up_ = 0
			right_ = board_[Vector2(x+1, y)]
			down_ = board_[Vector2(x, y+1)]
			left_ = 0
		elif x == 0 and y == rows:
			up_ = board_[Vector2(x, y-1)]
			right_ = board_[Vector2(x+1, y)]
			down_ = 0
			left_ = 0
		elif x == cols and y == 0:
			up_ = 0
			right_ = 0
			down_ = board_[Vector2(x, y+1)]
			left_ = board_[Vector2(x-1,y)]
		elif x == cols and y == rows:
			up_ = board_[Vector2(x, y-1)]
			right_ = 0
			down_ = 0
			left_ = board_[Vector2(x-1,y)]
		elif ( x == 0 and y < rows and y > 0 ):
			up_ = board_[Vector2(x, y-1)]
			right_ = board_[Vector2(x+1, y)]
			down_ = board_[Vector2(x, y+1)]
			left_ = 0
		elif x == cols and y > 0 and y < rows:
			up_ = board_[Vector2(x, y-1)]
			right_ = 0
			down_ = board_[Vector2(x, y+1)]
			left_ = board_[Vector2(x-1,y)]
		elif y == 0 and x > 0 and x < cols:
			up_ = 0
			right_ = board_[Vector2(x+1, y)]
			down_ = board_[Vector2(x, y+1)]
			left_ = board_[Vector2(x-1,y)]
		elif y == rows and x > 0 and x < cols:
			up_ = board_[Vector2(x, y-1)]
			right_ = board_[Vector2(x+1, y)]
			down_ = 0
			left_ = board_[Vector2(x-1,y)]
		else:
			up_ = board_[Vector2(x, y-1)]
			right_ = board_[Vector2(x+1, y)]
			down_ = board_[Vector2(x, y+1)]
			left_ = board_[Vector2(x-1,y)]

#	var center = _board[cell]
	neigh = [up_,right_,down_,left_] 
	
	return neigh

# iterates over pairs_ dict and checks one by one if the value _board[cell] corresponds

func paired(cell):  # fix this function to incorporate reflexivity (symmetry, check whiteboard) of invoke a new function to do it 
	# rebuild the pairs_ dict
	var ngb :Array 
	ngb = neighbors_(cell)
	var ungb = unique(ngb) #unique neighbors
	# first append elementwise and then re-filter with unique
	for i in ungb:
		pairs_[board_[cell]].append(i)
	# update with unique 
	pairs_[board_[cell]] = unique(pairs_[board_[cell]])
	return pairs_

#### Ckeck and update board
func check_update_board_pairs(pairs_):
	# save the old pairs_ dict, to merge it at the end with the one updated here
	var old_pairs_ = pairs_.duplicate(true)
	var new_pairs_ = {} # pairs_.duplicate(true)
	# declare some local variables 
	var nbrs
	var site_val
	# start update
	for site in board_:
		site_val = board_[site]
		if site_val != 0:
			nbrs = neighbors_(site)
			new_pairs_[site_val] = nbrs
	# merge old and new information on pairing. The method merge is not working
	# so we will have to append both dictionaries together and then find the unique elements
	# let us do it by looping
	_build_pairs_dict(selected_number)
	for key in old_pairs_:
		var vals_ = old_pairs_[key]
		for i in vals_:
			new_pairs_[key].append(i)
			pairs_[key] = unique(new_pairs_[key])
	
	return pairs_


func update_PopupMouse_cursor(item_selected):
	
	if item_selected != null and selected_number >= item_selected:
		# Set the custom mouse cursor
		cursor_image = ResourceLoader.load("res://cursor/"+str(item_selected)+".png")
#		cursor_image.set("scale",0.5) # does not work
#		cursor_image.scale(0.5) # Invalid call. Nonexistent function 'scale' in base 'StreamTexture'
#		var cursor_color = Color(1, 1, 1, 0.6)
		Input.set_custom_mouse_cursor(cursor_image, Input.CURSOR_ARROW)
		
		current_cursor = cursor_image
#	elif item_selected != null and 
	else:
		current_cursor = null
		cursor_image = null


#func paired_neigh(cell):
#	var cols = COLS-1
#	var rows = ROWS-1
#	# get cell's coordinates
#	var x = cell.x
#	var y = cell.y
#	# declare the neighbor variables
#	print("cell input of neighbors: ")
#	print(cell)
#	var up_  = 0
#	var right_ = 0
#	var down_  = 0
#	var left_ = 0
#	# neighbor cells
#	var cell_up = null
#	var cell_right = null
#	var cell_down = null
#	var cell_left = null
#	var neigh :Array = []
#	##
#	var nei_up = [] # paired(unique(neighbors_(cell_up)))
#	var nei_right = [] #paired(unique(neighbors_(cell_right)))
#	var nei_down = [] #paired(unique(neighbors_(cell_down)))
#	var nei_left = [] #paired(unique(neighbors_(cell_left)))
#	nei_up = paired(unique(neighbors_(cell_up)))
#	nei_right = paired(unique(neighbors_(cell_right)))
#	nei_down = paired(unique(neighbors_(cell_down)))
#	nei_left = paired(unique(neighbors_(cell_left)))
#	### getting neighboring cells (board_ keys) and values
#	# the rest will output to null 
#	if x == 0 and y == 0: 
#		cell_right = Vector2(x+1, y)
#		cell_down = Vector2(x, y+1)
#		right_ = board_[Vector2(x+1, y)] 
#		down_ = board_[Vector2(x, y+1)]
#
##		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
#		pairs_[down_] = paired(unique(neighbors_(cell_down)))
##		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif x == 0 and y == rows:
#		cell_up = Vector2(x, y-1)
#		cell_right = Vector2(x+1, y)
#		up_ = board_[Vector2(x, y-1)]
#		right_ = board_[Vector2(x+1, y)]
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
##		pairs_[down_] = paired(unique(neighbors_(cell_down)))
##		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif x == cols and y == 0:
#		cell_down = Vector2(x, y+1)
#		cell_left = Vector2(x-1, y)
#		down_ = board_[Vector2(x, y+1)]
#		left_ = board_[Vector2(x-1,y)]
##		pairs_[up_] = paired(unique(neighbors_(cell_up)))
##		pairs_[right_] = paired(unique(neighbors_(cell_right)))
#		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif x == cols and y == rows:
#		cell_up = Vector2(x, y-1)
#		cell_left = Vector2(x-1, y)
#		up_ = board_[Vector2(x, y-1)]
#		left_ = board_[Vector2(x-1,y)]
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
##		pairs_[right_] = paired(unique(neighbors_(cell_right)))
##		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif ( x == 0 and y < rows and y > 0 ):
#		cell_up = Vector2(x, y-1)
#		cell_right = Vector2(x+1, y)
#		cell_down = Vector2(x, y+1)
#		up_ = board_[Vector2(x, y-1)]
#		right_ = board_[Vector2(x+1, y)]
#		down_ = board_[Vector2(x, y+1)]
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
##		pairs_[down_] = paired(unique(neighbors_(cell_down)))
##		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif x == cols and y > 0 and y < rows:
#		cell_up = Vector2(x, y-1)
#		cell_down = Vector2(x, y+1)
#		cell_left = Vector2(x-1,y)
#		up_ = board_[Vector2(x, y-1)]
#		down_ = board_[Vector2(x, y+1)]
#		left_ = board_[Vector2(x-1,y)]
#
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
##		pairs_[right_] = paired(unique(neighbors_(cell_right)))
#		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif y == 0 and x > 0 and x < cols:
#		cell_right = Vector2(x+1, y)
#		cell_down = Vector2(x, y+1)
#		cell_left = Vector2(x-1,y)
#		right_ = board_[Vector2(x+1, y)]
#		down_ = board_[Vector2(x, y+1)]
#		left_ = board_[Vector2(x-1,y)]
##		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
#		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_] = paired(unique(neighbors_(cell_left)))
#	elif y == rows and x > 0 and x < cols:
#		cell_up = Vector2(x, y-1)
#		cell_right = Vector2(x+1, y)
#		cell_left = Vector2(x-1,y)
#		up_ = board_[Vector2(x, y-1)]
#		right_ = board_[Vector2(x+1, y)]
#		left_ = board_[Vector2(x-1,y)]
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
##		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_]  = paired(unique(neighbors_(cell_left)))
#	else:
#		cell_up = Vector2(x, y-1)
#		cell_right = Vector2(x+1, y)
#		cell_down = Vector2(x, y+1)
#		cell_left = Vector2(x-1,y)
#		up_ = board_[Vector2(x, y-1)]
#		right_ = board_[Vector2(x+1, y)]
#		down_ = board_[Vector2(x, y+1)]
#		left_ = board_[Vector2(x-1,y)]
#		pairs_[up_] = paired(unique(neighbors_(cell_up)))
#		pairs_[right_] = paired(unique(neighbors_(cell_right)))
#		pairs_[down_] = paired(unique(neighbors_(cell_down)))
#		pairs_[left_] = paired(unique(neighbors_(cell_left)))
	# update in dictionary

		
	
	
	
#	var center = _board[cell]
#	var cell_neigh = [cell_up, cell_right, cell_down, cell_left]
	
#	return neigh


	

