FUNCTION zfm_cbs8_tra_det_que.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(INPUT) TYPE  ZSCBS8_TDQ
*"  EXPORTING
*"     VALUE(OUTPUT) TYPE  ZSCBS8_TDQ_OUT
*"     VALUE(OUTPUTSTR) TYPE  STRING
*"     VALUE(RTYPE) TYPE  BAPI_MTYPE
*"     VALUE(RTMSG) TYPE  BAPI_MSG
*"     VALUE(BODY) TYPE  STRING
*"----------------------------------------------------------------------
  zfmdatasave1 ''.
  zfmdatasave2 'B'.
  COMMIT WORK.
  CLEAR:output,outputstr,rtype,rtmsg,body.
  CREATE OBJECT cl_cbs8.
  CHECK cl_cbs8 IS BOUND.
  body = /ui2/cl_json=>serialize( data = input  compress = abap_false pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
  CALL METHOD cl_cbs8->post2cbs8
    EXPORTING
      body        = body
      cbs8_suffix = '/openapi/account/openapi/v1/transaction-detail/query'
    IMPORTING
      output      = outputstr
      rtmsg       = DATA(msg)
      status      = DATA(status).
  .
  /ui2/cl_json=>deserialize( EXPORTING json = outputstr  pretty_name = /ui2/cl_json=>pretty_mode-camel_case CHANGING data = output ).
  IF output-code = '0' AND msg NS '不一致!!!'.
    rtype = 'S'.
    rtmsg = '交易明细查询成功'.
  ELSE.
    rtype = 'E'.
    rtmsg = |交易明细查询失败:[{ output-msg }],http响应状态码[{ status }],http响应消息[{ msg }]|.
  ENDIF.
  FREE cl_cbs8.
  zfmdatasave2 'R'.

ENDFUNCTION.
