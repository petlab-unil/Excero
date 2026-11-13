//
//  Constants.swift
//  excero
//
//  Created by Alessandro on 03.05.24.
//

import Foundation

enum ExperimentalConditionAcronyms: String {
    case HUM = "HUM"
    case SEP = "SEP"
    case CON = "CON"
    case BASE = "BASE"
}

enum AvatarPieceGroup: String {
    case BODY = "body"
    case HAIRS = "hairs"
    case HEAD = "head"
    case TOP = "top"
    case LEGS = "legs"
    case SHOES = "shoes"
}

struct Constants {
    static let IS_APP_DEV_MODE: Bool = false
    static let DEFAULT_STEP_GOAL: Int = 70000
    static let BASE_API_URL: String = "INSERT URL TO API"
    static let PASSWORD_RESET_LINK: String = "INSERT URL TO PASSWORD RESET PAGE"
    static let DEFAULT_PRIMARY_COLOR_LIGHT: String = "008DA5"
    static let DEFAULT_PRIMARY_COLOR_DARK: String = "008DA5"
    static let DEFAULT_ACCENT_COLOR_LIGHT: String = ""
    static let DEFAULT_ACCENT_COLOR_DARK: String = ""
    
    static let DEFAULT_TEXT_COLOR_LIGHT: String = "#000000"
    static let DEFAULT_TEXT_COLOR_DARK: String = "#FFFFFF"
    
    static let STEP_INDICATOR_BACKGROUND_COLOR_LIGHT: String = "F5F5F5"
    static let STEP_INDICATOR_BACKGROUND_COLOR_DARK: String = "404040"
    
    static let CHAT_BUBBLE_COLOR_AUTHOR_LIGHT: String = Constants.DEFAULT_PRIMARY_COLOR_LIGHT
    static let CHAT_BUBBLE_COLOR_AUTHOR_DARK: String = Constants.DEFAULT_PRIMARY_COLOR_DARK
    static let CHAT_BUBBLE_COLOR_PEER_LIGHT: String = "ededed"
    static let CHAT_BUBBLE_COLOR_PEER_DARK: String = "8a8a8a"
    static let CHAT_SEND_ICON_LIGHT: String = "000000"
    static let CHAT_SEND_ICON_DARK: String = "FFFFFF"
    static let CHAT_SEP_LIMITED_ACCESS_MODE: Bool = false
    
    static let USER_DEFAULTS_SUITE_NAME: String = "group.ch.heg.silacci.excero.Notifications"
    static let USER_DEFAULTS_SAVED_AVATAR_TYPE: String = "ch.heg.silacci.excero.Constants.USER_DEFAULTS_SAVED_AVATAR_TYPE"
    static let USER_DEFAULTS_IS_FIRST_LAUNCH: String = "ch.heg.silacci.excero.Constants.USER_DEFAULT_IS_FIRST_LAUNCH"
    static let USER_DEFAULTS_AUTOCONNECT: String = "ch.heg.silacci.excero.Constants.USER_DEFAULT_AUTOCONNECT"
    static let USER_DEFAULTS_ACCOUNT_DEACTIVATED: String = "ch.heg.silacci.excero.Constants.USER_DEFAULTS_ACCOUNT_DEACTIVATED"
    
    static let PEER_AVATAR_SPRITE_PREVIEW: String = "ch.heg.silacci.excero.Constants.peer-avatar.png"
    static let USER_AVATAR_SPRITE_PREVIEW: String = "ch.heg.silacci.excero.Constants.user-avatar.png"
    
    static let SHOW_GOAL_SETTING_VIEW: Bool = false
    
    static let SHOW_DEBUG_DATA: Bool = false || IS_APP_DEV_MODE
    
    static let DEFAULTS_LAST_STEP_SYNCHDATE: String = "ch.heg.silacci.excero.Constants.DEFAULTS_LAST_STEP_SYNCHDATE"
    
    static let DELTA_TIME_STEPS_SYNCH: TimeInterval = TimeInterval(5 * 60) // In seconds
    
    static let TEXT_AUTH_ERROR: String = "La combinaison nom d'utilisateur et mot de passe est erronnée"
    
    static let URLSESSION_BG_IDENTIFIER: String = "ch.heg.silacci.excero.step_synch"
    
    static let PEER_STEPS_REFRESH_TIMEINTERVAL: TimeInterval = TimeInterval(60 * 1) // In seconds
}
