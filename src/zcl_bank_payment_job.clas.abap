CLASS zcl_bank_payment_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

TYPES: BEGIN OF ty_pending_doc,
             accountingdocument TYPE i_accountingdocumentjournal-accountingdocument, " BELNR
             companycode        TYPE i_accountingdocumentjournal-companycode,        " BUKRS
             fiscalyear         TYPE i_accountingdocumentjournal-fiscalyear,
             documentdate       type I_AccountingDocumentJournal-PostingDate,
             m_ind              type    abap_boolean,     " GJAHR
           END OF ty_pending_doc.

    TYPES tt_pending_doc TYPE STANDARD TABLE OF ty_pending_doc WITH EMPTY KEY.

    CLASS-METHODS fetch_pending_documents
      EXPORTING
        et_pending TYPE tt_pending_doc.

    CLASS-METHODS generate_and_store_pdfs
      IMPORTING
        it_pending      TYPE tt_pending_doc
      EXPORTING
        ev_job_message  TYPE string.

ENDCLASS.



CLASS ZCL_BANK_PAYMENT_JOB IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    " This allows you to test the job instantly by pressing F9 in Eclipse ADT
    DATA lt_pending   TYPE tt_pending_doc.
    DATA lv_message   TYPE string.

    zcl_bank_payment_job=>fetch_pending_documents(
      IMPORTING
        et_pending = lt_pending
    ).

    out->write( |Documents found needing Base64 layout generation: { lines( lt_pending ) }| ).

    IF lt_pending IS NOT INITIAL.
      zcl_bank_payment_job=>generate_and_store_pdfs(
        EXPORTING
          it_pending     = lt_pending
        IMPORTING
          ev_job_message = lv_message
      ).
      out->write( 'Processing complete.' ).
      out->write( lv_message ).
    ELSE.
      out->write( 'No missing accounting document print items found.' ).
    ENDIF.
  ENDMETHOD.


  METHOD fetch_pending_documents.

*SELECT accountingdocument,
*           companycode,
*           fiscalyear,
*           m_ind
*      FROM zi_bank_payment_n
*      WHERE m_ind IS NULL
*         OR m_ind <> 'X'
*      INTO TABLE @et_pending
*      UP TO 5000 ROWS.

  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).  " Today's date

  SELECT accountingdocument,
         companycode,
         fiscalyear,
         documentdate,
         m_ind
    FROM zi_bank_payment_n
    WHERE ( m_ind IS NULL OR m_ind <> 'X' )
      AND documentdate = @lv_today              " <-- Only today's docs
    INTO TABLE @et_pending
    UP TO 5000 ROWS.

  ENDMETHOD.


  METHOD generate_and_store_pdfs.
    DATA: lt_updates TYPE TABLE OF zdb_bank_pay_n,
          wa_data    TYPE zdb_bank_pay_n,
          lv_success TYPE i,
          lv_failed  TYPE i.

    DATA(lo_pdf) = NEW zcl_bank_payment( ).

    LOOP AT it_pending INTO DATA(ls_pending).

      DATA(lv_pdf64) = lo_pdf->get_pdf_64(
        io_accountingdoc = ls_pending-accountingdocument
        io_compcode      = ls_pending-companycode
        io_fiscal        = ls_pending-fiscalyear
        io_mind = ls_pending-m_ind
      ).

      IF lv_pdf64 IS INITIAL.
        lv_failed = lv_failed + 1.
        CONTINUE.
      ENDIF.

      CLEAR wa_data.
      if lv_pdf64 is noT iniTIAL.
      wa_data-accountingdocument = ls_pending-accountingdocument.
      wa_data-companycode        = ls_pending-companycode.
      wa_data-fiscalyear         = ls_pending-fiscalyear.
      wa_data-base64             = lv_pdf64.
      wa_data-m_ind              = abap_true.
      wa_data-pdf_ind            = abap_true.



      APPEND wa_data TO lt_updates.
      lv_success = lv_success + 1.

      " Write changes in array-packages of 100
      IF lines( lt_updates ) >= 100.
        MODIFY zdb_bank_pay_n FROM TABLE @lt_updates.
        COMMIT WORK AND WAIT.
        CLEAR lt_updates.
      ENDIF.

       endIF.

    ENDLOOP.

    " Catch final entries
    IF lt_updates IS NOT INITIAL.
      MODIFY zdb_bank_pay_n FROM TABLE @lt_updates.
      COMMIT WORK AND WAIT.
    ENDIF.

    ev_job_message = |Processed updates: { lv_success } successful, { lv_failed } failed.|.
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def, et_parameter_val.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    " This method is executed when the background system kicks off the Job
    DATA: application_log           TYPE REF TO if_bali_log,
          application_log_free_text TYPE REF TO if_bali_free_text_setter.

    DATA lt_pending TYPE tt_pending_doc.
    DATA lv_message TYPE string.

    TRY.
        zcl_bank_payment_job=>fetch_pending_documents(
          IMPORTING
            et_pending = lt_pending
        ).

        IF lt_pending IS NOT INITIAL.
          zcl_bank_payment_job=>generate_and_store_pdfs(
            EXPORTING
              it_pending     = lt_pending
            IMPORTING
              ev_job_message = lv_message
          ).
        ELSE.
          lv_message = 'No records required generation processing today.'.
        ENDIF.

        " Set up application log trace exactly like your email application setup
        application_log = cl_bali_log=>create_with_header(
          header = cl_bali_header_setter=>create(
            object    = 'XYZ'          " Replace with your actual log object
            subobject = 'INSERT'       " Replace with your actual log subobject
          )
        ).

        application_log_free_text = cl_bali_free_text_setter=>create(
          severity = if_bali_constants=>c_severity_information
          text     = CONV #( lv_message )
        ).

        application_log->add_item( item = application_log_free_text ).

        cl_bali_log_db=>get_instance( )->save_log(
          log                        = application_log
          assign_to_current_appl_job = abap_true
        ).

      CATCH cx_root INTO DATA(exception).
        " Gracefully handle runtime exception bugs
        DATA(lv_err) = exception->get_text( ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
