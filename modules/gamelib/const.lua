-- @docconsts @{

ACCOUNT_TYPE_NORMAL      = 1
ACCOUNT_TYPE_TUTOR       = 2
ACCOUNT_TYPE_SENIORTUTOR = 3
ACCOUNT_TYPE_GAMEMASTER  = 4
ACCOUNT_TYPE_GOD         = 5

FloorHigher = 0
FloorLower  = 15

CreatureTypePlayer      = 0
CreatureTypeMonster     = 1
CreatureTypeNpc         = 2
CreatureTypeSummonOwn   = 3
CreatureTypeSummonOther = 4
CreatureTypeHidden      = 5

SkullNone      = 0
SkullYellow    = 1
SkullGreen     = 2
SkullWhite     = 3
SkullRed       = 4
SkullBlack     = 5
SkullOrange    = 6
SkullProtected = 7

ShieldNone                   = 0
ShieldWhiteYellow            = 1
ShieldWhiteBlue              = 2
ShieldBlue                   = 3
ShieldYellow                 = 4
ShieldBlueSharedExp          = 5
ShieldYellowSharedExp        = 6
ShieldBlueNoSharedExpBlink   = 7
ShieldYellowNoSharedExpBlink = 8
ShieldBlueNoSharedExp        = 9
ShieldYellowNoSharedExp      = 10
ShieldGray                   = 11
ShieldStr = {
  [ShieldNone]        = loc'${CorelibInfoNone}',
  [ShieldWhiteYellow] = loc'${GamelibInfoShieldInviter}',
  [ShieldWhiteBlue]   = loc'${GamelibInfoShieldInvitee}',
  [ShieldBlue]        = loc'${GamelibInfoShieldPartner}',
  [ShieldYellow]      = loc'${GamelibInfoShieldLeader}',
  [ShieldGray]        = loc'${GamelibInfoShieldOtherMember}',
}
ShieldStr[ShieldBlueSharedExp]          = ShieldStr[ShieldBlue]
ShieldStr[ShieldYellowSharedExp]        = ShieldStr[ShieldYellow]
ShieldStr[ShieldBlueNoSharedExpBlink]   = ShieldStr[ShieldBlue]
ShieldStr[ShieldYellowNoSharedExpBlink] = ShieldStr[ShieldYellow]
ShieldStr[ShieldBlueNoSharedExp]        = ShieldStr[ShieldBlue]
ShieldStr[ShieldYellowNoSharedExp]      = ShieldStr[ShieldYellow]
ShieldHierarchy = { -- From most to less important
  [ShieldYellow]                 = 1,
  [ShieldYellowSharedExp]        = 2,
  [ShieldYellowNoSharedExpBlink] = 3,
  [ShieldYellowNoSharedExp]      = 4,
  [ShieldWhiteYellow]            = 5,

  [ShieldBlue]                   = 6,
  [ShieldBlueSharedExp]          = 7,
  [ShieldBlueNoSharedExpBlink]   = 8,
  [ShieldBlueNoSharedExp]        = 9,
  [ShieldWhiteBlue]              = 10,

  [ShieldGray]                   = 11,
  [ShieldNone]                   = 12,
}

EmblemNone   = 0
EmblemGreen  = 1
EmblemRed    = 2
EmblemBlue   = 3
EmblemMember = 4
EmblemOther  = 5

VocationLearner  = 0
VocationKnight   = 1
VocationPaladin  = 2
VocationArcher   = 3
VocationAssassin = 4
VocationWizard   = 5
VocationBard     = 6
VocationStr = {
  [VocationLearner]  = loc'${GamelibInfoVocationLearner}',
  [VocationKnight]   = loc'${GamelibInfoVocationKnight}',
  [VocationPaladin]  = loc'${GamelibInfoVocationPaladin}',
  [VocationArcher]   = loc'${GamelibInfoVocationArcher}',
  [VocationAssassin] = loc'${GamelibInfoVocationAssassin}',
  [VocationWizard]   = loc'${GamelibInfoVocationWizard}',
  [VocationBard]     = loc'${GamelibInfoVocationBard}',
}

TownNone    = 0
TownErembor = 1
TownNova    = 2
TownNalta   = 3
TownDronma  = 4
TownFirst   = TownErembor
TownLast    = TownDronma
TownStr = {
  [TownErembor] = "Erembor",
  [TownNova]    = "Nova",
  [TownNalta]   = "Nalta",
  [TownDronma]  = "Dron'Ma",
}

SpeechBubbleNone        = 0
SpeechBubbleChat        = 1
SpeechBubbleTrader      = 2
SpeechBubbleQuest       = 3
SpeechBubbleHouse       = 4
SpeechBubbleTraderQuest = 5
SpeechBubbleTraderHouse = 6

SpecialIconNone   = 0
SpecialIconWanted = 1

VipIconFirst = 0
VipIconLast  = 10

Directions = {
  North     = 0,
  East      = 1,
  South     = 2,
  West      = 3,
  NorthEast = 4,
  SouthEast = 5,
  SouthWest = 6,
  NorthWest = 7
}

Skill = {
  Fist            = 0,
  Club            = 1,
  Sword           = 2,
  Axe             = 3,
  Distance        = 4,
  Shielding       = 5,
  Fishing         = 6,
  CriticalChance  = 7,
  CriticalDamage  = 8,
  LifeLeechChance = 9,
  LifeLeechAmount = 10,
  ManaLeechChance = 11,
  ManaLeechAmount = 12
}

North     = Directions.North
East      = Directions.East
South     = Directions.South
West      = Directions.West
NorthEast = Directions.NorthEast
SouthEast = Directions.SouthEast
SouthWest = Directions.SouthWest
NorthWest = Directions.NorthWest

FightOffensive = 1
FightBalanced  = 2
FightDefensive = 3

DontChase     = 0
ChaseOpponent = 1

PVPWhiteDove  = 0
PVPWhiteHand  = 1
PVPYellowHand = 2
PVPRedFist    = 3

GameProtocolChecksum        = 1
GameAccountNames            = 2
GameChallengeOnLogin        = 3
GamePenalityOnDeath         = 4
GameNameOnNpcTrade          = 5
GameDoubleFreeCapacity      = 6
GameDoubleExperience        = 7
GameTotalCapacity           = 8
GameSkillsBase              = 9
GamePlayerRegenerationTime  = 10
GameChannelPlayerList       = 11
GamePlayerMounts            = 12
GameEnvironmentEffect       = 13
GameCreatureEmblems         = 14
GameItemAnimationPhase      = 15
GameMagicEffectU16          = 16
-- KA - Free
GameSpritesU32              = 18
-- KA - Free
GameOfflineTrainingTime     = 20
-- KA - Free
GameFormatCreatureName      = 22
-- KA - Free
GameClientPing              = 24
-- KA - Free
-- KA - Free
-- KA - Free
GameDoubleHealth            = 28
GameDoubleSkills            = 29
GameChangeMapAwareRange     = 30
GameMapMovePosition         = 31
GameAttackSeq               = 32
-- KA - Free
GameDiagonalAnimatedText    = 34
GameLoginPending            = 35
GameNewSpeedLaw             = 36
GameForceFirstAutoWalkStep  = 37
-- KA - Free
-- KA - Free
GameContainerPagination     = 40
GameThingMarks              = 41
GameLooktypeU16             = 42
GamePlayerStamina           = 43
GamePlayerAddons            = 44
GameMessageStatements       = 45
GameMessageLevel            = 46
GameNewFluids               = 47
GamePlayerStateU16          = 48
GameNewOutfitProtocol       = 49
-- KA - Free
GameWritableDate            = 51
GameAdditionalVipInfo       = 52
-- KA - Free
GameSpeechBubble            = 54 -- KA - Renamed from GameCreatureIcons
-- KA - Free
GameSpritesAlphaChannel     = 56
GamePremiumExpiration       = 57
-- KA - Free
GameEnhancedAnimations      = 59
GameOGLInformation          = 60
GameMessageSizeCheck        = 61
GamePreviewState            = 62
GameLoginPacketEncryption   = 63
GameClientVersion           = 64
GameContentRevision         = 65
GameExperienceBonus         = 66
GameAuthenticator           = 67
GameUnjustifiedPointsPacket = 68 -- KA - Renamed from GameUnjustifiedPoints
GameSessionKey              = 69
GameDeathType               = 70
GameIdleAnimations          = 71
GameKeepUnawareTiles        = 72
GameIngameStore             = 73
GameIngameStoreHighlights   = 74
GameIngameStoreServiceType  = 75
-- KA - Free
GameDistanceEffectU16       = 77
-- KA - Free
-- KA - Free
GameMapOldEffectRendering   = 80
GameMapDontCorrectCorpse    = 81
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
GameSequencedPackets        = 90
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
GameVipGroups               = 96
-- KA - Free
-- KA - Free
-- KA - Free
-- KA - Free
GameItemShader              = 101
GameCreatureShader          = 102
GameCreatureAttachedEffect  = 103
LastGameFeature             = 104

TextColors = {
  red         = '#f55e5e', --'#c83200'
  orange      = '#f36500', --'#c87832'
  lightYellow = '#e6db74',
  yellow      = '#ffff00', --'#e6c832'
  green       = '#00eb00', --'#3fbe32'
  lightblue   = '#5ff7f7',
  blue        = '#9f9dfd',
  --blue1     = '#6e50dc',
  --blue2     = '#3264c8',
  --blue3     = '#0096c8',
  white       = '#ffffff', --'#bebebe'
}

MessageModes = {
  None                  = 0,
  Say                   = 1,
  Whisper               = 2,
  Yell                  = 3,
  PrivateFrom           = 4,
  PrivateTo             = 5,
  ChannelManagement     = 6,
  Channel               = 7,
  ChannelHighlight      = 8,
  Spell                 = 9,
  NpcFromStartBlock     = 10,
  NpcFrom               = 11,
  NpcTo                 = 12,
  GamemasterBroadcast   = 13,
  GamemasterChannel     = 14,
  GamemasterPrivateFrom = 15,
  GamemasterPrivateTo   = 16,
  Login                 = 17,
  Warning               = 18,
  Game                  = 19,
  GameHighlight         = 20,
  Failure               = 21,
  Look                  = 22,
  DamageDealed          = 23,
  DamageReceived        = 24,
  Heal                  = 25,
  Exp                   = 26,
  DamageOthers          = 27,
  HealOthers            = 28,
  ExpOthers             = 29,
  Status                = 30,
  Loot                  = 31,
  TradeNpc              = 32,
  Guild                 = 33,
  PartyManagement       = 34,
  Party                 = 35,
  BarkLow               = 36,
  BarkLoud              = 37,
  Report                = 38,
  HotkeyUse             = 39,
  TutorialHint          = 40,
  Thankyou              = 41,
  GamemasterSay         = 42,
  Mana                  = 43,
  GameBigTop            = 44, -- KA - Big font text message (Jotun)
  GameBigCenter         = 45, -- KA - Big font text message (Jotun)
  GameBigBottom         = 46, -- KA - Big font text message (Jotun)

  Last                  = 52,
  Invalid               = 255,
}

OTSERV_RSA  = '1091201329673994292788609605089955415282375029027981291234687579' ..
              '3726629149257644633073969600111060390723088861007265581882535850' ..
              '3429057592827629436413108566029093628212635953836686562675849720' ..
              '6207862794310902180176810615217550567108238764764442605581471797' ..
              '07119674283982419152118103759076030616683978566631413'

CIPSOFT_RSA = '1321277432058722840622950990822933849527763264961655079678763618' ..
              '4334395343554449668205332383339435179772895415509701210392836078' ..
              '6959821132214473291575712138800495033169914814069637740318278150' ..
              '2907336840325241747827401343576296990629870233111328210165697754' ..
              '88792221429527047321331896351555606801473202394175817'

-- set to the latest Tibia.pic signature to make otclient compatible with official tibia
PIC_SIGNATURE = 0x56C5DDE7

OsTypes = {
  Linux           = 1,
  Windows         = 2,
  Flash           = 3,
  OtclientLinux   = 10,
  OtclientWindows = 11,
  OtclientMac     = 12,
}

PathFindResults = {
  Ok         = 0,
  Position   = 1,
  Impossible = 2,
  TooFar     = 3,
  NoWay      = 4,
}

PathFindFlags = {
  AllowNullTiles   = 1,
  AllowCreatures   = 2,
  AllowNonPathable = 4,
  AllowNonWalkable = 8,
}

VipState = {
  Offline = 0,
  Online  = 1,
  Pending = 2,
}

ExtendedIds = {
  Activate    = 0,
  Locale      = 1,
  Ping        = 2,
  Sound       = 3,
  Game        = 4,
  Particles   = 5,
  MapShader   = 6,
  NeedsUpdate = 7
}

PreviewState = {
  Default  = 0,
  Inactive = 1,
  Active   = 2
}

Blessings = {
  None               = 0,
  Adventurer         = 1,
  SpiritualShielding = 2,
  EmbraceOfTibia     = 4,
  FireOfSuns         = 8,
  WisdomOfSolitude   = 16,
  SparkOfPhoenix     = 32
}

DeathType = {
  Regular = 0,
  Blessed = 1
}

ProductType = {
  Other      = 0,
  NameChange = 1
}

StoreErrorType = {
  NoError       = -1,
  PurchaseError = 0,
  NetworkError  = 1,
  HistoryError  = 2,
  TransferError = 3,
  Information   = 4
}

StoreState = {
  None  = 0,
  New   = 1,
  Sale  = 2,
  Timed = 3
}

ChannelEvent = {
  Join    = 0,
  Leave   = 1,
  Invite  = 2,
  Exclude = 3,
}

ShadowFloor = {
  Disabled = 0,
  Bottom   = 1,
  Upside   = 2,
  Both     = 3
}

HotkeyStatus = {
  Applied = { color = 'alpha',     focusColor = '#CCCCCC44' },
  Added   = { color = '#00FF0044', focusColor = '#00CC0044' },
  Edited  = { color = '#FFFF0044', focusColor = '#CCCC0044' },
  Deleted = { color = '#FF000044', focusColor = '#CC000044' },
}

HotkeyItemUseType = {
  Default   = nil,
  Crosshair = 1,
  Target    = 2,
  Self      = 3
}

WidgetLockActionFlag = {
  Unlock = 0,
  Lock   = 1,
}

-- @}
