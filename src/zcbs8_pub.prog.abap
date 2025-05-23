*&---------------------------------------------------------------------*
*& 包含               ZCBS8_PUB
*&---------------------------------------------------------------------*
DATA:cbs_ver       TYPE char5,
     "账户列表查询
     input_aq      TYPE zscbs8_aq,
     output_aq_out TYPE zscbs8_aq_out,
     "支付
     input_pac     TYPE zlcbs8_pac,
     w_input_pac   TYPE zscbs8_pac,
     output_pac    TYPE zscbs8_pac_out,
     "支付/代发/代扣列表查询
     input_q       TYPE zscs8_q,
     output_q      TYPE zscs8_q_out,
     "支付/代发/代扣详情查询
     input_d       TYPE zscs8_d,
     output_d      TYPE zscs8_d_out,
     "
     rtype8        TYPE bapi_mtype,
     rtmsg8        TYPE bapi_msg,
     ddtext        TYPE ddtext.

FORM domain_value_get  USING    p_data
                         CHANGING p_domvalue_l.
  DATA:it_dd07v TYPE TABLE OF dd07v WITH HEADER LINE,
       wa_dd01t TYPE dd01t.
  CLEAR p_domvalue_l.
  CHECK p_data IS NOT INITIAL.
  TRY.
      DATA(realname) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( p_data ) )->get_relative_name( ).
    CATCH cx_root INTO DATA(exc).
      DATA(exct) = exc->get_text( ).
      RETURN.
  ENDTRY.
  SELECT SINGLE
    dd04l~domname,
    dd01t~ddtext
    FROM dd04l
    JOIN dd01t ON dd04l~domname = dd01t~domname AND dd01t~ddlanguage = @sy-langu AND dd01t~as4local = 'A'
    WHERE rollname = @realname
    AND dd04l~as4local = 'A'
    INTO @DATA(wa_dom).
  CHECK wa_dom IS NOT INITIAL.

  PERFORM getdomain(zpubform) TABLES it_dd07v USING wa_dom-domname.
  CHECK it_dd07v[] IS NOT INITIAL.
  READ TABLE it_dd07v WITH KEY domvalue_l = p_data.
  IF sy-subrc EQ 0.
    p_domvalue_l = it_dd07v-ddtext.
  ENDIF.
ENDFORM.
