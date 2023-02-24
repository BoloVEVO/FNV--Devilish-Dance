startSwing = false;
startRotating = false;
swingVal = 0;
reset = false;
function start(song)
    setProperty('PlayStateChangeables','middleScroll',true);
    
end

function postStart(song)

end

function update(elapsed)

    currentBeat = (songPos / 1000)*(bpm/60);

    for i = 0,3 do 
        local PlayerReceptor = _G['Player_receptor_'..i];

        if startSwing then 
            if swingVal < 6 then
                swingVal = swingVal + 0.025
            end
            PlayerReceptor.laneFollowsReceptor = 0;
            PlayerReceptor.x = (PlayerReceptor.defaultX + swingVal * math.sin(((currentBeat/4) + i*0.25) * math.pi))+swingVal*math.sin(currentBeat)
            
       
        end

        if startRotating then 
            PlayerReceptor.angle = PlayerReceptor.angle + elapsed*6;
        end
    end



    notes = getNotes();
    for i,v in ipairs(getNotes()) do
       local note = _G[v];

       if not note.isSustain then
            note.followAngle = 1;
       end
    end
end

local function strumSplit()
    for i = 0,1 do 
        local rec = _G['Player_receptor_'..i];
        rec.laneFollowsReceptor = 1;
        rec:tweenPos(rec.defaultX-300,rec.y,3,'expoout');
        rec:tweenAngle(rec.angle-360,3,'expoout');
    end

    for k = 2,3 do 
        local TwiceReceptors = _G['Player_receptor_'..k];
        TwiceReceptors.laneFollowsReceptor = 1;
        TwiceReceptors:tweenPos(TwiceReceptors.defaultX+300,TwiceReceptors.y,3,'expoout');
        TwiceReceptors:tweenAngle(TwiceReceptors.angle+360,3,'expoout');
   end
end 

local function spin()
    for i = 0,3 do 
        local CoolReceptor = _G['Player_receptor_'..i];
        CoolReceptor:tweenAngle(CoolReceptor.angle+360,0.35,'smoothstepout');
    end
end

local function resetStrumPos()
    if not reset then
        for i = 0,3 do 
            local CoolReceptor = _G['Player_receptor_'..i];
            CoolReceptor:tweenPos(CoolReceptor.defaultX,CoolReceptor.y,0.25,'smoothstepout');
            CoolReceptor:tweenAngle(CoolReceptor.defaultAngle,0.5,'smoothstepout');
        end
        reset = true
    end
end 

function beatHit(beat)


    if beat == 296 then
        startSwing = true;
        startRotating = true;
    end
    
    if beat == 360 then
        startSwing = false;
        startRotating = false;
        resetStrumPos();
    end

    if beat == 328 then 
        startRotating = false;
        spin()
    end

    if beat == 330 then 
        spin()
    end

    if beat == 332 then 
        startRotating = true;
    end

    if beat == 480 then
        strumSplit()
    end
end