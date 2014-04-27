display.setStatusBar( display.HiddenStatusBar )

system.activate( "multitouch" )

local physics = require("physics")
physics.start()

local score = require( "score" )

-- constants

local SWIMFORCE = 10
local SWIMMAXVEL = 600

local SIDEWAYSFORCE = 150
local SIDEWAYSMAXVEL = 200

local WALLHEIGHT = 100
local WALLWIDTH = 20

local MINSHINYACTIVETIME = 5000
local MAXSHINYACTIVETIME = 10000

local MINSHARKMOVE = 6000
local MAXSHARKMOVE = 8000

local MINSHARKWAIT = 0
local MAXSHARKWAIT = 0

local OXYGENDECAY = 0.002
local OXYGENSWIMPENALTY = 0.004

-- variables
local sidewaysMultiplier = 0
local swimMultiplier = 0
local shinies = 0
local bestShinies = 0
local oxygen = 1.0

-- score saving

function saveBest()
	local path = system.pathForFile( "best.txt", system.DocumentsDirectory )
   	local file = io.open(path, "w")
   	if ( file ) then
    	local contents = tostring( bestShinies )
    	file:write( contents )
      	io.close( file )
      	return true
	else
    	print( "Error: could not open best.txt." )
    	return false
	end	
end

-- score loading
local path = system.pathForFile( "best.txt", system.DocumentsDirectory )
local file = io.open( path, "r" )
if ( file ) then
	-- read all contents of file into a string
    local contents = file:read( "*a" )
    bestShinies = tonumber(contents);
    print(bestShinies)
    io.close( file )
else
	print( "Error: could not read scores from best.txt." )
end

-- audio
local shinySound = audio.loadSound( "shiny2.wav" )
local hitSound = audio.loadSound( "hit.wav" )
local noOxygenSound = audio.loadSound( "nooxygen.wav" )

-- boundaries
local topBoundary = display.newRect(display.contentCenterX, -5, display.contentWidth, 10 )
physics.addBody( topBoundary, "static", { friction=0.5, bounce=0.3 } )
local leftBoundary = display.newRect(-5, display.contentCenterY, 10, display.contentHeight*1.5 )
physics.addBody( leftBoundary, "static", { friction=0.5, bounce=0.3 } )
local rightBoundary = display.newRect(display.contentWidth+5, display.contentCenterY, 10, display.contentHeight*1.5 )
physics.addBody( rightBoundary, "static", { friction=0.5, bounce=0.3 } )

-- stage elements
local seabed = display.newRect(display.contentCenterX,display.contentHeight-100,display.contentWidth,300)
seabed:setFillColor(0.5)
physics.addBody( seabed, "static", { friction=0.5, bounce=0 } )

local water = display.newRect(display.contentCenterX,display.contentHeight-700,display.contentWidth,900)
water:setFillColor(0,0,1,0.5)

-- walls
local wall1 = display.newRect( display.contentCenterX-130, display.contentHeight-(250+WALLHEIGHT/2), WALLWIDTH, WALLHEIGHT )
wall1:setFillColor(0.5)
physics.addBody( wall1, "static", { friction=0.5, bounce=0 } )
local wall2 = display.newRect( display.contentCenterX+130, display.contentHeight-(250+WALLHEIGHT/2), WALLWIDTH, WALLHEIGHT )
wall2:setFillColor(0.5)
physics.addBody( wall2, "static", { friction=0.5, bounce=0 } )


---[[
local sky = display.newImage("sky.jpg")
sky.x = display.contentCenterX
sky.y = 65
sky.width = display.contentWidth
sky.height = 125
--]]

local pearl1 = display.newCircle( display.contentCenterX-245, display.contentHeight-305, 10 )
pearl1.active = true
physics.addBody( pearl1, "static", { isSensor=true } )
local pearl2 = display.newCircle( display.contentCenterX, display.contentHeight-305, 10 )
pearl2.active = true
physics.addBody( pearl2, "static", { isSensor=true } )
local pearl3 = display.newCircle( display.contentCenterX+245, display.contentHeight-305, 10 )
pearl3.active = true
physics.addBody( pearl3, "static", { isSensor=true } )

local swimmer = display.newRect(display.contentCenterX,25,50,50)
swimmer:setFillColor(1,1,0)
physics.addBody( swimmer, { density=2.0, friction=2.0, bounce=0.1 } )
swimmer.linearDamping = 1.5
--print("SWIMMER LINEAR DAMPING: "..swimmer.linearDamping)

-- SHARKS

local shark1 = display.newRect(-100, display.contentCenterY-350, 100, 50)
shark1:setFillColor(1,0,0,0.5)
shark1.direction = "right"
physics.addBody( shark1, "static", { isSensor=true } )
local shark2 = display.newRect(display.contentWidth+100, display.contentCenterY-150, 100, 50)
shark2:setFillColor(1,0,0,0.5)
shark2.direction = "left"
physics.addBody( shark2, "static", { isSensor=true } )
local shark3 = display.newRect(-100, display.contentCenterY+50, 100, 50)
shark3:setFillColor(1,0,0,0.5)
shark3.direction = "right"
physics.addBody( shark3, "static", { isSensor=true } )

local shark4 = display.newRect(display.contentWidth+100, display.contentCenterY-350, 100, 50)
shark4:setFillColor(1,0,0,0.5)
shark4.direction = "left"
physics.addBody( shark4, "static", { isSensor=true } )
local shark5 = display.newRect(-100, display.contentCenterY-150, 100, 50)
shark5:setFillColor(1,0,0,0.5)
shark5.direction = "right"
physics.addBody( shark5, "static", { isSensor=true } )
local shark6 = display.newRect(display.contentWidth+100, display.contentCenterY+50, 100, 50)
shark6:setFillColor(1,0,0,0.5)
shark6.direction = "left"
physics.addBody( shark6, "static", { isSensor=true } )

function onSharkStop( shark )

	-- update shark direction
	if(shark.direction == "right") then
		shark.direction = "left"
	else
		shark.direction = "right"
	end

	stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
	stm.params = { shark = shark }

end

function moveShark( event )
	local dirMultiplier = 1

	if(event.source.params.shark.direction == "left") then
		dirMultiplier = -1
	end

	transition.to( event.source.params.shark , { time=math.random(MINSHARKMOVE, MAXSHARKMOVE), x=dirMultiplier*(display.contentWidth+100), transition=easing.outQuad, onComplete=onSharkStop } )
end

stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark1 }
stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark2 }
stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark3 }
stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark4 }
stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark5 }
stm = timer.performWithDelay(math.random(MINSHARKWAIT, MAXSHARKWAIT), moveShark)
stm.params = { shark = shark6 }


-- UI
local oxygenBar = display.newRect( display.contentCenterX, 20, display.contentWidth, 40 )
local shiniesLbl = display.newText( "", display.contentWidth-100, 18, native.systemFont, 28 )
shiniesLbl:setFillColor(0.2)
local bestLbl = display.newText( "", 75, 18, native.systemFont, 28 )
bestLbl:setFillColor(0.2)

-- swim button
local swimBtn = display.newCircle( display.contentWidth-125, display.contentHeight-125, 50)

function swimBtnTap (event)
	if(event.phase == "began") then
		--swimmer:applyLinearImpulse( 0, -1 * SWIMFORCE, swimmer.x, swimmer.y )
		swimMultiplier = -1
	elseif(event.phase == "ended") then
		swimMultiplier = 0
	end
end

swimBtn:addEventListener( "touch", swimBtnTap )

-- left/right buttons
local leftBtn = display.newPolygon(100, display.contentHeight-125, { 0,100, 0,-100, -100,0} )
local rightBtn = display.newPolygon(250, display.contentHeight-125, { 0,100, 0,-100, 100,0} )

function leftMotion(event)
	if(event.phase == "began") then
		sidewaysMultiplier = -1
	elseif(event.phase == "ended") then
		sidewaysMultiplier = 0
	end
end

function rightMotion(event)
	if(event.phase == "began") then
		sidewaysMultiplier = 1
	elseif(event.phase == "ended") then
		sidewaysMultiplier = 0
	end
end

leftBtn:addEventListener( "touch", leftMotion )
rightBtn:addEventListener( "touch", rightMotion )

function reset()
	oxygen = 1.0
	shinies = 0
	swimmer.x, swimmer.y = display.contentCenterX,25
	oxygenBar:setFillColor(1)
end

-- motion handling
function swimmerMotion()
	-- normalize angular velocity and rotation
	swimmer.angularVelocity = 0
	swimmer.rotation = 0

	-- apply swim Force
	if(swimMultiplier ~= 0) then 
		--print("SWIM!")
		oxygen = oxygen - OXYGENSWIMPENALTY
	end
	swimmer:applyLinearImpulse( 0, swimMultiplier * SWIMFORCE, swimmer.x, swimmer.y )

	-- horizontal force
	--print("FORCE: ".. sidewaysMultiplier * SIDEWAYSFORCE )
	--print("ANGULAR VELOCITY: ".. swimmer.angularVelocity )
	swimmer:applyForce( sidewaysMultiplier * SIDEWAYSFORCE, 0, swimmer.x, swimmer.y )	
	--swimmer.x = swimmer.x + (sidewaysMultiplier * SIDEWAYSFORCE)

	-- velocity cap
	local vx,vy = swimmer:getLinearVelocity()
	if( vx < -SIDEWAYSMAXVEL ) then
		vx = -SIDEWAYSMAXVEL
	end
	if ( vx > SIDEWAYSMAXVEL ) then
		vx = SIDEWAYSMAXVEL
	end
	if( vy < -SWIMMAXVEL ) then
		vy = -SWIMMAXVEL
	end
	if ( vy > SWIMMAXVEL ) then
		vy = SWIMMAXVEL
	end	
	swimmer:setLinearVelocity(vx,vy)
	--print("VELOCITY X: "..vx.." VELOCITY Y:"..vy)

	-- boundaries
	--[[
	if(swimmer.x < 0) then
		swimmer.x = 0;
	end
	if(swimmer.x >= display.contentWidth) then
		swimmer.x = display.contentWidth;
	end
	--]]
end

Runtime:addEventListener("enterFrame", swimmerMotion)

function oxygenUpdate()
	if(swimmer.y > 125) then
		oxygen = oxygen - OXYGENDECAY
		if(oxygen<0) then
			audio.play(noOxygenSound)
			reset()
		end
	else
		oxygen = 1.0
		oxygenBar:setFillColor(1)
	end
end

Runtime:addEventListener("enterFrame", oxygenUpdate)

function uiUpdate()
	oxygenBar.width = display.contentWidth * oxygen
	oxygenBar.x = display.contentCenterX + (display.contentWidth - oxygenBar.width) / 2
	if(oxygen < 0.3) then
		oxygenBar:setFillColor(1,0,0)
	end
	shiniesLbl.text = "SHINIES "..shinies
	bestLbl.text = "BEST "..bestShinies
end

Runtime:addEventListener("enterFrame", uiUpdate)

function activateShiny( event )
	event.source.params.shiny.alpha = 1
	event.source.params.shiny.active = true
end

function onShinyCollision( self, event )

    if ( event.phase == "began" ) then
        --print( "SHINY COL!")

        if(self.active) then
        	audio.play(shinySound)
        	self.active = false
        	self.alpha = 0.15
        	shinies = shinies + 1
        	if(shinies > bestShinies) then
        		bestShinies = shinies
        		saveBest()
        	end
        	local tm = timer.performWithDelay( math.random(MINSHINYACTIVETIME, MAXSHINYACTIVETIME), activateShiny)
        	tm.params = { shiny = self }
        end
    end
end

function onSharkCollision( self, event )
	--print("SHARK COLLISION")
	if ( event.phase == "began" ) then
		audio.play(hitSound)
		timer.performWithDelay(10, reset)
	end
end

-- setup pearl collisions
pearl1.collision = onShinyCollision
pearl1:addEventListener( "collision", pearl1 )
pearl2.collision = onShinyCollision
pearl2:addEventListener( "collision", pearl2 )
pearl3.collision = onShinyCollision
pearl3:addEventListener( "collision", pearl3 )

-- setup shark collisions
shark1.collision = onSharkCollision
shark1:addEventListener( "collision", shark1 )
shark2.collision = onSharkCollision
shark2:addEventListener( "collision", shark2 )
shark3.collision = onSharkCollision
shark3:addEventListener( "collision", shark3 )
shark4.collision = onSharkCollision
shark4:addEventListener( "collision", shark4 )
shark5.collision = onSharkCollision
shark5:addEventListener( "collision", shark5 )
shark6.collision = onSharkCollision
shark6:addEventListener( "collision", shark6 )