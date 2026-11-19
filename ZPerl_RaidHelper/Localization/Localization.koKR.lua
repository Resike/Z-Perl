-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "koKR" then return end

local L = ZPerl.L

L["TOOLTIP_ASSISTING"] = "플레이어 지원:"
L["TOOLTIP_HEALERS"]   = "나를 지원한 힐러:"
L["TOOLTIP_ALLONME"]   = "나를 타겟한 모두:"
L["TOOLTIP_ENEMYONME"] = "나를 타겟한 적:"
L["TOOLTIP_HELP"]      = "클릭시 실시간 보기"
L["TOOLTIP_PET"]       = "%s의 소환수"

L["BUTTON_TOGGLE_LABELS"]    = "토글 대상 라벨"
L["BUTTON_TOGGLE_MTTARGETS"] = "매인탱커의 대상과 대대상 토글"
L["BUTTON_TOGGLE_SHOWMT"]    = "메인탱커 보기 토글"
L["BUTTON_HELPER_PIN"]       = "창 고정"

L["XS_TARGET"] = "%s'의 대상"
L["NO_TARGET"] = "대상 없음"

L["TITLE_MT_LONG"]       = "MT 대상"
L["TITLE_WARRIOR_LONG"]  = "전사 대상"
L["TITLE_WARRIOR_SHORT"] = "탱커"

L["HELPER_NEEDPROMOTE"] = "메인탱커를 설정하려면 공격대장이나 승급자이어야 합니다."
L["HELPER_MASET"]       = "메인탱커 설정 %s"
L["HELPER_MACLEAR"]     = "메인 지원 |c00FF0000지움!"
L["HELPER_MAREMOVED"]   = "%s 메인 지원을 목록에서 찾지 못함 - 삭제!"
L["HELPER_MAREMOTESET"] = "%s 메인 지원을 지정 %s"

L["HELPER_FINDFOUND"]   = "정확한 목표를 찾기 위해 FIND를 사용. ('|c00007F00/zphelper find|r' 지움)."
L["HELPER_FINDCLEARED"] = "Find |c00FF0000지움!|r"
L["HELPER_FINDSET"]     = "Find 설정 %s. ('|c00007F00/zphelper find|r' 지움)."

L["AGGRO_PLAYER"]  = "- 어그로 -"
L["AGGRO_PET"]     = "- 소환수 어그로 -"
L["AGGRO_DRAGTIP"] = "어그로 경고의 위치 이동"
