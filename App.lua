local _,Library = ...;
local jMap = LibStub( 'AceAddon-3.0' ):NewAddon( 'jMap','AceEvent-3.0','AceHook-3.0','AceConsole-3.0' );
local WorldMapUnitPin;
for Pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
    WorldMapUnitPin = Pin;
    break;
end 
if( not WorldMapFrame or not WorldMapUnitPin ) then
    return;
end

function jMap:SetValue( Index,Value )
    return self:SetDBValue( Index,Value );
end

function jMap:GetValue( Index )
    return self:GetDBValue( Index );
end

function jMap:WorldMapFrameSynchronizeDisplayState()
    -- Map Position
    self:WorldMapFrameSetPosition();

    -- Map Scale
    self:WorldMapFrameSetScale();
end

function jMap:WorldMapFrameSynchronizeSizes()
    if( WorldMapUnitPin:IsForbidden() ) then
        return;
    end
    if( jMap:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'WorldMapFrameSynchronizeSizes' );
    end
    local PlayerWidth,PlayerHeight = 64,64;
    local PingWidth,PingHeight = 75,75;
    if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
        WorldMapUnitPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
    end
    if( WorldMapUnitPin.SetPlayerPingScale ) then
        WorldMapUnitPin:SetPlayerPingScale( jMap:GetValue( 'PinAnimScale' )/WorldMapFrame:GetCanvasScale() );
    end
    if( WorldMapUnitPin.SetPinSize ) then
        WorldMapUnitPin:SetPinSize( PlayerWidth,PlayerHeight );
    end
end

function jMap:WorldMapFrameUpdatePin()
    if( WorldMapUnitPin:IsForbidden() ) then
        return;
    end
    if( jMap:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'WorldMapFrameUpdatePin' );
    end
    if( WorldMapUnitPin.SetPinTexture ) then
        local SkullPins = {
            Pink = 'Interface\\WorldMap\\Glowskull_64purple',
            Blue = 'Interface\\WorldMap\\Glowskull_64blue',
            Yellow = 'Interface\\WorldMap\\Glowskull_64',
            Green = 'Interface\\WorldMap\\Glowskull_64green',
            Grey = 'Interface\\WorldMap\\Glowskull_64grey',
            Red = 'Interface\\WorldMap\\Glowskull_64red',
            Normal = 'Interface\\WorldMap\\WorldMapArrow',
        }
        WorldMapUnitPin:SetPinTexture( 'player',SkullPins[ jMap:GetValue( 'PinColor' ) ] );
        WorldMapUnitPin:SetFrameLevel( 5000 );
    end
end

function jMap:UpdatePartyPins()
    if( WorldMapUnitPin:IsForbidden() ) then
        return;
    end
    if( self:GetValue( 'ClassColors' ) ) then
        WorldMapUnitPin:SetUseClassColor( 'party',true );
        WorldMapUnitPin:SetUseClassColor( 'raid',true );
    else
        WorldMapUnitPin:SetUseClassColor( 'party',false );
        WorldMapUnitPin:SetUseClassColor( 'raid',false );
    end
end

function jMap:WorldMapFramePing()
    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'WorldMapFramePing' );
    end
    if( self.Ticker ) then
        self.Ticker:Cancel();
    end
    if( WorldMapUnitPin:IsForbidden() ) then
        return;
    end
    local function PingMap()
        if( WorldMapFrame:IsShown() ) then
            if( self:GetValue( 'PinPing' ) ) then
                WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
            else
                WorldMapUnitPin:StartPlayerPing( 1,0 );
                WorldMapUnitPin:StopPlayerPing();
            end
        end
    end
    local PingInterval = self:GetValue( 'PinPingSeconds' );
    self.Ticker = C_Timer.NewTicker( PingInterval,function()
        securecall( function()
            PingMap();
        end );
    end );
    PingMap();
end

function jMap:WorldMapFrameOnShow()
    -- Map Sync
    self:WorldMapFrameSynchronizeDisplayState();

    -- Map Emote
    if( C_ChatInfo and C_ChatInfo.PerformEmote ) then
        hooksecurefunc( C_ChatInfo,'PerformEmote',function( Emote )
            if( self:GetValue( 'StopReading' ) ) then
                C_ChatInfo.CancelEmote();
            end
        end );
    else
        hooksecurefunc( 'DoEmote',function( Emote )
            if( self:GetValue( 'StopReading' ) ) then
                CancelEmote();
            end
       end );
    end

    -- Map Fade
    local function OnUpdate()
        local Setting = {
            MinAlpha = jMap:GetValue( 'MapMinAlpha' ),
            MaxAlpha = jMap:GetValue( 'MapMaxAlpha' ),
            TimeToMax = 0.1,
        };
        if( WorldMapFrame:IsMouseOver() ) then
            WorldMapFrame:SetAlpha( Setting.MaxAlpha );
        else
            WorldMapFrame:SetAlpha( Setting.MinAlpha );
        end
    end
    FrameFaderDriver = CreateFrame( 'FRAME',nil,WorldMapFrame );
    FrameFaderDriver:HookScript( 'OnUpdate',OnUpdate );
    PlayerMovementFrameFader.RemoveFrame( WorldMapFrame );

    -- Map Ping
    self:WorldMapFramePing();
end

function jMap:WorldMapFrameCheckShown()
    if( self:GetValue( 'AlwaysShow' ) ) then
        if( self:HasMap() ) then
            if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
                if( not self.WorldMapFrameClosed ) then
                    WorldMapFrame:Show();
                end
            end
        else
            WorldMapFrame:Hide();
        end
    else
        WorldMapFrame:Hide();
    end
end

function jMap:WorldMapFrameSetScale()
    WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
end

function jMap:WorldMapFrameOnMouseWheel( self,Value )
    if( not jMap:GetValue( 'ScrollScale' ) ) then
        return;
    end
    local SliderData = {
        Name = 'MapScale',
        Step = .1,
        KeyPairs = {
            Low = {
                Value = .3,
                Description = 'Low',
            },
            High = {
                Value = 2,
                Description = 'High',
            },
        },
    };
    local RangeSlider = Library.FRAMES:AddRange( SliderData,WorldMapFrame,{
        -- AddRange initialization calls this
        Get = function( Index )
            return jMap:GetValue( 'MapScale' );
        end,
        -- AddRange:OnValueChanged calls this
        Set = function( Index,Value )
            print( 'Set',Index,Value)
            --return jMap:SetValue( 'MapScale',Value );
        end,
    },Library.Theme.Text.Colors.Default );

    local CurrentValue = jMap:GetValue( SliderData.Name );
    local ScrollDirection;
    if Value > 0 then
        ScrollDirection = 'up';
    else
        ScrollDirection = 'down';
    end

    local MaxValue;
    local MinValue;
    local NewValue;

    if ScrollDirection == 'up' then
        MaxValue = SliderData.KeyPairs.High.Value;
        NewValue = CurrentValue + SliderData.Step;
        if NewValue > MaxValue then
            return;
        end
    elseif ScrollDirection == 'down' then
        MinValue = SliderData.KeyPairs.Low.Value;
        NewValue = CurrentValue - SliderData.Step;
        if NewValue < MinValue then
            return;
        end
    end

    if( NewValue ~= nil ) then
        RangeSlider.EditBox:SetText( NewValue );
        jMap:SetValue( SliderData.Name,NewValue );
        jMap:WorldMapFrameSetScale();
    end
end

function jMap:WorldMapFrameStopMoving()
    WorldMapFrame:StopMovingOrSizing();
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
        if( MapXPos ~= nil and MapYPos ~= nil ) then
            jMap:SetValue( 'MapPoint',MapPoint );
            jMap:SetValue( 'MapRelativeTo',MapRelativeTo );
            jMap:SetValue( 'MapRelativePoint',MapRelativePoint );
            jMap:SetValue( 'MapXPos',MapXPos );
            jMap:SetValue( 'MapYPos',MapYPos );
        end
    end
    WorldMapFrame:SetUserPlaced( true );
end

function jMap:WorldMapFrameStartMoving()
    if( not WorldMapFrame:IsMaximized() ) then
        WorldMapFrame:StartMoving();
    end
end

function jMap:WorldMapFrameSetPosition()
    if( not( WorldMapFrame:IsMaximized() ) ) then
        local MapPoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
        if( MapXPos ~= nil and MapYPos ~= nil ) then
            WorldMapFrame:ClearAllPoints();
            WorldMapFrame:SetPoint( MapPoint,MapXPos,MapYPos );
        end
    end
end

function jMap:SetCVars()
    SetCVar('questLogOpen',Library:BoolToInt( not self:GetValue( 'PanelColapsed' ) ) );

    SetCVar( 'mapFade',Library:BoolToInt( self:GetValue( 'MapFade' ) ) );

    SetCVar( 'rotateMinimap',Library:BoolToInt( self:GetValue( 'MiniRotate' ) ) );
end

function jMap:HasMap()
    if( Library:IsVanilla() ) then
        local Instanced,InstanceType = IsInInstance();
        if( Instanced ) then
            return false;
        end
    end
    if( C_Housing and C_Housing.IsInsideHouse() ) then
        return false;
    end
    return true;
end

function jMap:UpdateWorldMapFrameZone()
    if( not self:GetValue( 'UpdateWorldMapFrameZone' ) ) then
        return;
    end
    local NewPosition = WorldMapFrame.mapID;
    local CurrentZone = C_Map.GetBestMapForUnit( 'player' );

    if( CurrentZone ) then
        WorldMapFrame:SetMapID( CurrentZone );
    end
end

function jMap:OnZoneChanged()
    self:UpdateWorldMapFrameZone();
end

function jMap:Refresh()
    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'Refreshing all settings...' );
    end

    -- Map Strata
    local DefaultStrata = WorldMapFrame:GetFrameStrata();
    if( self:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
        WorldMapFrame:SetFrameStrata( 'MEDIUM' );
    else
        WorldMapFrame:SetFrameStrata( DefaultStrata );
    end

    -- Map Settings
    self:SetCVars();

    -- Map Player Pin
    self:WorldMapFrameUpdatePin();

    -- Map Party Pin
    self:UpdatePartyPins();

    -- Map Pin Sizes
    self:WorldMapFrameSynchronizeSizes();

    -- Map Show
    self:WorldMapFrameOnShow();

    -- Check Show
    self:WorldMapFrameCheckShown();

    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'Done' );
    end
end

function jMap:OnEnable()
    WorldMapFrame:SetMovable( true );
    WorldMapFrame:RegisterForDrag( 'LeftButton' );

    -- Events
    self:RegisterEvent( 'ZONE_CHANGED_NEW_AREA','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED_INDOORS','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED','OnZoneChanged' );

    -- Hooks
    self:SecureHook( WorldMapFrame,'SynchronizeDisplayState','WorldMapFrameSynchronizeDisplayState' );
    self:SecureHookScript( WorldMapFrame.ScrollContainer,'OnMouseWheel','WorldMapFrameOnMouseWheel' );
    self:SecureHook( WorldMapUnitPin,'SynchronizePinSizes','WorldMapFrameSynchronizeSizes' );
    self:SecureHookScript( WorldMapFrame,'OnShow','WorldMapFrameOnShow' );
    hooksecurefunc( MapCanvasMixin,'OnMapChanged',function( self )
        jMap:WorldMapFrameUpdatePin();
    end );
    hooksecurefunc( 'MoveForwardStart',function()
        self:UpdateWorldMapFrameZone();
    end );

    -- Position
    WorldMapFrame:HookScript( 'OnDragStart',self.WorldMapFrameStartMoving );
    WorldMapFrame:HookScript( 'OnDragStop',self.WorldMapFrameStopMoving );

    -- Refresh
    self:Refresh();
end

function jMap:ConfigOpen( Input )
    if( not Input or Input:trim() == "" ) then

        if( InterfaceOptionsFrame_OpenToCategory ) then
            InterfaceOptionsFrame_OpenToCategory( self.CategoryID );
        else
            Settings.OpenToCategory( self.CategoryID );
        end
    else
        self:Print( 'Command:',Input );
    end
end

function jMap:OnInitialize()
    self:InitializeDB();
    self:InitializeConfig();
    self:RegisterChatCommand( 'jm','ConfigOpen' );
end