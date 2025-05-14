class ZCL_CBS8 definition
  public
  final
  create public .

public section.

  data URL_COMM type ZURL_COMM read-only .
  data URL_SIGN type ZURL_SIGN read-only .

  methods CONSTRUCTOR .
  methods POST2CBS8
    importing
      value(BODY) type STRING
      value(CBS8_SUFFIX) type STRING
    exporting
      value(OUTPUT) type STRING
      value(RTMSG) type STRING
      value(STATUS) type I .
protected section.
private section.

  methods GET_CHECK_CODE
    importing
      value(BODY) type STRING
    exporting
      value(RTYPE) type BAPI_MTYPE
      value(RTMSG) type BAPI_MSG
      value(CHECKCODE) type STRING .
ENDCLASS.



CLASS ZCL_CBS8 IMPLEMENTATION.


  METHOD constructor.
    SELECT SINGLE
      url_comm,
      url_sign
      FROM ztconf_epic_url
      WHERE cbs_ver = 'CBS8'
      INTO ( @me->url_comm,@me->url_sign )
      .
  ENDMETHOD.


  METHOD get_check_code.
    DATA:bodyx TYPE xstring.
    IF me->url_sign IS INITIAL OR me->url_comm IS INITIAL.
      rtype = 'E'.
      rtmsg = '请配置CBS8的端口和密钥'.
      RETURN.
    ENDIF.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = |{ me->url_sign }{ body }|
*       MIMETYPE       = ' '
*       ENCODING       =
      IMPORTING
        buffer = bodyx
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
    IF sy-subrc EQ 0.
      CALL METHOD cl_abap_zip=>crc32
        EXPORTING
          content = bodyx
        RECEIVING
          crc32   = DATA(crc32).
      bodyx = crc32.
      checkcode = bodyx.
      checkcode = |Z{ checkcode WIDTH = 8 PAD = '0' ALIGN = RIGHT CASE = UPPER }|.
      rtype = 'S'.
    ELSE.
      rtype = 'E'.
    ENDIF.
  ENDMETHOD.


  METHOD post2cbs8.
    TYPES:BEGIN OF ty_header,
            name  TYPE string,
            value TYPE string,
            cdata TYPE string,
            xdata TYPE xstring,
          END OF ty_header.
    DATA:t_header TYPE TABLE OF ty_header.
    CALL METHOD me->get_check_code
      EXPORTING
        body      = body
      IMPORTING
*       rtype     =
*       rtmsg     =
        checkcode = DATA(checkcode).
    APPEND INITIAL LINE TO t_header ASSIGNING FIELD-SYMBOL(<h>).
    <h>-name = 'checkcode'.
    <h>-value = checkcode.
    CALL METHOD zcl_dingtalk=>create_http_client
      EXPORTING
        input     = body
        url       = to_lower( |{ me->url_comm }{ cbs8_suffix }| )
*       username  =
*       password  =
        reqmethod = 'POST'
*       http1_1   = ABAP_TRUE
*       proxy     =
*       bodytype  = 'JSON'
        header    = t_header
      IMPORTING
        output    = output
        rtmsg     = rtmsg
        status    = status
        fields    = DATA(fields).
    CLEAR checkcode.
    CALL METHOD me->get_check_code
      EXPORTING
        body      = output
      IMPORTING
*       rtype     =
*       rtmsg     =
        checkcode = checkcode.
    LOOP AT fields ASSIGNING FIELD-SYMBOL(<f>).
      IF to_lower( <f>-name ) = 'checkcode'.
        DATA(value) = <f>-value.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF checkcode NE value.
      rtmsg = |CBS8返回的CRC32校验码[{ value }]与计算所得[{ checkcode }]不一致!!!|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
