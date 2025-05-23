*&---------------------------------------------------------------------*
*& Report ZCBS8_ACC_QUE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcbs8_acc_que.
TABLES:t001.
DATA: gt_fldct TYPE lvc_t_fcat,
      gs_slayt TYPE lvc_s_layo,
      gs_varnt TYPE disvariant,
      gv_repid TYPE sy-repid.
DATA: BEGIN OF gs_out.
        INCLUDE STRUCTURE zscbs8_pub_re0_data_list.
DATA: sel,
      END OF gs_out.
DATA:gt_out LIKE TABLE OF gs_out.
DATA:BEGIN OF lt_bukrs OCCURS 0,
       bukrs TYPE t001-bukrs,
     END OF lt_bukrs.
DATA cl_document TYPE REF TO cl_dd_document.
INCLUDE zcbs8_pub.
DATA:t_ztconf_epic_01 TYPE TABLE OF ztconf_epic_01.


DEFINE mcr_html_field.
  g_text = &3.
  CALL METHOD document->add_text
    EXPORTING
      text         = g_text
      sap_emphasis = &2.
  CALL METHOD document->add_gap
    EXPORTING
      width = &1.
END-OF-DEFINITION.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE btxt1.
  SELECT-OPTIONS:s_bukrs  FOR t001-bukrs MEMORY ID bkr."公司代码
*                 s_acc_no FOR input_aq-account_no. "交易账号
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN OUTPUT.
  btxt1 = '数据筛选'(t01).

AT SELECTION-SCREEN. "PAI
  CASE sy-ucomm.
    WHEN 'ONLI'.
*      PERFORM auth_check.
  ENDCASE.

INITIALIZATION.

START-OF-SELECTION.
  PERFORM auth_check.
  PERFORM savelog(zreplog) USING sy-repid '' IF FOUND.
  PERFORM getdata.
  PERFORM updatelog(zreplog) IF FOUND.
  PERFORM outdata.

*&---------------------------------------------------------------------*
*&      Form  auth_check
*&---------------------------------------------------------------------*
FORM auth_check.
  DATA:lv_msg TYPE char50.
  SELECT bukrs
    INTO TABLE lt_bukrs
    FROM t001
   WHERE bukrs IN s_bukrs.
  SELECT *
    FROM ztconf_epic_01
    WHERE bukrs IN @s_bukrs
    ORDER BY zyhzh
    INTO CORRESPONDING FIELDS OF TABLE @t_ztconf_epic_01.
  LOOP AT lt_bukrs.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
            ID 'ACTVT' DUMMY
            ID 'BUKRS' FIELD lt_bukrs-bukrs.

    IF sy-subrc <> 0 .
      lv_msg = '对不起，您没有公司代码' && lt_bukrs-bukrs && '的权限'.
      MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
      STOP.
    ENDIF.
    CLEAR:lt_bukrs.
  ENDLOOP.
  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD sy-tcode.
  IF sy-subrc NE 0.
    MESSAGE e000(oo) WITH '无事务码权限:'(m02) sy-tcode.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& getdata
*&---------------------------------------------------------------------*
FORM getdata.
  CLEAR:gt_out,input_aq,output_aq_out,rtype8,rtmsg8.
  LOOP AT lt_bukrs.
    APPEND INITIAL LINE TO input_aq-unit_code_list ASSIGNING FIELD-SYMBOL(<u>).
    <u> = lt_bukrs-bukrs.
  ENDLOOP.
  PERFORM getdata(zpub_data) USING 'CBS_VER' CHANGING cbs_ver.

  CALL FUNCTION 'ZFM_CBS8_ACC_QUE'
    EXPORTING
      input  = input_aq
    IMPORTING
      output = output_aq_out
*     OUTPUTSTR       =
      rtype  = rtype8
      rtmsg  = rtmsg8
*     BODY   =
    .
  MOVE-CORRESPONDING output_aq_out-data-list TO gt_out.
  IF gt_out IS INITIAL.
    MESSAGE s000(oo) WITH rtmsg8.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
* outdata
*---------------------------------------------------------------------*
FORM outdata.
  gv_repid        = sy-repid.
  gs_slayt-zebra  = 'X'.
  gs_slayt-box_fname  = 'SEL'.
  gs_varnt-report = sy-repid.
  gs_varnt-handle = 1.

  CHECK gt_out IS NOT INITIAL.
  DATA dfies_tab LIKE TABLE OF dfies WITH HEADER LINE.
  CLEAR:gt_fldct.
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = 'ZSCBS8_PUB_RE0_DATA_LIST'
*     FIELDNAME      = ' '
      langu          = sy-langu
*     LFIELDNAME     = ' '
*     ALL_TYPES      = ' '
*     GROUP_NAMES    = ' '
*     UCLEN          =
*     DO_NOT_WRITE   = ' '
* IMPORTING
*     X030L_WA       =
*     DDOBJTYPE      =
*     DFIES_WA       =
*     LINES_DESCR    =
    TABLES
      dfies_tab      = dfies_tab[]
*     FIXED_VALUES   =
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  LOOP AT dfies_tab.
    IF dfies_tab-fieldname = 'MANDT'.
      CONTINUE.
    ENDIF.
    CASE dfies_tab-fieldname.
      WHEN 'VBELN'.

      WHEN OTHERS.
        PERFORM catset TABLES gt_fldct USING:
              dfies_tab-fieldname dfies_tab-tabname dfies_tab-fieldname dfies_tab-fieldtext.
    ENDCASE.
  ENDLOOP.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      it_fieldcat_lvc             = gt_fldct
      i_save                      = 'A'
      is_variant                  = gs_varnt
      is_layout_lvc               = gs_slayt
      i_callback_program          = gv_repid
      i_callback_user_command     = 'USER_COMMAND'
      i_callback_pf_status_set    = 'SET_STATUS'
      i_callback_html_top_of_page = 'HTML_TOP_OF_PAGE'
      i_html_height_top           = 7
      i_html_height_end           = 7
    TABLES
      t_outtab                    = gt_out.
ENDFORM.
FORM html_top_of_page USING document TYPE REF TO cl_dd_document.
  DESCRIBE TABLE gt_out LINES DATA(line).
  DATA: g_text TYPE sdydo_text_element.
  CALL METHOD document->initialize_document.
  SEARCH document->html_table FOR document->cursor.
  IF sy-subrc = 0.
    mcr_html_field 0 'Strong' '条目数:'.
    mcr_html_field 1 'Key' line.
*    CALL METHOD document->new_line.
*    mcr_html_field 0 'Strong' '分摊状态:'.
*    mcr_html_field 1 'Key' rtype.
*    mcr_html_field 0 'Strong' '分摊结果:'.
*    mcr_html_field 1 'Key' rtmsg.
*    mcr_html_field 0 'Strong' '分摊凭证:'.
*    mcr_html_field 1 'Key' mblnr.
*    mcr_html_field 0 'Strong' '分摊凭证年:'.
*    mcr_html_field 1 'Key' mjahr.
  ENDIF.
  CHECK cl_document IS INITIAL.
  cl_document = document.
ENDFORM. "HTML_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*& set_status
*&---------------------------------------------------------------------*
FORM set_status USING pt_extab TYPE slis_t_extab ##CALLED.
  SET PF-STATUS 'STD_FULL' EXCLUDING pt_extab.
ENDFORM.

*&--------------------------------------------------------------------*
*& ALV user_command
*&--------------------------------------------------------------------*
FORM user_command USING pv_ucomm TYPE sy-ucomm ##CALLED
                        pv_field TYPE slis_selfield.

*  READ TABLE gt_out INTO gs_out INDEX pv_field-tabindex.
  CASE pv_ucomm.
    WHEN '&IC1'.

    WHEN 'TCLIP'.
      PERFORM alvtoclip IN PROGRAM zpubform IF FOUND TABLES gt_out USING 'X'.
    WHEN 'REFRE'.
      PERFORM getdata.
      pv_field-row_stable = 'X'.
      pv_field-col_stable = 'X'.
      pv_field-refresh    = 'X'.
    WHEN 'BC'.
      PERFORM bc.
  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
* set fieldcat
*---------------------------------------------------------------------*
FORM catset TABLES t_fldcat
            USING pv_field pv_reftab pv_reffld pv_text.
  DATA: ls_fldcat TYPE lvc_s_fcat.

  ls_fldcat-fieldname =  pv_field.    "字段名
  ls_fldcat-scrtext_l =  pv_text.     "长描述
  ls_fldcat-scrtext_S =  pv_text.     "长描述
  ls_fldcat-scrtext_m =  pv_text.     "长描述
  ls_fldcat-selddictxt =  pv_text.    "布局
  ls_fldcat-coltext   =  pv_text.     "列描述
  ls_fldcat-ref_table =  pv_reftab.   "参考表名
  ls_fldcat-ref_field =  pv_reffld.   "参考字段名
  ls_fldcat-col_opt   = 'A'.          "自动优化列宽

  CASE ls_fldcat-fieldname.
    WHEN 'GSMNG'.
      ls_fldcat-qfieldname = 'MEINS'.
      ls_fldcat-no_zero    = 'X'.
    WHEN 'MENGE'.
      ls_fldcat-qfieldname = 'MEINS'.
      ls_fldcat-no_zero    = 'X'.
    WHEN 'WRBTR'.
      ls_fldcat-cfieldname = 'WAERS'.
    WHEN 'LIFNR' OR 'AUFNR' OR 'KUNNR'.
      ls_fldcat-edit_mask = '==ALPHA'.
    WHEN 'MATNR' OR 'IDNRK'.
      ls_fldcat-edit_mask = '==MATN1'.
    WHEN 'MEINS' .
      ls_fldcat-edit_mask = '==CUNIT'.
  ENDCASE.

  APPEND ls_fldcat TO t_fldcat.
  CLEAR ls_fldcat.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form bc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM bc .
  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<g>) WHERE sel = 'X'.
    READ TABLE t_ztconf_epic_01 ASSIGNING FIELD-SYMBOL(<t>) WITH KEY zyhzh = <g>-account_no.
    IF sy-subrc EQ 0.
      <t>-bukrs              = <g>-unit_code.
      <t>-banktype           = <g>-bank_type.
*<t>-TRANSMASTERID_H    = <g>-
*<t>-TRANSMASTERID      = <g>-
*<t>-OFFSHORESIGN       = <g>-
      <t>-banka              = <g>-account_name.
*<t>-CONTACTTEL         = <g>-
    ELSE.
      INSERT INITIAL LINE INTO TABLE t_ztconf_epic_01 ASSIGNING FIELD-SYMBOL(<tc>).
      <tc>-zyhzh              = <g>-account_no.
      <tc>-bukrs              = <g>-unit_code.
      <tc>-banktype           = <g>-bank_type.
*<tc>-TRANSMASTERID_H    = <g>-
*<tc>-TRANSMASTERID      = <g>-
*<tc>-OFFSHORESIGN       = <g>-
      <tc>-banka              = <g>-account_name.
*<tc>-CONTACTTEL         = <g>-
    ENDIF.
  ENDLOOP.
  IF sy-subrc NE 0.
    MESSAGE e000(oo) WITH '请选择要保存的数据'.
  ELSE.
    MODIFY ztconf_epic_01 FROM TABLE t_ztconf_epic_01.
    IF sy-subrc EQ 0.
      COMMIT WORK.
      MESSAGE s000(oo) WITH '保存成功'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE e000(oo) WITH '保存失败'.
    ENDIF.
  ENDIF.
ENDFORM.
