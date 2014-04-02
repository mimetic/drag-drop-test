--====================================================================--
-- OO Drop Target
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--


-- =========================================================
-- Imports
-- =========================================================
local display = require( "scripts.dmc.dmc_kolor" )
--require( 'scripts.dmc.dmc_kolor' )

local Objects = require( "scripts.dmc.dmc_objects" )
local Utils = require( "scripts.dmc.dmc_utils" )
local DragMgr = require ( "scripts.dmc.dmc_dragdrop" )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

local funx = require ("funx")

--====================================================================--
-- Setup, Constants
--====================================================================--

local color_white = { 255,255,255 }
local color_blue = { 25, 100, 255 }
local color_lightblue = { 90, 170, 255 }
local color_green = { 50, 255, 50 }
local color_lightgreen = { 170, 225, 170 }
local color_red = { 255, 50, 50 }
local color_red_trans = { 255, 50, 50, 50 }
local color_lightred = { 255, 120, 120 }
local color_grey = { 180, 180, 180 }
local color_lightgrey = { 200, 200, 200 }
local color_transparent = { 200, 200, 200, 0 }



--== Support Items ==--

-- createSquare()
--
-- function to help create shapes, useful for drag/drop target examples
--
	local function createSquare( size, color, borderColor )
		borderColor = borderColor or color_transparent

		local s = display.newRect(0, 0, unpack( size ) )
		s.strokeWidth = 3
		s:setFillColor( unpack( color ) )
		s:setStrokeColor( unpack( borderColor ) )

		return s
	end




-- =========================================================
-- Drop Target Class
-- =========================================================

local DropTarget = inheritsFrom( CoronaBase )
DropTarget.NAME = "Drop Target"


-- _init()
--
-- initialize our object
-- base dmc_object override
--
function DropTarget:_init( options )

	self:superCall( "_init" )

	self.format = {}
	self.id = nil
	self.background = nil
	self.startColor = nil
	self.enterColor = nil
	
	self.obj = options.obj or nil
	
	self.startColor = options.startColor
	self.enterColor = options.enterColor


	-- Save the options
	self._options = options or {}

	if options.format then
		if type( options.format ) == "string" then
			self.format = { options.format }

		elseif type( options.format ) == "table" then
			self.format = options.format
		end
	end

	self._options.color  = ( options.color ) and options.color or color_lightgrey

end


-- _createView()
--
-- create our object's view
-- base dmc_object override
--
function DropTarget:_createView()

	local background = createSquare( { self._options.width, self._options.height }, self._options.color, self._options.borderColor )
	self:insert( background )
	funx.anchor(background, "Center")
	background.x = 0 ; background.y = 0

	self._background = background

end


-- _initComplete()
--
-- post init actions
-- base dmc_object override
--
function DropTarget:_initComplete()
	-- draw initial score
	--self:_updateScore()
end



-- define method handlers for each drag phase

function DropTarget:dragStart( e )

	local data_format = e.format
	if Utils.propertyIn( self.format, data_format ) then
		--self._background:setStrokeColor( 255, 0, 0 )
		if (self.obj and self._options.startColor) then
			self.obj:setFillColor( unpack( self._options.startColor ) )
		end
	end
	return true
end
function DropTarget:dragEnter( e )
	-- must accept drag here

	local data_format = e.format
	if Utils.propertyIn( self.format, data_format ) then
		if (self._options.enterColor) then
			self.obj:setFillColor( unpack( self._options.enterColor ) )
		end
		DragMgr:acceptDragDrop()
	end

	return true
end

-- Dragging over the target
function DropTarget:dragOver( e )
	return true
	end
	
function DropTarget:dragDrop( e )

	-- We got it, object cannot be dragged again?
	if (e.data.singleUse) then
		e.data.dragItem.noDrag = true
	end
	
	-- Move the dragger box to the dropped location?
	if (self._options.moveDragger) then
		funx.anchor(e.data.dragItem, "Center")
		e.data.dragItem.x = e.x
		e.data.dragItem.y = e.y
	end
	
	local options = self._options
	if options.action then
		local drop = {
			x = e.x,
			y = e.y,
		}
		options.handler ( { action = options.action, params = options.params, data = e.data, format = e.format, drop = drop } )
	end
	-- cleanup
	self:dragExit( e )

	return true
end
function DropTarget:dragExit( e )
	if (self._options.enterColor) then
		self.obj:setFillColor( unpack( self._options.startColor ) )
	end
	return true
end

-- Finished dragging, user stopped touching
function DropTarget:dragStop( e )
	return true
end


-- The Factory

local DropTargetFactory = {}

function DropTargetFactory.create( options )
	return DropTarget:new( options )
end


return DropTargetFactory




