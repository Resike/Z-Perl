-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "koKR" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFF우클릭|r 으로 버튼을 드래그해서 이동가능합니다."
L["MINIMAP_HELP5"] = "|c00FFFFFFALT|r : Z-Perl 메모리 사용량"
L["MINIMAP_HELP6"] = "|c00FFFFFF+SHIFT|r : 접속 후 Z-Perl 메모리 사용량"

L["MINIMENU_OPTIONS"]    = "설정"
L["MINIMENU_ASSIST"]     = "어시스트 창 표시"
L["MINIMENU_CASTMON"]    = "시전 현황 표시"
L["MINIMENU_RAIDAD"]     = "공격대 관리 표시"
L["MINIMENU_ITEMCHK"]    = "아이템 체커 표시"
L["MINIMENU_ROSTERTEXT"] = "명부 글자"

L["TYPE_NOT_SPECIFIED"] = "무엇인가"
L["TYPE_PET"]           = "소환수"
L["TYPE_BOSS"]          = "보스"
L["TYPE_RAREPLUS"]      = "희귀 정예"
L["TYPE_ELITE"]         = "정예"
L["TYPE_RARE"]          = "희귀"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]          = "검은 사원"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "하이잘 정상"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "얼음왕관 성채"
L["LOC_ZONE_KARAZHAN"]              = "카라잔"
L["LOC_ZONE_RUBY_SANCTUM"]          = "루비 성소"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "불뱀 제단"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "태양샘 고원"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "십자군의 시험장"
L["LOC_ZONE_ULDUAR"]                = "울두아르"

-- Status
L["LOC_DEAD"]         = "죽음"
L["LOC_GHOST"]        = "유령"
L["LOC_OFFLINE"]      = "오프라인"
L["LOC_RESURRECTED"]  = "부활"
L["LOC_SS_AVAILABLE"] = "영혼석 있음"
L["LOC_UPDATING"]     = "업데이트"
L["LOC_ACCEPTEDRES"]  = "수락됨"
L["RAID_GROUPSHORT"]  = "%d파"

L["LOC_NONEWATCHED"] = "발견된 사항 없음"

L["LOC_STATUSTIP"]     = "상태 강조: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "주기적인 치유",
	AGGRO = "어그로",
	HEAL = "치유 중",
	SHIELD = "보호막"
}

BINDING_HEADER_ZPERL                  = "Z-Perl 단축키 설정"
BINDING_NAME_ZPERL_TOGGLERAID         = "공격대 창 켜기/끄기"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "공격대 소환수창 켜기/끄기"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "설정창 열기/닫기"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "버프/디버프/없음 변경"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "시전가능/해제가능 변경"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "거리 측정 켜기/끄기"

L["KEY_NOTICE_RAID_BUFFANY"]      = "모든 버프/디버프 표시"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "오직 시전가능/해제가능 한 버프 또는 디버프만 표시"
L["KEY_NOTICE_RAID_BUFFS"]        = "공격대 버프 표시"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "공격대 디버프 표시"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "공격대 버프 표시안함"

L["DRAGHINT1"] = "창 비율을 조절하려면 |c00FFFFFF클릭|r하세요."
L["DRAGHINT2"] = "창 크기를 조절하려면 |c00FFFFFFSHIFT+클릭|r하세요."

L["RAID_TOOLTIP_WITHBUFF"]    = "버프있음: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "버프없음: (%s)"
