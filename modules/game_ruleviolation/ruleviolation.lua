g_locales.loadLocales(resolvepath(''))

_G.GameRuleViolation = { }



local minimumCommentSize = 50
local textPattern        = '[^%w%s!?%+-*/=@%(%)%[%]%{%}.,]+' -- Find symbols that are NOT letters, numbers, spaces and !?+-*/=@()[]{}.,



local REPORT_MODE_NEWREPORT    = 0
local REPORT_MODE_UPDATESEARCH = 1
local REPORT_MODE_UPDATESTATE  = 2
local REPORT_MODE_REMOVEROW    = 3
local REPORT_MODE_ACTION       = 4

local REPORT_TYPE_ALL       = 255
local REPORT_TYPE_NAME      = 0
local REPORT_TYPE_STATEMENT = 1
local REPORT_TYPE_VIOLATION = 2
local REPORT_TYPE_NOTATIONS = 3

local function sendNewReport(_type, targetName, reasonId, comment, statement, translation)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  if not statement or statement == '' then
    statement = '-'
  end

  statement = statement:gsub(':', ';') -- Replace all ':' with ';' for avoid errors on opcodes
  if not translation or translation == '' then
    translation = '-'
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeRuleViolation)
  msg:addString(f('%d:%d:%s:%d:%s:%s:%s', REPORT_MODE_NEWREPORT, _type, targetName, reasonId, comment:trim(), statement:trim(), translation:trim()))
  protocolGame:send(msg)
end

local function sendUpdateSearch(_type, reasonId, page, rowsPerPage, state)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeRuleViolation)
  msg:addString(f('%d:%d:%d:%d:%d:%d', REPORT_MODE_UPDATESEARCH, _type, reasonId, page, rowsPerPage, state))
  protocolGame:send(msg)
end

local function sendUpdateState(row, state) -- (row[, state])
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeRuleViolation)
  msg:addString(f('%d:%d:%d', REPORT_MODE_UPDATESTATE, state or row.state, row.id))
  protocolGame:send(msg)
end

local function sendRemoveRow(row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeRuleViolation)
  msg:addString(f('%d:%d', REPORT_MODE_REMOVEROW, row.id))
  protocolGame:send(msg)
end

local function sendAddAction(_type, targetName, reasonId, comment, actionId, days, row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  if comment == '' then
    comment = '-'
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeRuleViolation)
  msg:addString(f('%d:%d:%s:%d:%s:%d:%d:%d', REPORT_MODE_ACTION, _type, targetName, reasonId, comment:trim(), actionId, days, row and row.id or 0))
  protocolGame:send(msg)
end



rvWindow                 = nil
rvLabel                  = nil
targetTextEdit           = nil
statementTextEdit        = nil
translationTextEdit      = nil
typeComboBox             = nil
reasonMultilineTextEdit  = nil
commentMultilineTextEdit = nil
okButton                 = nil
cancelButton             = nil



local types = {
  [REPORT_TYPE_ALL]       = loc'${CorelibInfoAll}',
  [REPORT_TYPE_NAME]      = loc'${CorelibInfoName}',
  [REPORT_TYPE_STATEMENT] = loc'${GameRuleViolationReportTypeStatement}',
  [REPORT_TYPE_VIOLATION] = loc'${GameRuleViolationReportTypeViolation}',
}

local typeId = REPORT_TYPE_NAME

local reasons = { -- Titles should have until 255 characters.
  [REPORT_TYPE_NAME] = {
    [0]  = { title = loc'${GameRuleViolationNameRacism}',                 description = loc'${GameRuleViolationNameRacismDesc}' },
    [1]  = { title = loc'${GameRuleViolationNameHarassing}',              description = loc'${GameRuleViolationNameHarassingDesc}' },
    [2]  = { title = loc'${GameRuleViolationNameInsulting}',              description = loc'${GameRuleViolationNameInsultingDesc}' },
    [3]  = { title = loc'${GameRuleViolationNameDrug}',                   description = loc'${GameRuleViolationNameDrugDesc}' },
    [4]  = { title = loc'${GameRuleViolationNameSexually}',               description = loc'${GameRuleViolationNameSexuallyDesc}' },
    [5]  = { title = loc'${GameRuleViolationNameReligiousPolitical}',     description = loc'${GameRuleViolationNameReligiousPoliticalDesc}' },
    [6]  = { title = loc'${GameRuleViolationNameGenerallyObjectionable}', description = loc'${GameRuleViolationNameGenerallyObjectionableDesc}' },
    [7]  = { title = loc'${GameRuleViolationNameSupporting}',             description = loc'${GameRuleViolationNameSupportingDesc}' },
    [8]  = { title = loc'${GameRuleViolationNameBrand}',                  description = loc'${GameRuleViolationNameBrandDesc}' },
    [9]  = { title = loc'${GameRuleViolationNameNotRelatedToTheGame}',    description = loc'${GameRuleViolationNameNotRelatedToTheGameDesc}' },
    [10] = { title = loc'${GameRuleViolationName}',                       description = loc'${GameRuleViolationNameDesc}' },
  },

  [REPORT_TYPE_STATEMENT] = {
    [0]  = { title = loc'${GameRuleViolationStatementNotDefaultLanguage}',     description = loc'${GameRuleViolationStatementNotDefaultLanguageDesc}' },
    [1]  = { title = loc'${GameRuleViolationStatementNotChannelSubject}',      description = loc'${GameRuleViolationStatementNotChannelSubjectDesc}' },
    [2]  = { title = loc'${GameRuleViolationStatementNonsensicalText}',        description = loc'${GameRuleViolationStatementNonsensicalTextDesc}' },
    [3]  = { title = loc'${GameRuleViolationStatementRepeatingText}',          description = loc'${GameRuleViolationStatementRepeatingTextDesc}' },
    [4]  = { title = loc'${GameRuleViolationStatementRacism}',                 description = loc'${GameRuleViolationStatementRacismDesc}' },
    [5]  = { title = loc'${GameRuleViolationStatementHarassing}',              description = loc'${GameRuleViolationStatementHarassingDesc}' },
    [6]  = { title = loc'${GameRuleViolationStatementInsulting}',              description = loc'${GameRuleViolationStatementInsultingDesc}' },
    [7]  = { title = loc'${GameRuleViolationStatementDrug}',                   description = loc'${GameRuleViolationStatementDrugDesc}' },
    [8]  = { title = loc'${GameRuleViolationStatementSexually}',               description = loc'${GameRuleViolationStatementSexuallyDesc}' },
    [9]  = { title = loc'${GameRuleViolationStatementReligiousPolitical}',     description = loc'${GameRuleViolationStatementReligiousPoliticalDesc}' },
    [10] = { title = loc'${GameRuleViolationStatementGenerallyObjectionable}', description = loc'${GameRuleViolationStatementGenerallyObjectionableDesc}' },
    [11] = { title = loc'${GameRuleViolationStatementSupporting}',             description = loc'${GameRuleViolationStatementSupportingDesc}' },
    [12] = { title = loc'${GameRuleViolationStatementBrand}',                  description = loc'${GameRuleViolationStatementBrandDesc}' },
    [13] = { title = loc'${GameRuleViolationStatementNotRelatedToTheGame}',    description = loc'${GameRuleViolationStatementNotRelatedToTheGameDesc}' },
    [14] = { title = loc'${GameRuleViolationStatementDisclosingPersonalData}', description = loc'${GameRuleViolationStatementDisclosingPersonalDataDesc}' },
    [15] = { title = loc'${GameRuleViolationStatementFalseInfoToTeam}',        description = loc'${GameRuleViolationStatementFalseInfoToTeamDesc}' },
    [16] = { title = loc'${GameRuleViolationStatementWrongInfoAboutTeam}',     description = loc'${GameRuleViolationStatementWrongInfoAboutTeamDesc}' },
    [17] = { title = loc'${GameRuleViolationStatementBoycootTeam}',            description = loc'${GameRuleViolationStatementBoycootTeamDesc}' },
    [18] = { title = loc'${GameRuleViolationStatementPretendingBeTeam}',       description = loc'${GameRuleViolationStatementPretendingBeTeamDesc}' },
    [19] = { title = loc'${GameRuleViolationStatement}',                       description = loc'${GameRuleViolationStatementDesc}' },
  },

  [REPORT_TYPE_VIOLATION] = {
    [0] = { title = loc'${GameRuleViolationMainBugAbuse}',            description = loc'${GameRuleViolationMainBugAbuseDesc}' },
    [1] = { title = loc'${GameRuleViolationMainErrorAbuse}',          description = loc'${GameRuleViolationMainErrorAbuseDesc}' },
    [2] = { title = loc'${GameRuleViolationMainUnofficialSoftware}',  description = loc'${GameRuleViolationMainUnofficialSoftwareDesc}' },
    [3] = { title = loc'${GameRuleViolationMainStealingData}',        description = loc'${GameRuleViolationMainStealingDataDesc}' },
    [4] = { title = loc'${GameRuleViolationMainManipulatingClient}',  description = loc'${GameRuleViolationMainManipulatingClientDesc}' },
    [5] = { title = loc'${GameRuleViolationMainAttackingService}',    description = loc'${GameRuleViolationMainAttackingServiceDesc}' },
    [6] = { title = loc'${GameRuleViolationMainAgainstService}',      description = loc'${GameRuleViolationMainAgainstServiceDesc}' },
    [7] = { title = loc'${GameRuleViolationMainAgainstRightOfThird}', description = loc'${GameRuleViolationMainAgainstRightOfThirdDesc}' },
    [8] = { title = loc'${GameRuleViolationMainAgainstLaw}',          description = loc'${GameRuleViolationMainAgainstLawDesc}' },
    [9] = { title = loc'${GameRuleViolationMain}',                    description = loc'${GameRuleViolationMainDesc}' },
  }
}

local reasonId = 0



function GameRuleViolation.init()
  -- Alias
  GameRuleViolation.m = modules.game_ruleviolation

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeRuleViolation, GameRuleViolation.parseRuleViolationsReports) -- View List
end

function GameRuleViolation.terminate()
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeRuleViolation) -- View List

  GameRuleViolation.destroyRuleViolationReportWindow()
  GameRuleViolation.destroyRVViewWindow()

  _G.GameRuleViolation = nil
end

function GameRuleViolation.showRuleViolationReportWindow(_type, targetName, statement)
  if not g_game.isOnline() then
    return
  end
  typeId = _type

  g_ui.importStyle('ruleviolation')

  rvWindow                 = g_ui.createWidget('RVWindow', rootWidget)
  rvLabel                  = rvWindow:getChildById('rvLabel')
  targetTextEdit           = rvWindow:getChildById('targetTextEdit')
  statementTextEdit        = rvWindow:getChildById('statementTextEdit')
  translationTextEdit      = rvWindow:getChildById('translationTextEdit')
  typeComboBox             = rvWindow:getChildById('typeComboBox')
  reasonMultilineTextEdit  = rvWindow:getChildById('reasonMultilineTextEdit')
  commentMultilineTextEdit = rvWindow:getChildById('commentMultilineTextEdit')
  okButton                 = rvWindow:getChildById('okButton')
  cancelButton             = rvWindow:getChildById('cancelButton')

  rvWindow:setText(f(loc'${GameRuleViolationReportPlayer}', types[typeId]:lower()))

  if targetName then
    targetTextEdit:setText(targetName)
  end

  if statement then
    statementTextEdit:setText(statement)
  end

  typeComboBox.onOptionChange = GameRuleViolation.onChangeReasonId
  if reasons[typeId] then
    for reasonId = 0, #reasons[typeId] do
      local reason = reasons[typeId][reasonId]
      typeComboBox:addOption(reason.title)
    end
  end

  -- Only REPORT_TYPE_STATEMENT has fields statement and translation
  if typeId ~= REPORT_TYPE_STATEMENT then
    local statementLabel   = rvWindow:getChildById('statementLabel')
    local translationLabel = rvWindow:getChildById('translationLabel')

    statementLabel:destroy()
    statementTextEdit:destroy()
    translationLabel:destroy()
    translationTextEdit:destroy()
    statementLabel      = nil
    statementTextEdit   = nil
    translationLabel    = nil
    translationTextEdit = nil
  end

  rvWindow:show()
  rvWindow:raise()
  if translationTextEdit then
    translationTextEdit:focus()
  else
    commentMultilineTextEdit:focus()
  end
end

function GameRuleViolation.destroyRuleViolationReportWindow()
  if rvWindow then
    rvWindow:destroy()
  end

  rvWindow                 = nil
  rvLabel                  = nil
  targetTextEdit           = nil
  statementTextEdit        = nil
  translationTextEdit      = nil
  typeComboBox             = nil
  reasonMultilineTextEdit  = nil
  commentMultilineTextEdit = nil
  okButton                 = nil
  cancelButton             = nil
end



function GameRuleViolation.onChangeReasonId(comboBox, option)
  if not reasons[typeId] then
    return
  end

  if option then
    for _reasonId = 0, #reasons[typeId] do
      local reason = reasons[typeId][_reasonId]
      if option == reason.title then
        reasonId = _reasonId
        break
      end
    end
  end

  reasonMultilineTextEdit:setText(typeId and reasonId >= 0 and reasons[typeId][reasonId] and reasons[typeId][reasonId].description or '')
end

function GameRuleViolation.report()
  if not g_game.isOnline() then
    return
  end

  local targetName  = targetTextEdit:getText()
  local statement   = statementTextEdit and statementTextEdit:getText() or nil
  local translation = translationTextEdit and translationTextEdit:getText() or nil
  local comment     = commentMultilineTextEdit:getText()

  local err
  if typeId == REPORT_TYPE_STATEMENT and not statement then
    err = loc'${GameRuleViolationErrorNoStatement}'
  elseif translation and translation:match(textPattern) then
    err = loc'${GameRuleViolationErrorTranslationNotFormatted}'
  elseif #comment < minimumCommentSize then
    err = f(loc'${GameRuleViolationErrorMinChars}', minimumCommentSize)
  elseif comment:match(textPattern) then
    err = loc'${GameRuleViolationErrorCommentNotFormatted}'
  end
  if err then
    displayErrorBox(loc'${CorelibInfoError}', err)
    return
  end

  sendNewReport(typeId, targetName, reasonId, comment, statement or '', translation or '')
  GameRuleViolation.destroyRuleViolationReportWindow()
end










-- View window

local rvViewWindow                     = nil
local rvViewActionButton               = nil
local rvViewTypeActionComboBox         = nil
local rvViewActionComboBox             = nil
local rvViewActionReasonComboBox       = nil
local rvViewActionTargetNameLabel      = nil
local rvViewTargetNameTextEdit         = nil
local rvViewCommentMultilineTextEdit   = nil
local rvViewList                       = nil
local rvViewPage                       = nil
local rvViewRowsPerPageLabel           = nil
local rvViewRowsPerPageOptionScrollbar = nil
local rvViewStateComboBox              = nil
local rvViewTypeComboBox               = nil
local rvViewReasonComboBox             = nil



local REPORT_STATE_UNDONE  = 255
local REPORT_STATE_NEW     = 0
local REPORT_STATE_WORKING = 1
local REPORT_STATE_DONE    = 2

local states = {
  [REPORT_STATE_UNDONE]  = loc'${GameRuleViolationStateUndone}',
  [REPORT_STATE_NEW]     = loc'${GameRuleViolationStateNew}',
  [REPORT_STATE_WORKING] = loc'${GameRuleViolationStateWorking}',
  [REPORT_STATE_DONE]    = loc'${GameRuleViolationStateDone}'
}



local VIOLATION_ACTIONTYPE_NOTATION  = 0
local VIOLATION_ACTIONTYPE_NAMELOCK  = 1
local VIOLATION_ACTIONTYPE_ACCOUNT   = 2
local VIOLATION_ACTIONTYPE_IPACCOUNT = 3

local ACTION_NOTATION             = { title = loc'${GameRuleViolationNotation}', actionType = VIOLATION_ACTIONTYPE_NOTATION }
local ACTION_NAMELOCK             = { title = loc'${GameRuleViolationNameLock}', actionType = VIOLATION_ACTIONTYPE_NAMELOCK }
local ACTION_BANISHMENT_7_DAYS    = { title = f(loc'${GameRuleViolationBanishmentDays}', 7), actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 7 }
local ACTION_BANISHMENT_14_DAYS   = { title = f(loc'${GameRuleViolationBanishmentDays}', 14), actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 14 }
local ACTION_BANISHMENT_30_DAYS   = { title = f(loc'${GameRuleViolationBanishmentDays}', 30), actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 30 }
local ACTION_BANISHMENT_60_DAYS   = { title = f(loc'${GameRuleViolationBanishmentDays}', 60), actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 60 }
local ACTION_BANISHMENT_90_DAYS   = { title = f(loc'${GameRuleViolationBanishmentDays}', 90), actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 90 }
local ACTION_BANISHMENT_PERMANENT = { title = loc'${GameRuleViolationPermanentBanishment}', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 0 }
local ACTION_IPBANISHMENT_7_DAYS  = { title = f(loc'${GameRuleViolationIPBanishmentDays}', 7), actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 7 }
local ACTION_IPBANISHMENT_14_DAYS = { title = f(loc'${GameRuleViolationIPBanishmentDays}', 14), actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 14 }
local ACTION_IPBANISHMENT_30_DAYS = { title = f(loc'${GameRuleViolationIPBanishmentDays}', 30), actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 30 }
local ACTION_IPBANISHMENT_60_DAYS = { title = f(loc'${GameRuleViolationIPBanishmentDays}', 60), actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 60 }
local ACTION_IPBANISHMENT_90_DAYS = { title = f(loc'${GameRuleViolationIPBanishmentDays}', 90), actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 90 }

local actions = {
  [REPORT_TYPE_NAME] = {
    ACTION_NAMELOCK
  },

  [REPORT_TYPE_STATEMENT] = {
    ACTION_NOTATION,
    ACTION_BANISHMENT_7_DAYS,
    ACTION_BANISHMENT_14_DAYS,
    ACTION_BANISHMENT_30_DAYS,
    ACTION_BANISHMENT_60_DAYS,
    ACTION_BANISHMENT_90_DAYS,
    ACTION_BANISHMENT_PERMANENT,
    ACTION_IPBANISHMENT_7_DAYS,
    ACTION_IPBANISHMENT_14_DAYS,
    ACTION_IPBANISHMENT_30_DAYS,
    ACTION_IPBANISHMENT_60_DAYS,
    ACTION_IPBANISHMENT_90_DAYS
  },

  [REPORT_TYPE_VIOLATION] = {
    ACTION_NOTATION,
    ACTION_BANISHMENT_7_DAYS,
    ACTION_BANISHMENT_14_DAYS,
    ACTION_BANISHMENT_30_DAYS,
    ACTION_BANISHMENT_60_DAYS,
    ACTION_BANISHMENT_90_DAYS,
    ACTION_BANISHMENT_PERMANENT,
    ACTION_IPBANISHMENT_7_DAYS,
    ACTION_IPBANISHMENT_14_DAYS,
    ACTION_IPBANISHMENT_30_DAYS,
    ACTION_IPBANISHMENT_60_DAYS,
    ACTION_IPBANISHMENT_90_DAYS
  }
}



local viewPage         = 1
local maxPages         = 1
local viewActionType   = REPORT_TYPE_NAME
local viewAction       = 1
local viewActionReason = 0
local viewTargetName   = ''
local viewComment      = ''
local viewState        = REPORT_STATE_UNDONE -- New + Working
local viewType         = REPORT_TYPE_ALL
local viewReason       = 0

local function hasViewAccess()
  return g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER
end

local function getWindowState()
  return g_game.isOnline() and rvViewWindow and hasViewAccess()
end



function GameRuleViolation.listOnChildFocusChange(textList, focusedChild)
  if not textList then
    return
  end

  -- Update Report Rows Style
  local children = textList:getChildren()
  for i = 1, #children do
    if children[i].state == REPORT_STATE_WORKING then
      children[i]:setColor('#3264c8')
    elseif children[i].state == REPORT_STATE_DONE then
      children[i]:setOn(true)
    end
  end
  if not focusedChild then
    return
  end

  if rvViewTargetNameTextEdit then
    rvViewActionTargetNameLabel:destroy()
    rvViewTargetNameTextEdit:destroy()
    rvViewActionTargetNameLabel = nil
    rvViewTargetNameTextEdit    = nil

    rvViewWindow:getChildById('commentLabel'):addAnchor(AnchorTop, 'prev', AnchorBottom)
  end
end

function GameRuleViolation.showViewWindow(_targetName, _comment)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  viewPage         = viewPage or 1
  maxPages         = maxPages or 1
  viewActionType   = viewActionType or REPORT_TYPE_NAME
  viewAction       = viewAction or 1
  viewActionReason = viewActionReason or 1
  viewTargetName   = _targetName or viewTargetName or ''
  viewComment      = _comment or viewComment or ''
  viewState        = viewState or REPORT_STATE_UNDONE
  viewType         = viewType or REPORT_TYPE_ALL
  viewReason       = viewReason or 0

  g_ui.importStyle('ruleviolationview')
  rvViewWindow = g_ui.createWidget('RVViewWindow', rootWidget)
  rvViewWindow:raise()
  rvViewWindow:lock()
  rvViewActionButton = rvViewWindow:getChildById('rvViewActionButton')
  rvViewTypeActionComboBox = rvViewWindow:getChildById('rvViewTypeActionComboBox')
  rvViewActionComboBox = rvViewWindow:getChildById('rvViewActionComboBox')
  rvViewActionReasonComboBox = rvViewWindow:getChildById('rvViewActionReasonComboBox')
  rvViewCommentMultilineTextEdit = rvViewWindow:getChildById('rvViewCommentMultilineTextEdit')
  rvViewList = rvViewWindow:getChildById('rvViewList')
  rvViewPage = rvViewWindow:getChildById('rvViewPage')
  rvViewRowsPerPageLabel = rvViewWindow:getChildById('rvViewRowsPerPageLabel')
  rvViewRowsPerPageOptionScrollbar = rvViewWindow:getChildById('rvViewRowsPerPageOptionScrollbar')
  rvViewStateComboBox = rvViewWindow:getChildById('rvViewStateComboBox')
  rvViewTypeComboBox = rvViewWindow:getChildById('rvViewTypeComboBox')
  rvViewReasonComboBox = rvViewWindow:getChildById('rvViewReasonComboBox')

  rvViewList.onChildFocusChange = GameRuleViolation.listOnChildFocusChange
  GameRuleViolation.updateRowsPerPageLabel(GameRuleViolation.getRowsPerPage())

  -- Action Type ComboBox
  for _type = REPORT_TYPE_NAME, REPORT_TYPE_VIOLATION do
    rvViewTypeActionComboBox:addOption(types[_type])
  end
  rvViewTypeActionComboBox.onOptionChange = GameRuleViolation.onViewChangeActionType
  rvViewTypeActionComboBox:setOption(types[viewActionType])
  GameRuleViolation.onViewChangeActionType(rvViewTypeActionComboBox) -- Actions ComboBox
  GameRuleViolation.rvViewDetachRow() -- Target Name Text Edit

  -- Action ComboBox
  rvViewActionComboBox.onOptionChange = GameRuleViolation.onViewChangeAction
  rvViewActionComboBox:setOption(actions[viewActionType][viewAction].title)

  -- Action Reason ComboBox
  rvViewActionReasonComboBox.onOptionChange = GameRuleViolation.onViewChangeActionReason
  rvViewActionReasonComboBox:setOption(reasons[viewActionType][viewActionReason].title)
  GameRuleViolation.onViewChangeActionReason(rvViewActionReasonComboBox)

  -- Action Target Name MultilineTextEdit
  if rvViewTargetNameTextEdit then
    rvViewTargetNameTextEdit:setText(viewTargetName)
  end

  -- Action Comment MultilineTextEdit
  rvViewCommentMultilineTextEdit:setText(viewComment)

  -- State ComboBox
  rvViewStateComboBox:addOption(states[REPORT_STATE_UNDONE])
  for state = REPORT_STATE_NEW, REPORT_STATE_DONE do
    rvViewStateComboBox:addOption(states[state])
  end
  rvViewStateComboBox.onOptionChange = GameRuleViolation.onViewChangeState
  rvViewStateComboBox:setOption(states[viewState])

  -- Type ComboBox
  rvViewTypeComboBox:addOption(types[REPORT_TYPE_ALL])
  for _type = REPORT_TYPE_NAME, REPORT_TYPE_VIOLATION do
    rvViewTypeComboBox:addOption(types[_type])
  end
  rvViewTypeComboBox.onOptionChange = GameRuleViolation.onViewChangeType
  rvViewTypeComboBox:setOption(types[viewType])
  GameRuleViolation.onViewChangeType(rvViewTypeComboBox)

  -- Reason ComboBox
  rvViewReasonComboBox.onOptionChange = GameRuleViolation.onViewChangeReason
  if viewType ~= REPORT_TYPE_ALL then
    rvViewReasonComboBox:setOption(reasons[viewType][viewReason].title)
  end

  GameRuleViolation.updatePage() -- Fill list
end

function GameRuleViolation.destroyRVViewWindow()
  if rvViewWindow then
    rvViewWindow:destroy()
  end

  rvViewWindow                     = nil
  rvViewActionButton               = nil
  rvViewTypeActionComboBox         = nil
  rvViewActionComboBox             = nil
  rvViewActionReasonComboBox       = nil
  rvViewActionTargetNameLabel      = nil
  rvViewTargetNameTextEdit         = nil
  rvViewCommentMultilineTextEdit   = nil
  rvViewList                       = nil
  rvViewPage                       = nil
  rvViewRowsPerPageLabel           = nil
  rvViewRowsPerPageOptionScrollbar = nil
  rvViewStateComboBox              = nil
  rvViewTypeComboBox               = nil
  rvViewReasonComboBox             = nil
end

function GameRuleViolation.clearViewWindow()
  viewPage         = 1
  maxPages         = 1
  viewActionType   = REPORT_TYPE_NAME
  viewAction       = 1
  viewActionReason = 0
  viewTargetName   = ''
  viewComment      = ''
  viewState        = REPORT_STATE_UNDONE -- New + Working
  viewType         = REPORT_TYPE_ALL
  viewReason       = 0

  rvViewPage:setText('1')
  GameRuleViolation.updateRowsPerPageLabel(GameRuleViolation.getRowsPerPage())

  rvViewTypeActionComboBox:setOption(types[viewActionType])
  rvViewActionComboBox:setOption(actions[viewActionType][viewAction].title)
  rvViewActionReasonComboBox:setOption(reasons[viewActionType][viewActionReason].title)
  if rvViewTargetNameTextEdit then
    rvViewTargetNameTextEdit:setText('')
  end
  rvViewCommentMultilineTextEdit:setText('')
  rvViewStateComboBox:setOption(states[viewState])
  rvViewTypeComboBox:setOption(types[viewType])
  if viewType ~= REPORT_TYPE_ALL then
    rvViewReasonComboBox:setOption(reasons[viewType][viewReason].title)
  end

  GameRuleViolation.updatePage() -- Fill list
end

function GameRuleViolation.openRow(row)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  if rvWindow and rvWindow:isVisible() then
    displayErrorBox(loc'${CorelibInfoError}', loc'${GameRuleViolationErrorCloseBeforeDo}')
    return
  end

  GameRuleViolation.showRuleViolationReportWindow(row.type, row.targetName, row.statement)
  if rvWindow then
    rvViewWindow:unlock()
    rvViewWindow:hide()

    rvWindow:lock()

    rvLabel:setText(f(loc'%s\n- ${GameRuleViolationInfoTime}: %s\n- ${GameRuleViolationInfoPlayerName}: %s', row:getText(), os.date('%Y %b %d %H:%M:%S', row.time), row.playerName))

    typeComboBox:setOption(reasons[row.type][row.reasonId].title)
    typeComboBox:setEnabled(false)
    if statementTextEdit then
      local rvStatementVerticalScrollBar = g_ui.createWidget('HorizontalScrollBar', rvWindow)
      rvStatementVerticalScrollBar:setId('rvStatementVerticalScrollBar')
      rvStatementVerticalScrollBar:setStep(5)
      rvStatementVerticalScrollBar.pixelsScroll = true
      rvStatementVerticalScrollBar:addAnchor(AnchorTop, 'statementTextEdit', AnchorBottom)
      rvStatementVerticalScrollBar:addAnchor(AnchorLeft, 'statementTextEdit', AnchorLeft)
      rvStatementVerticalScrollBar:addAnchor(AnchorRight, 'statementTextEdit', AnchorRight)
      if translationTextEdit then
        rvWindow:getChildById('translationLabel'):addAnchor(AnchorTop, 'rvStatementVerticalScrollBar', AnchorBottom)
      else
        rvWindow:getChildById('reasonLabel'):addAnchor(AnchorTop, 'rvStatementVerticalScrollBar', AnchorBottom)
      end
      statementTextEdit:setHorizontalScrollBar(rvStatementVerticalScrollBar)
    end
    if translationTextEdit then
      translationTextEdit:setText(row.translation)
      translationTextEdit:setEditable(false)

      local rvTranslationVerticalScrollBar = g_ui.createWidget('HorizontalScrollBar', rvWindow)
      rvTranslationVerticalScrollBar:setId('rvTranslationVerticalScrollBar')
      rvTranslationVerticalScrollBar:setStep(5)
      rvTranslationVerticalScrollBar.pixelsScroll = true
      rvTranslationVerticalScrollBar:addAnchor(AnchorTop, 'translationTextEdit', AnchorBottom)
      rvTranslationVerticalScrollBar:addAnchor(AnchorLeft, 'translationTextEdit', AnchorLeft)
      rvTranslationVerticalScrollBar:addAnchor(AnchorRight, 'translationTextEdit', AnchorRight)
      rvWindow:getChildById('reasonLabel'):addAnchor(AnchorTop, 'rvTranslationVerticalScrollBar', AnchorBottom)
      translationTextEdit:setHorizontalScrollBar(rvTranslationVerticalScrollBar)
    end
    commentMultilineTextEdit:setText(row.comment)
    commentMultilineTextEdit:setEditable(false)

    okButton:hide()
    cancelButton.onClick = function()
      if rvViewTargetNameTextEdit then
        viewTargetName = rvViewTargetNameTextEdit:getText()
      end

      viewComment = rvViewCommentMultilineTextEdit:getText()

      rvWindow:unlock()
      GameRuleViolation.destroyRuleViolationReportWindow()
      GameRuleViolation.showViewWindow()
      rvViewWindow:lock()
      GameRuleViolation.listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
    end
    rvWindow.onEscape = cancelButton.onClick
  end
end



function GameRuleViolation.onRVViewPageChange(self)
  local text   = self:getText()
  local number = tonumber(text) or 0
  if text:match('[^0-9]+') or number > maxPages then -- Pattern: Cannot have non numbers (Correct: '7', '777' | Wrong: 'A7', '-7')
    return self:setText(maxPages)
  elseif text:match('^[0]+[1-9]*') then -- Pattern: Cannot start with 0, except 0 itself (Correct: '0', '70' | Wrong: '00', '07')
    return self:setText(1)
  end
end

function GameRuleViolation.getRowsPerPage()
  return rvViewRowsPerPageOptionScrollbar and rvViewRowsPerPageOptionScrollbar:getValue() or 1
end

function GameRuleViolation.updateRowsPerPageLabel(value)
  if not rvViewRowsPerPageLabel then
    return
  end

  rvViewRowsPerPageLabel:setText(f(loc'${GameRuleViolationRowsPerPage}: ', value))
end

function GameRuleViolation.onViewChangeState(comboBox, option)
  if option then
    local newViewState = nil
    for k, v in pairs(states) do
      if v == option then
        newViewState = k
        break
      end
    end

    if not newViewState then
      return
    end

    viewState = newViewState
  end
end

function GameRuleViolation.onViewChangeType(comboBox, option)
  if option then
    local newViewType = nil
    for k, v in pairs(types) do
      if v == option then
        newViewType = k
        break
      end
    end

    if not newViewType then
      return
    end

    viewType = newViewType
  end

  rvViewReasonComboBox:clearOptions()
  if viewType ~= REPORT_TYPE_ALL then
    for k = 0, #reasons[viewType] do
      rvViewReasonComboBox:addOption(reasons[viewType][k].title)
    end
  end
end

function GameRuleViolation.onViewChangeReason(comboBox, option)
  if option then
    if viewType == REPORT_TYPE_ALL then
      return
    end

    local newViewReason = nil
    for k, v in pairs(reasons[viewType]) do
      if v.title == option then
        newViewReason = k
        break
      end
    end

    if not newViewReason then
      return
    end

    viewReason = newViewReason
  end
end

function GameRuleViolation.rvViewUpdatePage()
  local page = tonumber(rvViewPage:getText()) or 1
  if page < 1 or page > maxPages then
    return
  end

  viewPage = page
  GameRuleViolation.updatePage()
end

function GameRuleViolation.rvViewPreviousPage()
  viewPage = math.max(1, viewPage - 1)
  rvViewPage:setText(viewPage)
  GameRuleViolation.updatePage()
end

function GameRuleViolation.rvViewNextPage()
  viewPage = math.min(viewPage + 1, maxPages)
  rvViewPage:setText(viewPage)
  GameRuleViolation.updatePage()
end

function GameRuleViolation.updatePage()
  if not getWindowState() then
    return
  end

  sendUpdateSearch(viewType, viewReason, viewPage, GameRuleViolation.getRowsPerPage(), viewState)
end



local function updateReportRowTitle(row)
  row:setText(row.id .. '. [' .. states[row.state] .. ' | ' .. types[row.type] .. '] ' .. row.comment:sub(0, 35) .. (#row.comment > 35 and '...' or ''))
end

function GameRuleViolation.parseRuleViolationsReports(protocolGame, opcode, msg)
  local buffer = msg:getString()

  if not getWindowState() then
    return
  end

  -- Clear list
  local children = rvViewList:getChildren()
  for i = 1, #children do
    rvViewList:removeChild(children[i])
    children[i]:destroy()
  end

  local _buffer = string.split(buffer, ':::')
  if #_buffer ~= 2 then
    return
  end

  maxPages = tonumber(_buffer[1]) or 1
  maxPages = math.ceil(maxPages / GameRuleViolation.getRowsPerPage())

  local reports = string.split(_buffer[2], '::')
  for _, report in ipairs(reports) do
    local data = string.split(report, ':')
    local row = g_ui.createWidget('RVVRowLabel', rvViewList)
    row.id          = tonumber(data[1])
    row.state       = tonumber(data[2])
    row.time        = tonumber(data[3])
    row.type        = tonumber(data[4])
    row.playerId    = tonumber(data[5])
    row.targetName  = f('%s', data[6])
    row.statement   = f('%s', data[7])
    row.translation = f('%s', data[8])
    row.reasonId    = tonumber(data[9])
    row.comment     = f('%s', data[10])
    row.playerName  = f('%s', data[11])
    updateReportRowTitle(row)
    row.onDoubleClick = GameRuleViolation.openRow
  end

  GameRuleViolation.rvViewDetachRow()
  GameRuleViolation.listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end



-- For avoid multiple confirm windows
local confirmWindowLock = false
function GameRuleViolation.setConfirmWindowLock(lock)
  confirmWindowLock = lock
end

function GameRuleViolation.removeRow(rvViewList, row) -- After confirm button
  if not getWindowState() then
    return
  end

  sendRemoveRow(row)

  rvViewList:removeChild(row)
  row:destroy()

  GameRuleViolation.rvViewDetachRow()
  GameRuleViolation.listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end

function GameRuleViolation.rvViewRemoveRow()
  if not getWindowState() then
    return
  end

  local row = rvViewList:getFocusedChild()
  if not row then
    displayErrorBox(loc'${CorelibInfoError}', loc'${GameRuleViolationErrorNoRowSelected}')
    return
  end

  if not confirmWindowLock then
    local buttonCallback = function()
      if modules.game_ruleviolation then
        GameRuleViolation.removeRow(rvViewList, row)
        GameRuleViolation.setConfirmWindowLock(false)
      end
    end

    local onCancelCallback = function()
      if modules.game_ruleviolation then
        GameRuleViolation.setConfirmWindowLock(false)
      end
    end

    displayCustomBox(loc'${GameRuleViolationWarningTitle}', 'Are you sure that you want to remove the row id ' .. row.id .. '?', {{ text = 'Yes', buttonCallback = buttonCallback }}, 1, 'No', onCancelCallback, nil)
    GameRuleViolation.setConfirmWindowLock(true)
  end
end

function GameRuleViolation.rvViewSetReportState()
  if not getWindowState() then
    return
  end

  local err
  local row = rvViewList:getFocusedChild()
  if not row then
    err = loc'${GameRuleViolationErrorNoRowSelected}'
  elseif viewState == 255 then
    err = loc'${GameRuleViolationStateNotFound}'
  end
  if err then
    displayErrorBox(loc'${CorelibInfoError}', err)
    return
  end

  row.state = viewState
  sendUpdateState(row)
  updateReportRowTitle(row)

  GameRuleViolation.rvViewDetachRow()
  GameRuleViolation.listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end



function GameRuleViolation.rvViewDetachRow()
  rvViewList:focusChild(nil)

  if not rvViewTargetNameTextEdit or not rvViewTargetNameTextEdit:isVisible() then
    rvViewActionTargetNameLabel = g_ui.createWidget('Label', rvViewWindow)
    rvViewActionTargetNameLabel:setId('rvViewActionTargetNameLabel')
    rvViewActionTargetNameLabel:setText(loc'${GameRuleViolationLabelTargetName}:')
    rvViewActionTargetNameLabel:addAnchor(AnchorTop, 'rvViewActionReasonComboBox', AnchorBottom)
    rvViewActionTargetNameLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    rvViewActionTargetNameLabel:setMarginTop(5)

    rvViewTargetNameTextEdit = g_ui.createWidget('TextEdit', rvViewWindow)
    rvViewTargetNameTextEdit:setId('rvViewTargetNameTextEdit')
    rvViewTargetNameTextEdit:addAnchor(AnchorTop, 'rvViewActionReasonComboBox', AnchorBottom)
    rvViewTargetNameTextEdit:addAnchor(AnchorLeft, 'rvViewActionTargetNameLabel', AnchorRight)
    rvViewTargetNameTextEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
    rvViewTargetNameTextEdit:setMarginTop(3)
    rvViewTargetNameTextEdit:setMarginLeft(5)

    rvViewWindow:getChildById('commentLabel'):addAnchor(AnchorTop, 'rvViewTargetNameTextEdit', AnchorBottom)
  end
end

function GameRuleViolation.onViewChangeActionType(comboBox, option)
  if option then
    local newViewActionType = nil
    for k, v in pairs(types) do
      if v == option then
        newViewActionType = k
        break
      end
    end

    if not newViewActionType then
      return
    end

    viewActionType = newViewActionType
  end

  rvViewActionComboBox:clearOptions()
  for k = 1, #actions[viewActionType] do
    rvViewActionComboBox:addOption(actions[viewActionType][k].title)
  end

  rvViewActionReasonComboBox:clearOptions()
  for k = 0, #reasons[viewActionType] do
    rvViewActionReasonComboBox:addOption(reasons[viewActionType][k].title)
  end
end

function GameRuleViolation.onViewChangeAction(comboBox, option)
  if option then
    local newViewAction = nil
    for k, v in pairs(actions[viewActionType]) do
      if v.title == option then
        newViewAction = k
        break
      end
    end

    if not newViewAction then
      return
    end

    viewAction = newViewAction
  end
end

function GameRuleViolation.onViewChangeActionReason(comboBox, option)
  if option then
    local newViewActionReason = nil
    for k, v in pairs(reasons[viewActionType]) do
      if v.title == option then
        newViewActionReason = k
        break
      end
    end

    if not newViewActionReason then
      return
    end

    viewActionReason = newViewActionReason
  end

  rvViewActionReasonComboBox:setTooltip(viewActionType and viewActionReason >= 0 and reasons[viewActionType][viewActionReason] and reasons[viewActionType][viewActionReason].description or '', TooltipType.textBlock)
end

local function checkActionFields(row, targetName)
  local err
  if row and (not row.targetName or row.targetName == '') then
    err = loc'${GameRuleViolationErrorRowNoTarget}'
  elseif not row and (not targetName or targetName == '') then
    err = loc'${GameRuleViolationErrorRowNoContent}'
  elseif rvViewCommentMultilineTextEdit:getText():match(textPattern) then
    err = loc'${GameRuleViolationErrorActionCommentNotFormatted}'
  end
  if err then
    displayErrorBox(loc'${CorelibInfoError}', err)
    return false
  end
  return true
end

function GameRuleViolation.action(row, targetName)
  if not getWindowState() or not checkActionFields(row, targetName) then
    return
  end

  local action = actions[viewActionType][viewAction].actionType
  local days   = actions[viewActionType][viewAction].days or 0
  sendAddAction(viewActionType, targetName, viewActionReason, rvViewCommentMultilineTextEdit:getText(), action, days, row)

  if row then
    sendUpdateState(row, REPORT_STATE_DONE)
    updateReportRowTitle(row)
  end

  GameRuleViolation.updatePage()
end

function GameRuleViolation.rvViewAction()
  if not getWindowState() then
    return
  end

  local row = rvViewList:getFocusedChild()
  local targetName = not row and rvViewTargetNameTextEdit and rvViewTargetNameTextEdit:getText() or row and row.targetName or ''
  if not checkActionFields(row, targetName) then
    return
  end

  local message = f(loc'${GameRuleViolationActionMsgAdd}', actions[viewActionType][viewAction].title, targetName)

  -- Notes
  local notes = ''
  if not row then
    notes = f(loc'%s\n- GameRuleViolationInfoNeedReport', notes)
  end
  if row then
    if row.state == REPORT_STATE_DONE then
      notes = f(loc'%s\n- GameRuleViolationMarkedAlready', notes, states[REPORT_STATE_DONE])
    end
    if viewActionType ~= row.type then
      notes = f(loc'%s\n- GameRuleViolationDiffType', notes, types[viewActionType], types[row.type])
    else
      if viewActionReason ~= row.reasonId then
        notes = f(loc'%s\n- GameRuleViolationDiffReason', notes)
      end
    end
  end
  if notes ~= '' then
    message = f(loc'%s\n\n${GameRuleViolationInfoImportant}:\n%s', message, notes)
  end

  if not confirmWindowLock then
    local buttonCallback = function()
      if modules.game_ruleviolation then
        GameRuleViolation.action(row, targetName)
        GameRuleViolation.setConfirmWindowLock(false)
      end
    end

    local onCancelCallback = function()
      if modules.game_ruleviolation then
        GameRuleViolation.setConfirmWindowLock(false)
      end
    end

    displayCustomBox(loc'${GameRuleViolationWarningTitle}', message, {{ text = loc'${CorelibInfoYes}', buttonCallback = buttonCallback }}, 1, loc'${CorelibInfoNo}', onCancelCallback, nil)
    GameRuleViolation.setConfirmWindowLock(true)
  end
end
