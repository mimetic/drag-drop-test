--====================================================================--
-- drag-and-drop plugin
--
-- based on work by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--
--[[

A plugin for the Mimetic Books system.

Uses XML to layout drag-and-drop games.

Do different things based on drops.



--]]
--=========================================================


--=========================================================
-- Imports
--=========================================================
--require( 'scripts.dmc.dmc_kolor' )

local display = require( "scripts.dmc.dmc_kolor" )
--require ( 'scripts.patches.refPointConversions' )

local DragMgr = require ( "scripts.dmc.dmc_dragdrop" )
local Utils = require( "scripts.dmc.dmc_utils" )


-- object-oriented Drop Target implementation
local DropTarget = require ( "scripts.drag-and-drop.drop_target" )

local funx = require ("funx")

----------------------------------------------------------------------------------
local pathToModule = "scripts/drag-and-drop/"

----------------------------------------------------------------------------------
-- GAME ID, USED TO IDENTIFY THING RELATED TO THIS GAME
local gameID = "drag-and-drop"

--====================================================================--
-- Setup, Constants
--====================================================================--

local color_blue = { 25, 100, 255 }
local color_lightblue = { 90, 170, 255 }
local color_green = { 50, 255, 50 }
local color_lightgreen = { 170, 225, 170 }
local color_red = { 255, 50, 50 }
local color_red_trans = { 255, 50, 50, 100 }
local color_lightred = { 255, 120, 120 }
local color_grey = { 180, 180, 180 }
local color_lightgrey = { 200, 200, 200 }
local color_transparent = { 200, 200, 200, 0 }


-- What is the proper orientation for this book? We must draw it correctly.
-- If this is not a correct orientation, then obviously we reverse the height/width!
local screenW, screenH, viewableScreenW, viewableScreenH, screenOffsetW, screenOffsetH, midscreenX, midscreenY
local scalingRatio, bottom, top, tbHeight, contentAreaHeight

-------------------------------------------------
-- In case the screen changes, e.g. orientation change, this must called!
-------------------------------------------------
local function rebuildDisplaySettings()
	screenW, screenH = display.contentWidth, display.contentHeight
	viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight
	screenOffsetW, screenOffsetH = display.contentWidth -  display.viewableContentWidth, display.contentHeight - display.viewableContentHeight
	midscreenX = screenW*(0.5)
	midscreenY = screenH*(0.5)

end
rebuildDisplaySettings()



local G = {}

function G.new(params)

	local testing = false
	
	if (params.testing) then 
		testing = params.testing
	end
	if (testing) then
		print ("drag-and-drop plugin: Testing active.")
	end

	local board = display.newGroup()
	G.board = board

	-- So we can cancel them
	board.transitions = {}
	board.timers = {}

	-- This table holds the list of objects we have registered as drop targets.
	-- We must unregister them with DragDrop to clear them.
	board._dropTargets = {}

	--=========================================================
	-- FUNCTIONS
	--=========================================================

			local function cancelAllTransitions()
				for i = #board.transitions,1,-1 do
					transition.cancel(board.transitions[i])
					board.transitions[i] = nil
				end
				board.transitions = {}
			end

			local function cancelAllTimers()
				for i = #board.timers,1,-1 do
					timer.cancel(board.timers[i])
					board.timers[i] = nil
				end
				board.timers = {}
			end

			---------------------------------------------------------------------------------
			-- Destroy the game
			-- Remove objects AND handlers, e.g. the particle water handler!
			-- Note the board is also part of EcosystemGame, i.e. EcosystemGame.view
			local function _removeSelf(me)
--				board._cardviewer:destroy()
--				board._cardviewer = nil
--
--				board._awardsHUD:destroy()
--				board._awardsHUD = nil

				cancelAllTransitions()
				cancelAllTimers()

				for _,obj in pairs(board._dropTargets) do
					DragMgr:unregister(obj)
					obj = nil
				end
				board:removeSelf()
				board = nil

			end
			board._removeSelf = _removeSelf

			---------------------------------------------------------------------------------
			-- Get the system directory of the cards book
			-- We can't pass this from slideview because slideview doesn't have access
			-- to the shelves table. Instead, we'll simply search for it.
			local function getCardViewerSystemDirectory (cardBookID)
				local _, bookSysPath = funx.findFile( "book.xml", 
					{ 
						-- shelves in caches
						{ path = params.settings.app.bookLibraryDirName , bookDir = cardBookID,  systemDirectory = system.CachesDirectory },
						-- built in books in _user/books
						{ path = "_user/books", bookDir = cardBookID , systemDirectory = system.ResourceDirectory },
					})
				local cardBookSystemDirectory = funx.indexOfSystemDirectory(bookSysPath)
				return cardBookSystemDirectory
			end


			---------------------------------------------------------------------------------
			-- end local functions
			---------------------------------------------------------------------------------


			---------------------------------------------------------------------------------
			-- Open Page
			-- Do nothing.
			local function _openPage(me)
				--print ("Open Page")
			end
			board._openPage = _openPage




			---------------------------------------------------------------------------------
			-- Leave Page
			-- Do nothing.
			local function _leavePage(me)
				--print ("Leave Page")
			end
			board._leavePage = _leavePage


	--=========================================================
	-- Main
	--=========================================================

	params.pageValues = params.pageValues or {}

	--== Support Items ==--

	-- createSquare()
	--
	-- function to help create shapes, useful for drag/drop target examples
	--
	local function createSquare( size, color, borderColor )
		local borderColor = borderColor or color_transparent

		local s = display.newRect(0, 0, unpack( size ) )
		s.strokeWidth = 3
		s:setFillColor( unpack( color ) )
		s:setStrokeColor( unpack( borderColor ) )
		
		-- Invisible objects, e.g. alpha = 0, don't get hits unless this is true.
		s.isHitTestable = true
	
		return s
	end


	--==============================================================
	-- This plugin plays with existing pictures on the screen:
	--==============================================================

	local pictures = { _pictureIndex = {} }
	if (params.pageScreen.pictures) then
	 	pictures = params.pageScreen.pictures._pictureIndex
	end



	--==============================================================
	-- Setup DROP Targets - areas we drag TO
	--==============================================================
	
	for _,picture in pairs(pictures) do

		if (picture.values.droptarget) then

			--== Setup Drop Targets, using object-oriented code ==--
			-- For details, see the file 'drop_target.lua'

			-- the params.bookhandlers is the function we use in slideview.lua
			-- to handle button events (the updated version, anyway)
			local dropgroup = funx.split(picture.values.dropgroup)
			local id = picture.values.id
			local w,h = picture.values.width, picture.values.height
			local x,y = picture.values.x, picture.values.y
			
			local startColor = nil
			if (params.startColor and params.startColor ~= "") then
				startColor = funx.stringToColorTable(params.startColor)
			end
			
			local enterColor = nil
			if (params.enterColor and params.enterColor ~= "") then
				enterColor = funx.stringToColorTable(params.enterColor)
			end
			
			local borderColor = color_transparent
			if (testing) then
				borderColor = color_blue
			end

			local dropTarget = DropTarget.create( {
				format = dropgroup,
				color=color_transparent,
				borderColor = color_transparent,
				borderColor = borderColor,
				startColor = startColor,
				enterColor = enterColor,
				id = id,
				width=w,
				height=h,
				action=picture.values.action,
				params=picture.values.params,
				handler = params.bookhandlers,
				obj = picture.picture.picture,
				-- Move the dragItem box to the final location. 
				-- This is the obj the user touches to drag the obj.
				-- This means you drag something somewhere, and you could, in theory
				-- continue to drag it around if the data.singleUse = false
				-- in the dragItemTouchHandler. This value is set in the picture XML, e.g. "singleUse value="false""
				moveDragger = true,
			} )

			board:insert(dropTarget.view)
			funx.anchor(dropTarget, "TopLeft")
			--funx.anchor(dropTarget, "Center")
			dropTarget.x = x
			dropTarget.y = y

			DragMgr:register( dropTarget )

			table.insert( board._dropTargets, dropTarget )


		end


		--==============================================================
		-- Setup DRAG Targets - areas we drag FROM
		--==============================================================

		if (picture.values.draggable) then


			-- this is the drag target, the location from which we start a drag
			local w,h = picture.values.width, picture.values.height
			local x,y = picture.values.x, picture.values.y
			
			local dragW, dragH = picture.values.dragWidth or w, picture.values.dragHeight or h

			--== create Draggable Object ==--
			local dragItemColor = color_transparent
			if testing then
				dragItemColor = { math.random(0,255), math.random(0,255), math.random(0,255), 255 }
			end
			local dragItem = createSquare( { dragW, dragH }, color_transparent, dragItemColor )
			board:insert(dragItem)
			funx.anchor(dragItem, "Center")
			--funx.anchor(dragItem, "TopLeft")
			dragItem.x = x ; dragItem.y = y
			dragItem._id = picture.values.label
				
			-- Label
		
			if (picture.values.label) then
				local font = params.labelFont or native.systemFont
				local fontsize = params.labelFontSize or 12
				-- add 4 pixels to give a default margin
				local labelY = tonumber(params.labelY) or dragH/2 + 4
				local fontColor = funx.stringToColorTable(params.fontColor or "0,0,0")
				
				local t = display.newText(board, picture.values.label, 0, labelY, font, fontsize )
				t:setFillColor(unpack(fontColor))
				t.x = x
				t.y = y + labelY
			end
			
			-- values for dragging
			local data = funx.tableCopy(picture.values)
			data.dragItem = dragItem
			data.dragItem._myname = picture.values.label or picture.values.id

			local function dragItemTouchHandler( event )

				if event.phase == "began" then
					if (not event.target.noDrag) then
						local target = event.target
						local proxy
						

						proxy = funx.loadImageFile(picture.values.filename, params.bookpath, params.bookSourceDirectory)
						-- Scale to fit drag width
						proxy:scale(dragW/proxy.width, dragW/proxy.width)
						
						proxy._myname = picture.values.label

						-- local proxy = createSquare( { dragW, dragH }, color_lightred )
						-- setup info about the drag operation
						local drag_info = {
							proxy = proxy,
							format = picture.values.dropgroup,
							data = data,
							yOffset = 0,
							--startColor = {0,200,200,100},
							--enterColor = {0,250,0,100},
						}
						-- now tell the Drag Manager about it
						DragMgr:doDrag( target, event, drag_info )
					end
				end

				return true
			end

			dragItem:addEventListener( "touch", dragItemTouchHandler )
		end -- is draggable

	end



	--==============================================================
	-- The display object to return:
	return board

end

return G