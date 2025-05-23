*&---------------------------------------------------------------------*
*&  Report ZCONF_EPIC
*&---------------------------------------------------------------------*
*&  银企直联配置
*&---------------------------------------------------------------------*
REPORT zconf_cbs8.

TYPE-POOLS: slis.
TABLES sscrfields.
DATA: tcode(20) ,
      exttab TYPE slis_t_extab.
FIELD-SYMBOLS <fs>.

SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but01 USER-COMMAND ztfi_dealtype .
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but02 USER-COMMAND ztfi_oadept.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but03 USER-COMMAND ztconf_epic_01.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but04 USER-COMMAND ztconf_epic_02.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but05 USER-COMMAND ztconf_epic_ag.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but06 USER-COMMAND ztconf_epic_url.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but07 USER-COMMAND ztconf_epic_zh.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but08 USER-COMMAND ztconf_pycat_ch.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but09 USER-COMMAND ztconf_waers_cr.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but10 USER-COMMAND ztconf_cnaps.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but12 USER-COMMAND ztconf_tax_code.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but11 USER-COMMAND ztest_epic.
SELECTION-SCREEN: SKIP 2,PUSHBUTTON 12(40) but13 USER-COMMAND zcbs8accque.


INITIALIZATION.
  APPEND 'ONLI' TO exttab.
  APPEND 'SPOS' TO exttab.
  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
    EXPORTING
      p_status  = sy-pfkey
    TABLES
      p_exclude = exttab.

AT SELECTION-SCREEN OUTPUT.
  but01 = 'ZTFI_DEALTYPE   资金交易业务类型配置'.
  but02 = 'ZTFI_OADEPT     OA部门主数据映射表'.
  but03 = 'ZTCONF_EPIC_01  银企直联_交易客户号主数据维护表'.
  but04 = 'ZTCONF_EPIC_02  银企直联_银行类别配置表'.
  but05 = 'ZTCONF_EPIC_AG  付款安排配置表'.
  but06 = 'ZTCONF_EPIC_URL 银企直联_URL配置表'.
  but07 = 'ZTCONF_EPIC_ZH  默认付款账号配置表'.
  but08 = 'ZTCONF_PYCAT_CH 付款业务类型选择配置表'.
  but09 = 'ZTCONF_WAERS_CR 银企直联货币对照表'.
  but10 = 'ZTCONF_CNAPS    联行号描述维护表'.
  but11 = 'ZTEST_EPIC      前置机连通测试'.
  but12 = 'ZTCONF_TAX_CODE 税码-税率对应关系配置表'.
  but13 = 'ZCBS8ACCQUE CBS8账户列表同步'.

  LOOP AT SCREEN.
    CHECK screen-name(3) = 'BUT'.

    ASSIGN (screen-name) TO <fs>.
    SPLIT <fs> AT space INTO tcode <fs> .
    CONDENSE <fs>.

    CALL 'AUTH_CHECK_TCODE'
          ID 'TCODE' FIELD tcode.
    IF sy-subrc <> 0.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN.
  CHECK sscrfields-ucomm IS NOT INITIAL.
  CALL TRANSACTION sscrfields-ucomm .
