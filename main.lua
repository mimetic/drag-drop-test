local funx = require ("funx")
local xml = require "xml"
local handler = require "handler"

-- =========================
-- Background
-- =========================
local bkgd = funx.loadImageFile("_user/images/_background.jpg")
bkgd.anchorX = 0
bkgd.anchorY = 0



-- =========================
-- Load XML
-- =========================
local filename = "pictures.xml"
local fullFilePath = system.pathForFile( filename, system.ResourceDirectory )

local h = handler.simpleTreeHandler()
local x = xml.xmlParser(h)
x.options.stripWS = true
x.options.expandEntities = true
x.options.tagLowercase = false
x:parseFile(fullFilePath)

--xmlTree = h.root
local picturesXML = h.root.pictures


-- =========================
-- Launch game
-- =========================
local gameFactory = require ("scripts.drag-and-drop.game_engine")

local pictures = {}
local pictureIndexByID = {}

for i,p in pairs( picturesXML.picture ) do
	p._attr.id = p._attr.id or "id-"..i
	local id = p._attr.id

	pictures[id] = { 
		values = {},
		}
	pictures[id].values = p._attr
	pictures[id].picture = {}
	pictures[id].picture.picture = funx.loadImageFile(p._attr.filename)
	pictures[id].picture.picture.x = p._attr.x
	pictures[id].picture.picture.y = p._attr.y
	funx.anchor(pictures[id].picture.picture, "Center")
	if (not p._attr.draggable) then
		-- jigger x,y to center, even if spec'd top-left in XML
		pictures[id].picture.picture.x = p._attr.x + pictures[id].picture.picture.width/2
		pictures[id].picture.picture.y = p._attr.y + pictures[id].picture.picture.height/2
		pictures[id].values.x = pictures[id].picture.picture.x
		pictures[id].values.y = pictures[id].picture.picture.y
	end
	pictureIndexByID[p._attr.id] = i

end


local params = {
	pageScreen = {
		pictures = {
			_pictureIndex = pictures,
		},
	},
}


-- =========================
-- Load Follow-up Function after Drop
-- { action, params, format, data, drop, target }
-- =========================
local dropObject = function(args)
	
	local action = args.action
	local params = args.params
	local data = args.data
	local drop = args.drop
	local target = args.target
	
	local followUpAction = nil

	if (params) then
		params = funx.trim(funx.split(params, ","))

		local id = data.id
		local pictureDef = pictures[id]
		local pictureOnScreen = pictureDef.picture.picture

		if (params[1] == "move") then
			-- Adjust for 'content' x,y positioning
			local x,y = pictureOnScreen:localToContent(0,0)

			transition.to(pictureOnScreen, { x= drop.x, y=drop.y, time=data.dropTime or 250, } )
		end

	end -- if params

	-- No followup action
	return nil
end



-- =========================
-- =========================

params.bookhandlers = dropObject
params.testing = true

local game = gameFactory.new( params )




-- =========================
-- =========================
