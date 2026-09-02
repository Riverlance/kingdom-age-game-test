-- Server to Client - Opcodes
ServerOpcodes = {
  -- At login only (this is why it may have same value of other opcodes)
  ServerOpcodeLoginOrPendingState        = 10,
  ServerOpcodeLoginErrorNew              = 11, -- 10.76+
  ServerOpcodeLoginTokenSuccess          = 12,
  ServerOpcodeLoginTokenError            = 13,
  ServerOpcodeLoginUpdate                = 17, -- Not in use yet
  ServerOpcodeLoginMotd                  = 20,
  ServerOpcodeLoginUpdateNeeded          = 30, -- Not in use yet
  ServerOpcodeLoginSessionKey            = 40,
  ServerOpcodeLoginCharacterList         = 100,
  ServerOpcodeLoginExtendedCharacterList = 101, -- Not in use yet
  -- -- --

  -- Free                               0 to 10
  -- Free                               11
  -- Free                               12 to 14
  ServerOpcodeEnterGame               = 15,
  -- Free                               16
  ServerOpcodeUpdateNeeded            = 17,
  -- Free                               18 to 19
  ServerOpcodeLoginError              = 20,
  ServerOpcodeLoginAdvice             = 21,
  ServerOpcodeLoginWait               = 22,
  ServerOpcodeLoginSuccess            = 23,
  ServerOpcodeLoginToken              = 24,
  ServerOpcodeStoreButtonIndicators   = 25, -- 1097
  -- Free                               26 to 28
  ServerOpcodePingBack                = 29,
  ServerOpcodePing                    = 30,
  ServerOpcodeChallenge               = 31,
  -- Free                               32 to 39
  ServerOpcodeDeath                   = 40,
  -- Free                               41 to 49
  ServerOpcodeExtendedOpcode          = 50,
  ServerOpcodeChangeMapAwareRange     = 51,
  ServerAttachedEffect                = 52, -- KA - Renamed from GameServerAttchedEffect
  ServerDetachEffect                  = 53, -- KA - Renamed from GameServerDetachEffect
  ServerCreatureShader                = 54, -- KA - Renamed from GameServerCreatureShader
  ServerMapShader                     = 55, -- KA - Renamed from GameServerMapShader
  ServerOpcodeProgressBar             = 56, -- KA - Progress bar
  ServerOpcodeFocusPoints             = 57, -- KA - Focus Points
  ServerOpcodeCreatureOutline         = 58, -- KA - Creature Outline
  -- Free                               59 to 82
  ServerOpcodeCreatureColor           = 83,
  ServerOpcodeCreatureNickname        = 84,
  ServerOpcodePlayerLoginname         = 85,
  ServerOpcodeCreatureSpecialIcon     = 86,
  ServerOpcodeAttributesList          = 87,
  ServerOpcodePowersList              = 88,
  ServerOpcodeConditionsList          = 89,
  ServerOpcodeCreatureJump            = 90,
  ServerOpcodeEmote                   = 91,
  ServerOpcodePartyList               = 92,
  ServerOpcodePlayerLevel             = 93,
  ServerOpcodeTracking                = 94,
  ServerOpcodePowerCast               = 95,
  ServerOpcodeStaticText              = 96,
  ServerOpcodeUnknownCreature         = 97,
  ServerOpcodeOutdatedCreature        = 98,
  ServerOpcodeCreature                = 99,
  ServerOpcodeFullMap                 = 100,
  ServerOpcodeMapTopRow               = 101,
  ServerOpcodeMapRightRow             = 102,
  ServerOpcodeMapBottomRow            = 103,
  ServerOpcodeMapLeftRow              = 104,
  ServerOpcodeUpdateTile              = 105,
  ServerOpcodeCreateOnMap             = 106,
  ServerOpcodeChangeOnMap             = 107,
  ServerOpcodeDeleteOnMap             = 108,
  ServerOpcodeMoveCreature            = 109,
  ServerOpcodeOpenContainer           = 110,
  ServerOpcodeCloseContainer          = 111,
  ServerOpcodeCreateContainer         = 112,
  ServerOpcodeChangeInContainer       = 113,
  ServerOpcodeDeleteInContainer       = 114,
  ServerOpcodePlayerShop              = 115, -- KA - Player shop actions
  ServerOpcodeCreatureSpeechBubble    = 116, -- KA - Creature speech bubble
  -- Free                               117 to 119
  ServerOpcodeSetInventory            = 120,
  ServerOpcodeDeleteInventory         = 121,
  ServerOpcodeOpenNpcTrade            = 122,
  ServerOpcodePlayerGoods             = 123,
  ServerOpcodeCloseNpcTrade           = 124,
  ServerOpcodeOwnTrade                = 125,
  ServerOpcodeCounterTrade            = 126,
  ServerOpcodeCloseTrade              = 127,
  -- Free                               128 to 129
  ServerOpcodeAmbient                 = 130,
  ServerOpcodeGraphicalEffect         = 131,
  ServerOpcodeTextEffect              = 132,
  ServerOpcodeMissileEffect           = 133,
  ServerOpcodeMarkCreature            = 134,
  ServerOpcodeTrappers                = 135,
  -- Free                               136 to 137
  ServerOpcodeCreatureHealth          = 138,
  ServerOpcodeCreatureMana            = 139,
  ServerOpcodeCreatureVigor           = 140,
  ServerOpcodeCreatureLight           = 141,
  ServerOpcodeCreatureOutfit          = 142,
  ServerOpcodeCreatureSpeed           = 143,
  ServerOpcodeCreatureSkull           = 144,
  ServerOpcodeCreatureParty           = 145,
  ServerOpcodeCreatureUnpass          = 146,
  ServerOpcodeCreatureMarks           = 147,
  -- Free                               148
  ServerOpcodeCreatureType            = 149,
  ServerOpcodeEditText                = 150,
  ServerOpcodeEditList                = 151,
  -- Free                               152 to 155
  ServerOpcodeBlessings               = 156,
  ServerOpcodePreset                  = 157,
  ServerOpcodePremiumTrigger          = 158, -- 1038
  ServerOpcodePlayerDataBasic         = 159, -- 950
  ServerOpcodePlayerData              = 160,
  -- Free                             = 161,
  ServerOpcodePlayerState             = 162,
  ServerOpcodeClearTarget             = 163,
  ServerOpcodeSpellDelay              = 164, -- 870
  ServerOpcodeSpellGroupDelay         = 165, -- 870
  ServerOpcodeMultiUseDelay           = 166, -- 870
  ServerOpcodePlayerModes             = 167,
  ServerOpcodeSetStoreDeepLink        = 168, -- 1097
  -- Free                               169
  ServerOpcodeTalk                    = 170,
  ServerOpcodeChannels                = 171,
  ServerOpcodeOpenChannel             = 172,
  ServerOpcodeOpenPrivateChannel      = 173,
  -- Free                               174 to 177
  ServerOpcodeOpenOwnChannel          = 178,
  ServerOpcodeCloseChannel            = 179,
  ServerOpcodeTextMessage             = 180,
  ServerOpcodeCancelWalk              = 181,
  ServerOpcodeWalkWait                = 182,
  ServerOpcodeUnjustifiedStats        = 183,
  ServerOpcodePvpSituations           = 184,
  -- Free                               185 to 189
  ServerOpcodeFloorChangeUp           = 190,
  ServerOpcodeFloorChangeDown         = 191,
  -- Free                               192 to 199
  ServerOpcodeChooseOutfit            = 200,
  -- Free                               201 to 209
  ServerOpcodeVipAdd                  = 210,
  ServerOpcodeVipState                = 211,
  ServerOpcodeVipLogout               = 212,
  -- Free                               213 to 219
  ServerOpcodeTutorialHint            = 220,
  ServerOpcodeAutomapFlag             = 221,
  ServerOpcodeMapShaders              = 222,
  ServerOpcodeCoinBalance             = 223, -- 1080
  ServerOpcodeStoreError              = 224, -- 1080
  ServerOpcodeRequestPurchaseData     = 225, -- 1080
  -- Free                               226 to 241
  ServerOpcodeCoinBalanceUpdating     = 242, -- 1080
  ServerOpcodeChannelEvent            = 243, -- 910
  ServerOpcodeItemInfo                = 244, -- 910
  ServerOpcodePlayerInventory         = 245, -- 910
  -- Free                               246 to 249
  ServerOpcodeModalDialog             = 250, -- 960
  ServerOpcodeStore                   = 251, -- 1080
  ServerOpcodeStoreOffers             = 252, -- 1080
  ServerOpcodeStoreTransactionHistory = 253, -- 1080
  ServerOpcodeStoreCompletePurchase   = 254, -- 1080
  -- Free                               255
}

-- Server to Client - Extended Opcodes
ServerExtOpcodes = {
  ServerExtOpcodeOtclientSignal    = 0, -- From Server ProtocolGame::onRecvFirstMessage
  ServerExtOpcodeAccountInfo       = 1,
  ServerExtOpcodeInstanceInfo      = 2,
  ServerExtOpcodeBlinkHit          = 3,
  ServerExtOpcodeLootWindow        = 4,
  ServerExtOpcodeScreenImage       = 5,
  ServerExtOpcodeAudio             = 6,
  ServerExtOpcodeUnjustifiedPoints = 7,
  ServerExtOpcodeQuestLog          = 8,
  ServerExtOpcodeBugReport         = 9,
  ServerExtOpcodeRuleViolation     = 10,
  ServerExtOpcodeDailyReward       = 11,
  ServerExtOpcodeWidgetLock        = 12,
  ServerExtOpcodePowerList         = 13,
  -- Free                            14 to 65535
}

-- Client to Server - Opcodes
ClientOpcodes = {
  -- Free                                 0
  ClientOpcodeEnterAccount              = 1,
  -- Free                                 2 to 9
  ClientOpcodePendingGame               = 10,
  -- Free                                 11 to 14
  ClientOpcodeEnterGame                 = 15,
  -- Free                                 16 to 19
  ClientOpcodeLeaveGame                 = 20,
  -- Free                                 21 to 28
  ClientOpcodePing                      = 29,
  ClientOpcodePingBack                  = 30,
  -- Free                                 31 to 49
  ClientOpcodeExtendedOpcode            = 50,
  ClientOpcodeChangeMapAwareRange       = 51,
  -- Free
  ClientOpcodeActionKey                 = 53,
  -- Free                                 54 to 60
  ClientOpcodePartyList                 = 61, -- Needed?
  -- Free                                 62
  ClientOpcodeTracking                  = 63,
  ClientOpcodePowerCast                 = 64,
  ClientOpcodePlayerShop                = 65, -- KA - Player shop actions
  -- Free                                 66 to 99
  ClientOpcodeAutoWalk                  = 100,
  ClientOpcodeWalkNorth                 = 101,
  ClientOpcodeWalkEast                  = 102,
  ClientOpcodeWalkSouth                 = 103,
  ClientOpcodeWalkWest                  = 104,
  ClientOpcodeStop                      = 105,
  ClientOpcodeWalkNorthEast             = 106,
  ClientOpcodeWalkSouthEast             = 107,
  ClientOpcodeWalkSouthWest             = 108,
  ClientOpcodeWalkNorthWest             = 109,
  -- Free                                 110
  ClientOpcodeTurnNorth                 = 111,
  ClientOpcodeTurnEast                  = 112,
  ClientOpcodeTurnSouth                 = 113,
  ClientOpcodeTurnWest                  = 114,
  -- Free                                 115 to 118
  ClientOpcodeEquipItem                 = 119, -- 910
  ClientOpcodeMove                      = 120,
  ClientOpcodeInspectNpcTrade           = 121,
  ClientOpcodeBuyItem                   = 122,
  ClientOpcodeSellItem                  = 123,
  ClientOpcodeCloseNpcTrade             = 124,
  ClientOpcodeRequestTrade              = 125,
  ClientOpcodeInspectTrade              = 126,
  ClientOpcodeAcceptTrade               = 127,
  ClientOpcodeRejectTrade               = 128,
  -- Free                                 129
  ClientOpcodeUseItem                   = 130,
  ClientOpcodeUseItemWith               = 131,
  ClientOpcodeUseOnCreature             = 132,
  ClientOpcodeRotateItem                = 133,
  -- Free                                 134
  ClientOpcodeCloseContainer            = 135,
  ClientOpcodeUpContainer               = 136,
  ClientOpcodeEditText                  = 137,
  ClientOpcodeEditList                  = 138,
  ClientOpcodeWrapItem                  = 139,
  ClientOpcodeLook                      = 140,
  ClientOpcodeLookCreature              = 141,
  -- Free                                 142 to 149
  ClientOpcodeTalk                      = 150,
  ClientOpcodeRequestChannels           = 151,
  ClientOpcodeJoinChannel               = 152,
  ClientOpcodeLeaveChannel              = 153,
  ClientOpcodeOpenPrivateChannel        = 154,
  -- Free                                 155 to 157
  ClientOpcodeCloseNpcChannel           = 158,
  -- Free                                 159
  ClientOpcodeChangeFightModes          = 160,
  ClientOpcodeAttack                    = 161,
  ClientOpcodeFollow                    = 162,
  ClientOpcodeInviteToParty             = 163,
  ClientOpcodeJoinParty                 = 164,
  ClientOpcodeRevokeInvitation          = 165,
  ClientOpcodePassLeadership            = 166,
  ClientOpcodeLeaveParty                = 167,
  ClientOpcodeShareExperience           = 168,
  -- Free                                 169
  ClientOpcodeOpenOwnChannel            = 170,
  ClientOpcodeInviteToOwnChannel        = 171,
  ClientOpcodeExcludeFromOwnChannel     = 172,
  -- Free                                 173 to 189
  ClientOpcodeCancelAttackAndFollow     = 190,
  -- Free                                 191 to 201
  ClientOpcodeRefreshContainer          = 202,
  -- Free                                 203
  ClientOpcodeSeekInContainer           = 204,
  -- Free                                 205 to 209
  ClientOpcodeRequestOutfit             = 210,
  ClientOpcodeChangeOutfit              = 211,
  ClientOpcodeMount                     = 212, -- 870
  -- Free                                 213 to 219
  ClientOpcodeAddVip                    = 220,
  ClientOpcodeRemoveVip                 = 221,
  ClientOpcodeEditVip                   = 222,
  -- Free                                 223 to 231
  ClientOpcodeDebugReport               = 232,
  -- Free                                 233 to 238
  ClientOpcodeTransferCoins             = 239, -- 1080
  -- Free                                 240 to 242
  ClientOpcodeRequestItemInfo           = 243, -- 910
  -- Free                                 244 to 248
  ClientOpcodeAnswerModalDialog         = 249, -- 960
  ClientOpcodeOpenStore                 = 250, -- 1080
  ClientOpcodeRequestStoreOffers        = 251, -- 1080
  ClientOpcodeBuyStoreOffer             = 252, -- 1080
  ClientOpcodeOpenTransactionHistory    = 253, -- 1080
  ClientOpcodeRequestTransactionHistory = 254, -- 1080
  -- Free                                 255
}

-- Client to Server - Extended Opcodes (onExtendedOpcode Player Event)
ClientExtOpcodes = {
  -- Free                              0
  ClientExtOpcodeLocale              = 1,
  ClientExtOpcodeAction              = 2,
  ClientExtOpcodeAttribute           = 3,
  ClientExtOpcodePowerList           = 4,
  ClientExtOpcodeUnjustifiedPoints   = 5,
  ClientExtOpcodeQuestLog            = 6,
  ClientExtOpcodeBugReport           = 7,
  ClientExtOpcodeRuleViolation       = 8,
  ClientExtOpcodeConditionsList      = 9,
  ClientExtOpcodeEmote               = 10,
  ClientExtOpcodeDailyReward         = 11,
  ClientExtOpcodeGreetNpc            = 12,
  ClientExtOpcodeGoldLootAutoDeposit = 13,
  ClientExtOpcodeDeals               = 14,
  ClientExtOpcodeWorldChannel        = 15,
  -- Free                              16 to 65535
}

ClientActions = {
  QuestItems     = 1,
  QuestTeleports = 2
}
