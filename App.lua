local _,Library = ...;
local jMap = LibStub( 'AceAddon-3.0' ):NewAddon( 'jMap','AceEvent-3.0','AceHook-3.0','AceConsole-3.0' );

function jMap:SetValue( Index,Value )
    return self:SetDBValue( Index,Value );
end

function jMap:GetValue( Index )
    return self:GetDBValue( Index );
end

function jMap:WorldMapFrameSynchronizeDisplayState()
    -- Map Position
    self:WorldMapSetPosition();

    -- Map Scale
    self:WorldMapFrameSetScale();
end

function jMap:WorldMapFrameSynchronizeSizes( self )
    local scale = self:GetMap():GetCanvasScale();
    for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
        if( Library:IsClassic() and unit == 'player' ) then
            size = size+10;
            --self:SetFrameStrata( 'TOOLTIP' );
        end
        if self.dataProvider:ShouldShowUnit(unit) then
            self:SetPinSize(unit, size / scale);
        end
    end
    self:SetPlayerPingScale( jMap:GetValue( 'PinAnimScale' ) / scale);
end

function jMap:WorldMapFrameOnShow()
    -- Map Position
    self:WorldMapSetPosition();

    -- Map Scale
    self:WorldMapFrameSetScale();

    -- Map Zone
    self:UpdateWorldMapFrameZone();

    -- Emotes
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

    -- Fading
    local function OnUpdate()
        local Setting = {
            MinAlpha = jMap:GetValue( 'MapAlpha' ),
            MaxAlpha = 1.0,
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
    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'WorldMapFrameCheckShown' );
    end
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

function jMap:WorldMapSetPosition()
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

function jMap:WorldMapFrameUpdatePinColor()
    -- Player Pin
    local WorldMapUnitPin;
    for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
        WorldMapUnitPin = pin
        break;
    end

    local SkullPins = {
        Pink = 'Interface\\WorldMap\\Skull_64Purple',
        Blue = 'Interface\\WorldMap\\Skull_64Blue',
        Yellow = 'Interface\\WorldMap\\skull_64',
        Green = 'Interface\\WorldMap\\Skull_64Green',
        Grey = 'Interface\\WorldMap\\skull_64grey',
        Red = 'Interface\\WorldMap\\Skull_64Red',
        Normal = 'Interface\\WorldMap\\WorldMapArrow',
    }
    WorldMapUnitPin:SetPinTexture( 'player',SkullPins[ self:GetValue( 'SkullMyAss' ) ] );
    local PingWidth,PingHeight = 75,75;

    if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
        WorldMapUnitPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
    end
    --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
    --WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
    --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
    --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );

    if( self:GetValue( 'ClassColors' ) ) then
        WorldMapUnitPin:SetUseClassColor( 'party',true );
        WorldMapUnitPin:SetUseClassColor( 'raid',true );
    else
        WorldMapUnitPin:SetUseClassColor( 'party',false );
        WorldMapUnitPin:SetUseClassColor( 'raid',false );
    end
end

function jMap:WorldMapFramePing()
    -- Player Pin
    local WorldMapUnitPin;
    for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
        WorldMapUnitPin = pin
        break;
    end

    if( self:GetValue( 'PinPing' ) ) then
        WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
    else
        WorldMapUnitPin:StartPlayerPing( 1,0 );
        WorldMapUnitPin:StopPlayerPing();
    end
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
    --WorldMapFrame:ResetZoom();
end

function jMap:OnZoneChanged()
    self:UpdateWorldMapFrameZone();

    -- Check Show
    self:WorldMapFrameCheckShown();
end

function jMap:Refresh()
    if( not WorldMapFrame ) then
        return;
    end
    
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

    -- Map Pin
    self:WorldMapFrameUpdatePinColor();
    
    -- Map Show
    self:WorldMapFrameOnShow();

    -- Check Show
    self:WorldMapFrameCheckShown();

    -- Continuous
    if( self.Ticker ) then
        self.Ticker:Cancel();
    end
    self.Ticker = C_Timer.NewTicker( self:GetValue( 'PinPingSeconds' ),function()
        -- Map Show
        self:WorldMapFrameCheckShown();

        -- Continue Ping
        self:WorldMapFramePing();
    end );

    -- Map Ping
    self:WorldMapFramePing();

    if( self:GetValue( 'Debug' ) ) then
        Library.FRAMES:Debug( 'Done' );
    end
end

function jMap:OnEnable()
    if( not WorldMapFrame ) then
        return;
    end
    WorldMapFrame:SetMovable( true );
    WorldMapFrame:RegisterForDrag( 'LeftButton' );

    -- Events
    self:RegisterEvent( 'ZONE_CHANGED_NEW_AREA','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED_INDOORS','OnZoneChanged' );
    self:RegisterEvent( 'ZONE_CHANGED','OnZoneChanged' );

    -- Player Pin
    local WorldMapUnitPin;
    for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
        WorldMapUnitPin = pin
        break;
    end

    -- Hooks
    self:SecureHook( WorldMapFrame,'SynchronizeDisplayState','WorldMapFrameSynchronizeDisplayState' );
    self:SecureHookScript( WorldMapFrame.ScrollContainer,'OnMouseWheel','WorldMapFrameOnMouseWheel' );
    self:SecureHook( WorldMapUnitPin,'SynchronizePinSizes','WorldMapFrameSynchronizeSizes' );
    self:SecureHookScript( WorldMapFrame,'OnShow','WorldMapFrameOnShow' );

    hooksecurefunc( MapCanvasPinMixin,'CheckMouseButtonPassthrough',function( ... )
        self:SetPassThroughButtons(); -- Clear existing passthrough buttons
    end );

    -- Position
    WorldMapFrame:HookScript( 'OnDragStart',self.WorldMapFrameStartMoving );
    WorldMapFrame:HookScript( 'OnDragStop',self.WorldMapFrameStopMoving );
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
    self:Refresh();
    self:RegisterChatCommand( 'jm','ConfigOpen' );
end