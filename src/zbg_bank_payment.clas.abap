CLASS zbg_bank_payment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
   INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .
    INTERFACES if_serializable_object .

     METHODS constructor
      IMPORTING
        iv_bill  TYPE  zde_out_payment
        iv_m_ind TYPE abap_boolean
        iv_comp type I_AccountingDocumentJournal-CompanyCode
        iv_fisc type I_AccountingDocumentJournal-FiscalYear.



  PROTECTED SECTION.
  DATA : im_bill TYPE  zde_out_payment,
           im_ind  TYPE abap_boolean,
           im_comp type I_AccountingDocumentJournal-CompanyCode,
            im_fisc type I_AccountingDocumentJournal-FiscalYear .


    METHODS modify
      RAISING
        cx_bgmc_operation.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZBG_BANK_PAYMENT IMPLEMENTATION.


 METHOD constructor.
    im_bill = iv_bill.
    im_ind  = iv_m_ind.
    im_comp = iv_comp.
    im_fisc = iv_fisc.

  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    modify( ).
  ENDMETHOD.


METHOD modify.
  DATA : wa_data TYPE zdb_bank_pay_n.
  DATA lo_pfd TYPE REF TO zcl_bank_payment.



  SELECT SINGLE base64
    FROM zdb_bank_pay_n
    WHERE accountingdocument = @im_bill
      AND companycode        = @im_comp
      AND fiscalyear         = @im_fisc
    INTO @DATA(lv_existing_b64).

  IF sy-subrc = 0 AND lv_existing_b64 IS NOT INITIAL.


    DATA(lv_current_user) = cl_abap_context_info=>get_user_technical_name( ).

    SELECT SINGLE name
      FROM zdb_bank_auth
      WHERE name = @lv_current_user
      INTO @DATA(lv_auth).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

  ENDIF.

  CREATE OBJECT lo_pfd.

  lo_pfd->get_pdf_64(
    EXPORTING
      io_accountingdoc = im_bill
      io_compcode      = im_comp
      io_fiscal        = im_fisc
      io_mind          = im_ind
    RECEIVING
      pdf_64           = DATA(pdf_64)
  ).
if pdf_64 is noT inITIAL.
  wa_data-accountingdocument = im_bill.
  wa_data-companycode        = im_comp.
  wa_data-fiscalyear         = im_fisc.
  wa_data-base64             = pdf_64.
  wa_data-m_ind              = im_ind.

  MODIFY zdb_bank_pay_n FROM @wa_data.
endIF.

ENDMETHOD.
ENDCLASS.
