CLASS zcl_bank_payment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS get_pdf_64
      IMPORTING
                VALUE(io_accountingdoc) TYPE i_accountingdocumentjournal-accountingdocument
                VALUE(io_compcode)      TYPE   i_accountingdocumentjournal-companycode "<-write your input name and type
                VALUE(io_fiscal)        TYPE i_accountingdocumentjournal-fiscalyear
                valUE(io_mind)          tyPE abap_boolean
      RETURNING VALUE(pdf_64)           TYPE string..

    METHODS escape_xml
      IMPORTING
        iv_in         TYPE any
      RETURNING
        VALUE(rv_out) TYPE string.

    METHODS num2wordsd
      IMPORTING
        iv_num          TYPE string
        iv_major        TYPE string
        iv_minor        TYPE string
        iv_top_call     TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_words) TYPE string.

  PRIVATE SECTION.

    METHODS build_xml
      IMPORTING
        VALUE(io_accountingdoc) TYPE  i_accountingdocumentjournal-accountingdocument
        VALUE(io_compcode)      TYPE   i_accountingdocumentjournal-companycode "<-write your input name and type
        VALUE(io_fiscal)        TYPE i_accountingdocumentjournal-fiscalyear
         valUE(io_mind)          tyPE abap_boolean
      RETURNING
        VALUE(rv_xml)           TYPE string.
ENDCLASS.



CLASS ZCL_BANK_PAYMENT IMPLEMENTATION.


  METHOD escape_xml.

    rv_out = |{ iv_in }|.   " explicit conversion to STRING

    IF rv_out IS INITIAL.
      RETURN.
    ENDIF.

    " Replace must be done in order to avoid double-escaping
    REPLACE ALL OCCURRENCES OF '&' IN rv_out WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_out WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_out WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_out WITH '&quot;'.

  ENDMETHOD.


  METHOD num2wordsd.

    TYPES: BEGIN OF ty_map,
             num  TYPE i,
             word TYPE string,
           END OF ty_map.

    DATA: lt_map TYPE STANDARD TABLE OF ty_map,
          ls_map TYPE ty_map.

    DATA: lv_int  TYPE i,
          lv_dec  TYPE i,
          lv_inp1 TYPE string,
          lv_inp2 TYPE string.

    DATA: lv_result TYPE string,
          lv_decres TYPE string.

    IF iv_num IS INITIAL.
      RETURN.
    ENDIF.

    lt_map = VALUE #(
      ( num = 0  word = 'Zero' )
      ( num = 1  word = 'One' )
      ( num = 2  word = 'Two' )
      ( num = 3  word = 'Three' )
      ( num = 4  word = 'Four' )
      ( num = 5  word = 'Five' )
      ( num = 6  word = 'Six' )
      ( num = 7  word = 'Seven' )
      ( num = 8  word = 'Eight' )
      ( num = 9  word = 'Nine' )
      ( num = 10 word = 'Ten' )
      ( num = 11 word = 'Eleven' )
      ( num = 12 word = 'Twelve' )
      ( num = 13 word = 'Thirteen' )
      ( num = 14 word = 'Fourteen' )
      ( num = 15 word = 'Fifteen' )
      ( num = 16 word = 'Sixteen' )
      ( num = 17 word = 'Seventeen' )
      ( num = 18 word = 'Eighteen' )
      ( num = 19 word = 'Nineteen' )
      ( num = 20 word = 'Twenty' )
      ( num = 30 word = 'Thirty' )
      ( num = 40 word = 'Forty' )
      ( num = 50 word = 'Fifty' )
      ( num = 60 word = 'Sixty' )
      ( num = 70 word = 'Seventy' )
      ( num = 80 word = 'Eighty' )
      ( num = 90 word = 'Ninety' )
    ).

    SPLIT iv_num AT '.' INTO lv_inp1 lv_inp2.
    lv_int = lv_inp1.
    IF lv_inp2 IS NOT INITIAL.
      lv_dec = lv_inp2.
    ENDIF.

    " ---- INTEGER PART ----
    IF lv_int < 20.
      READ TABLE lt_map INTO ls_map WITH KEY num = lv_int.
      lv_result = ls_map-word.

    ELSEIF lv_int < 100.
      READ TABLE lt_map INTO ls_map WITH KEY num = ( lv_int DIV 10 ) * 10.
      lv_result = ls_map-word.
      IF lv_int MOD 10 > 0.
        READ TABLE lt_map INTO ls_map WITH KEY num = lv_int MOD 10.
        lv_result = |{ lv_result } { ls_map-word }|.
      ENDIF.

    ELSEIF lv_int < 1000.
      lv_result =
        num2wordsd( iv_num = |{ lv_int DIV 100 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Hundred'.

      IF lv_int MOD 100 > 0.
        lv_result = |{ lv_result } |
          && num2wordsd( iv_num = |{ lv_int MOD 100 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSEIF lv_int < 100000.
      lv_result =
        num2wordsd( iv_num = |{ lv_int DIV 1000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Thousand'.

      IF lv_int MOD 1000 > 0.
        lv_result = |{ lv_result } |
          && num2wordsd( iv_num = |{ lv_int MOD 1000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSE.
      lv_result =
        num2wordsd( iv_num = |{ lv_int DIV 100000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Lakh'.

      IF lv_int MOD 100000 > 0.
        lv_result = |{ lv_result } |
          && num2wordsd( iv_num = |{ lv_int MOD 100000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.
    ENDIF.

    " ---- APPEND CURRENCY ONLY ONCE ----
    rv_words = lv_result.

    IF iv_top_call = abap_true.
      IF lv_dec > 0.
        lv_decres =
          num2wordsd(
            iv_num      = |{ lv_dec }|
            iv_major    = iv_major
            iv_minor    = iv_minor
            iv_top_call = abap_false
          ).
        rv_words = |{ rv_words } { iv_major } and { lv_decres } { iv_minor } Only|.
      ELSE.
        rv_words = |{ rv_words } { iv_major } Only|.
      ENDIF.
    ENDIF.

    CONDENSE rv_words.
    TRANSLATE rv_words TO UPPER CASE.

  ENDMETHOD.


  METHOD get_pdf_64.

    DATA(lv_xml) = build_xml( io_accountingdoc = io_accountingdoc
    io_compcode = io_compcode
    io_fiscal = io_fiscal
    io_mind = io_mind ). " <- input param

    IF lv_xml IS INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = 'ZFI_BANK_PAYMENT/ZFI_BANK_PAYMENT'
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.
      pdf_64 = lv_result.


    ENDIF.

  ENDMETHOD.


  METHOD build_xml.

    DATA : lv_docdate      TYPE string,
           lv_total_debit  TYPE string,
           lv_total_credit TYPE string,
           ls_compname     TYPE string.

    SELECT
  SINGLE * FROM i_accountingdocumentjournal
  WHERE accountingdocument = @io_accountingdoc
  AND ledger = '0L'
  AND companycode = @io_compcode
  AND fiscalyear = @io_fiscal
  INTO  @DATA(ls_data).


    IF ls_data-companycode = '1000'.

      ls_compname = 'MPM Private Limited'.

    ELSEIF ls_data-companycode = '2000'.

      ls_compname = 'MPM Durrans Refracoat Pvt Ltd'.

    ENDIF.

    "refno

    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
    FROM i_accountingdocumentjournal
    WHERE clearingaccountingdocument = @io_accountingdoc
    AND ledgergllineitem = '000001'
     AND companycode = @io_compcode
      AND fiscalyear = @io_fiscal
    INTO @DATA(lv_refno).





    lv_docdate = |{ ls_data-DocumentDate+6(2) }.{ ls_data-DocumentDate+4(2) }.{ ls_data-DocumentDate+0(4) }|..
    DATA(lv_post) = |{ ls_data-postingdate+6(2) }.{ ls_data-postingdate+4(2) }.{ ls_data-postingdate+0(4) }|..


    SELECT SINGLE *
    FROM i_journalentry
    WHERE accountingdocument = @io_accountingdoc
     AND companycode = @io_compcode
      AND fiscalyear = @io_fiscal
    INTO @DATA(ls_currrate).

    SELECT * FROM
    i_accountingdocumentjournal
WHERE accountingdocument = @io_accountingdoc
AND ledger = '0L'
AND companycode = @io_compcode
AND fiscalyear = @io_fiscal
AND glaccount <> '0000880001'
and ( AccountingDocumentType = 'KZ'
or AccountingDocumentType = 'SK'
or AccountingDocumentType = 'MR'
or AccountingDocumentType = 'MP'
or AccountingDocumentType = 'DZ' )
INTO TABLE @DATA(lt_item1).

SORT lt_item1 BY LedgerGLLineItem ASCENDING.

    SELECT * FROM i_accountingdocumentjournal
     WHERE clearingaccountingdocument = @io_accountingdoc
       AND ledger = '0L'
       AND companycode = @io_compcode

       AND ( accountingdocumenttype = 'RE'
             OR accountingdocumenttype = 'IV'
             OR accountingdocumenttype = 'KR'
             OR accountingdocumenttype = 'VI'
             OR accountingdocumenttype = 'II'
             OR accountingdocumenttype = 'KZ' )
            AND AccountingDocument <> @io_accountingdoc
     INTO TABLE @DATA(lt_item2).

     SORT lt_item2 BY LedgerGLLineItem ASCENDING.

    SELECT SINGLE *
    FROM i_accountingdocumentjournal
    WHERE accountingdocument = @io_accountingdoc
    AND ledgergllineitem = '000001'
     AND companycode = @io_compcode
      AND fiscalyear = @io_fiscal
    INTO @DATA(lv_chk).

    DATA : lv_chkname TYPE i_accountingdocumentjournal-assignmentreference,
           lv_user    TYPE string,
           lv_id      TYPE string,
           lv_userid  TYPE string.

    lv_chkname = lv_chk-assignmentreference.

    lv_user = lv_chk-accountingdoccreatedbyuser.

    SELECT SINGLE userid,
        personfullname
        FROM i_businessuserbasic
        WHERE userid = @lv_chk-accountingdoccreatedbyuser
        INTO @DATA(wa_userid).

    lv_id = wa_userid-personfullname.

    lv_userid = |{ lv_id }\n{ lv_user }|.

    DATA: lv_supplier_name TYPE string,
          lv_account_name  TYPE string.

    CLEAR:  lv_supplier_name.

    SELECT SINGLE suppliername
         FROM i_supplier
         WHERE supplier = @ls_data-supplier
         INTO @lv_supplier_name.

    lv_account_name = lv_supplier_name.


    SELECT SINGLE *
    FROM i_journalentry
    WHERE accountingdocument = @io_accountingdoc
    INTO @DATA(wa_bank).

    IF wa_bank-transactioncode = 'FBCJ'.

      DATA(bank_name) = 'Cash'.

   ELSEIF wa_bank-transactioncode = 'FBDC_C014'
       OR wa_bank-transactioncode = 'FBDC_C024'.

      bank_name = 'Bank'.

   ENDIF.

    SELECT SINGLE * FROM
    i_accountingdocumentjournal
    WHERE ledgergllineitem = '000002'
    AND accountingdocument = @io_accountingdoc
    AND companycode = @io_compcode
     AND fiscalyear = @io_fiscal
    AND ledger = '0L'
    INTO @DATA(wa_narrtezt).


    SELECT SINGLE * FROM
    i_accountingdocumentjournal
    WHERE accountingdocument = @io_accountingdoc
    AND companycode = @io_compcode
     AND fiscalyear = @io_fiscal
    AND ledger = '0L'
    INTO @DATA(wa_kz).



*    DATA(lv_xml_header) = |<form1>| &&
*                          |<Design>| &&
*                          | <Subform1> | &&
*                          |<CurrentPage></CurrentPage>| &&
*                          |<PageCount></PageCount>| &&
*                          |<comopnamehed>{  me->escape_xml( ls_compname  ) }</comopnamehed>| &&
*                          |</Subform1>| &&
*                          |<Subform1>| &&
*                          |<bank>{ bank_name }</bank>| &&
*                          |</Subform1>| &&
*                          |<Subform2>| &&
*                          |<Subform2>| &&
*                          |<kz>{ wa_kz-accountingdocumenttype }</kz>| &&
*                          |<Bp>{ ls_data-accountingdocument }</Bp>| &&
*                          |<postingdate>{ lv_post }</postingdate>| &&
*                          |<Headertext>{  me->escape_xml( ls_data-accountingdocumentheadertext  ) }</Headertext>| &&
*                          |</Subform2>| &&
*                          |<Subform2>| &&
*                          |<refno>{  me->escape_xml( ls_data-assignmentreference  ) }</refno>| &&
*                          |<docdate>{ lv_docdate }</docdate>| &&
*                          |</Subform2>| &&
*                          |<Subform2>| &&
*                          |<currrate>{ ls_currrate-absoluteexchangerate }</currrate>| &&
*                          |<currency>{ ls_data-companycodecurrency }</currency>| &&
*                          |</Subform2>| &&
*                          |</Subform2>| &&
*                          |<Subform2>| &&
*                          |<Table1>| &&
*                          |<HeaderRow/>|.


DATA(lv_xml_header) =
  |<form1>| &&
  |<Design>| &&
  |<Subform1>| &&
  |<CurrentPage></CurrentPage>| &&
  |<PageCount></PageCount>| &&
  |<comopnamehed>{ zcl_escape_xml=>escape_xml( ls_compname ) }</comopnamehed>| &&
  |</Subform1>| &&
  |<Subform1>| &&
  |<bank>{ zcl_escape_xml=>escape_xml( bank_name ) }</bank>| &&
  |</Subform1>| &&
  |<Subform2>| &&
  |<Subform2>| &&
  |<kz>{ zcl_escape_xml=>escape_xml( wa_kz-accountingdocumenttype ) }</kz>| &&
  |<Bp>{ zcl_escape_xml=>escape_xml( ls_data-accountingdocument ) }</Bp>| &&
  |<postingdate>{ zcl_escape_xml=>escape_xml( lv_post ) }</postingdate>| &&
  |<Headertext>{ zcl_escape_xml=>escape_xml( ls_data-accountingdocumentheadertext ) }</Headertext>| &&
  |</Subform2>| &&
  |<Subform2>| &&
  |<refno>{ zcl_escape_xml=>escape_xml( ls_data-assignmentreference ) }</refno>| &&
  |<docdate>{ zcl_escape_xml=>escape_xml( lv_docdate ) }</docdate>| &&
  |</Subform2>| &&
  |<Subform2>| &&
  |<currrate>{ zcl_escape_xml=>escape_xml( |{ ls_currrate-absoluteexchangerate }| ) }</currrate>| &&
  |<currency>{ zcl_escape_xml=>escape_xml( ls_data-companycodecurrency ) }</currency>| &&
  |</Subform2>| &&
  |</Subform2>| &&
  |<Subform2>| &&
  |<Table1>| &&
  |<HeaderRow/>|.


    DATA(lv_xml_items) = ``.


    LOOP AT lt_item1 INTO DATA(ls_row1).

      DATA(lv_debit) = ls_row1-debitamountincocodecrcy.
      DATA(lv_credit) = abs( CONV decfloat34( ls_row1-creditamountincocodecrcy ) ).

      CLEAR:  lv_supplier_name.

      lv_total_debit = lv_total_debit + lv_debit.
      lv_total_credit = lv_total_credit + lv_credit.

      SELECT SINGLE suppliername
      FROM i_supplier
      WHERE supplier = @ls_row1-supplier
      INTO @lv_supplier_name.

      lv_account_name = lv_supplier_name.

      "ls_row1-GLAccountName


      IF ls_row1-financialaccounttype = 'S'.

        lv_xml_items = lv_xml_items &&                  "#EC CI_NOORDER

*                       |<Row1>| &&
*                       |<Account>{ ls_row1-glaccount }</Account>| &&
*                       |<actdesc>{ zcl_escape_xml=>escape_xml( ls_row1-glaccountname ) }</actdesc>| &&
*                       |<costcenter>{ ls_row1-costcenter }</costcenter>| &&
*                       |<Bussarea>{ ls_row1-profitcenter }</Bussarea>| &&
*                       |<cheque>{ me->escape_xml( ls_row1-assignmentreference ) }</cheque>| &&
*                       |<debitamt>{ ls_row1-debitamountincocodecrcy }</debitamt>| &&
*                       |<creditamnt>{ abs( ls_row1-creditamountincocodecrcy ) }</creditamnt>| &&
*                       |</Row1>|.

|<Row1>| &&
|<Account>{ zcl_escape_xml=>escape_xml( ls_row1-glaccount ) }</Account>| &&
|<actdesc>{ zcl_escape_xml=>escape_xml( ls_row1-glaccountname ) }</actdesc>| &&
|<costcenter>{ zcl_escape_xml=>escape_xml( ls_row1-costcenter ) }</costcenter>| &&
|<Bussarea>{ zcl_escape_xml=>escape_xml( ls_row1-profitcenter ) }</Bussarea>| &&
|<cheque>{ zcl_escape_xml=>escape_xml( ls_row1-assignmentreference ) }</cheque>| &&
|<debitamt>{ zcl_escape_xml=>escape_xml( |{ ls_row1-debitamountincocodecrcy }| ) }</debitamt>| &&
|<creditamnt>{ zcl_escape_xml=>escape_xml( |{ abs( ls_row1-creditamountincocodecrcy ) }| ) }</creditamnt>| &&
|</Row1>| .

      ELSEIF ls_row1-financialaccounttype = 'K'.        "#EC CI_NOORDER
        lv_xml_items = lv_xml_items &&                  "#EC CI_NOORDER

*                       |<Row1>| &&
*                       |<Account>{ ls_row1-supplier }</Account>| &&
*                       |<actdesc>{ zcl_escape_xml=>escape_xml( lv_account_name ) }</actdesc>| &&
*                       |<costcenter>{ ls_row1-costcenter }</costcenter>| &&
*                       |<Bussarea>{ ls_row1-profitcenter }</Bussarea>| &&
*                       |<cheque>{ me->escape_xml( lv_chkname ) }</cheque>| &&
*                       |<debitamt>{ ls_row1-debitamountincocodecrcy }</debitamt>| &&
*                       |<creditamnt>{ abs( ls_row1-creditamountincocodecrcy ) }</creditamnt>| &&
*                       |</Row1>|.

|<Row1>| &&
|<Account>{ zcl_escape_xml=>escape_xml( ls_row1-supplier ) }</Account>| &&
|<actdesc>{ zcl_escape_xml=>escape_xml( lv_account_name ) }</actdesc>| &&
|<costcenter>{ zcl_escape_xml=>escape_xml( ls_row1-costcenter ) }</costcenter>| &&
|<Bussarea>{ zcl_escape_xml=>escape_xml( ls_row1-profitcenter ) }</Bussarea>| &&
|<cheque>{ zcl_escape_xml=>escape_xml( lv_chkname ) }</cheque>| &&
|<debitamt>{ zcl_escape_xml=>escape_xml( |{ ls_row1-debitamountincocodecrcy }| ) }</debitamt>| &&
|<creditamnt>{ zcl_escape_xml=>escape_xml( |{ abs( ls_row1-creditamountincocodecrcy ) }| ) }</creditamnt>| &&
|</Row1>| .

   ELSEIF ls_row1-financialaccounttype = 'D'.   "#EC CI_NOORDER

        CLEAR lv_account_name.

        SELECT SINGLE customername
          FROM i_customer
          WHERE customer = @ls_row1-customer
          INTO @lv_account_name.

        lv_xml_items = lv_xml_items &&

*                       |<Row1>| &&
*                       |<Account>{ ls_row1-customer }</Account>| &&
*                       |<actdesc>{ zcl_escape_xml=>escape_xml( lv_account_name ) }</actdesc>| &&
*                       |<costcenter>{ ls_row1-costcenter }</costcenter>| &&
*                       |<Bussarea>{ ls_row1-profitcenter }</Bussarea>| &&
*                       |<cheque>{ me->escape_xml( lv_chkname ) }</cheque>| &&
*                       |<debitamt>{ ls_row1-debitamountincocodecrcy }</debitamt>| &&
*                       |<creditamnt>{ abs( ls_row1-creditamountincocodecrcy ) }</creditamnt>| &&
*                       |</Row1>|.

|<Row1>| &&
|<Account>{ zcl_escape_xml=>escape_xml( ls_row1-customer ) }</Account>| &&
|<actdesc>{ zcl_escape_xml=>escape_xml( lv_account_name ) }</actdesc>| &&
|<costcenter>{ zcl_escape_xml=>escape_xml( ls_row1-costcenter ) }</costcenter>| &&
|<Bussarea>{ zcl_escape_xml=>escape_xml( ls_row1-profitcenter ) }</Bussarea>| &&
|<cheque>{ zcl_escape_xml=>escape_xml( lv_chkname ) }</cheque>| &&
|<debitamt>{ zcl_escape_xml=>escape_xml( |{ ls_row1-debitamountincocodecrcy }| ) }</debitamt>| &&
|<creditamnt>{ zcl_escape_xml=>escape_xml( |{ abs( ls_row1-creditamountincocodecrcy ) }| ) }</creditamnt>| &&
|</Row1>| .

      ENDIF.

    ENDLOOP.

    DATA: lv_major TYPE string,
          lv_minor TYPE string.

    CLEAR: lv_major, lv_minor.
    CLEAR: lv_major, lv_minor.

    CASE ls_row1-transactioncurrency .

        " -------- RUPEE FAMILY --------
      WHEN 'INR'. lv_major = 'Rupee'.   lv_minor = 'Paise'.
      WHEN 'PKR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'NPR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'LKR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.
      WHEN 'SCR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.

        " -------- DOLLAR FAMILY --------
      WHEN 'USD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'AUD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'CAD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'NZD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'SGD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'HKD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.

        " -------- EURO --------
      WHEN 'EUR'. lv_major = 'Euro'.    lv_minor = 'Cent'.

        " -------- POUND --------
      WHEN 'GBP'. lv_major = 'Pound'.   lv_minor = 'Penny'.

        " -------- YEN / WON (NO MINOR) --------
      WHEN 'JPY'. lv_major = 'Yen'.     lv_minor = ''.
      WHEN 'KRW'. lv_major = 'Won'.     lv_minor = ''.

        " -------- MIDDLE EAST --------
      WHEN 'AED'. lv_major = 'Dirham'.  lv_minor = 'Fils'.
      WHEN 'SAR'. lv_major = 'Riyal'.   lv_minor = 'Halala'.
      WHEN 'QAR'. lv_major = 'Riyal'.   lv_minor = 'Dirham'.
      WHEN 'OMR'. lv_major = 'Rial'.    lv_minor = 'Baisa'.
      WHEN 'KWD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.
      WHEN 'BHD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.

        " -------- ASIA --------
      WHEN 'CNY'. lv_major = 'Yuan'.    lv_minor = 'Fen'.
      WHEN 'THB'. lv_major = 'Baht'.    lv_minor = 'Satang'.
      WHEN 'MYR'. lv_major = 'Ringgit'. lv_minor = 'Sen'.
      WHEN 'IDR'. lv_major = 'Rupiah'.  lv_minor = 'Sen'.
      WHEN 'PHP'. lv_major = 'Peso'.    lv_minor = 'Centavo'.

        " -------- AFRICA --------
      WHEN 'ZAR'. lv_major = 'Rand'.    lv_minor = 'Cent'.
      WHEN 'NGN'. lv_major = 'Naira'.   lv_minor = 'Kobo'.

        " -------- OTHERS / FALLBACK --------
      WHEN OTHERS.
        lv_major = ls_row1-transactioncurrency.
        lv_minor = ''.

    ENDCASE.

    " --- Middle Static XML (Transition from Table 1 to Table 2) ---
    DATA : lv_amt_inword TYPE string.
    lv_amt_inword = me->num2wordsd(
         iv_num   = lv_total_debit
         iv_major = lv_major
         iv_minor = lv_minor
       ).

    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
    FROM i_accountingdocumentjournal
    WHERE accountingdocument = @io_accountingdoc
    AND ledgergllineitem = '000001'
     AND companycode = @io_compcode
      AND fiscalyear = @io_fiscal
    INTO @DATA(wa_narr).


    lv_xml_items = lv_xml_items &&
*                  |<Row2>| &&
*                  |<debitotal>{ lv_total_debit }</debitotal>| &&
*                  |<credittotal>{ lv_total_credit }</credittotal>| &&
*                  |</Row2>| &&
*                  |</Table1>| &&
*                  |<Subform2>| &&
*                  |<amntinrs>{ lv_total_debit }</amntinrs>| &&
*                  |<amntinword>{ lv_amt_inword }</amntinword>| &&
*                  |<narra>{ me->escape_xml( wa_narrtezt-documentitemtext ) }</narra>| &&
*                  |</Subform2>| &&
*                  |</Subform2>| &&
*                  |</Design>| &&
*                  |<Subform3>| &&
*                  |<Table2>| &&
*                  |<HeaderRow/>|.

|<Row2>| &&
|<debitotal>{ zcl_escape_xml=>escape_xml( |{ lv_total_debit }| ) }</debitotal>| &&
|<credittotal>{ zcl_escape_xml=>escape_xml( |{ lv_total_credit }| ) }</credittotal>| &&
|</Row2>| &&
|</Table1>| &&
|<Subform2>| &&
|<amntinrs>{ zcl_escape_xml=>escape_xml( |{ lv_total_debit }| ) }</amntinrs>| &&
|<amntinword>{ zcl_escape_xml=>escape_xml( lv_amt_inword ) }</amntinword>| &&
|<narra>{ zcl_escape_xml=>escape_xml( wa_narrtezt-documentitemtext ) }</narra>| &&
|</Subform2>| &&
|</Subform2>| &&
|</Design>| &&
|<Subform3>| &&
|<Table2>| &&
|<HeaderRow/>|.

    " --- Loop for Table 2 ---

    DATA: lv_gross     TYPE p DECIMALS 2,
          lv_netamt    TYPE p DECIMALS 2,
          lv_deduction TYPE p DECIMALS 2,
          lv_paidamt   TYPE p DECIMALS 2,
          lv_diffamnt  TYPE p DECIMALS 2.   "for footer total (if needed)

    DATA: lv_deduction_disp TYPE string,
          lv_diffamt_disp   TYPE string.

    DATA: lv_total_gross TYPE  p DECIMALS 2,
          lv_total_net   TYPE p DECIMALS 2,
          lv_total_paid  TYPE p DECIMALS 2,
          lv_total_ded   TYPE p DECIMALS 2,
          lv_total_diff  TYPE p DECIMALS 2.


    LOOP AT lt_item2 INTO DATA(ls_row2).


    if ls_row2-DebitCreditCode = 'H'.

      lv_gross = ls_row2-creditamountincocodecrcy .

      else.
       lv_gross = ls_row2-DebitAmountInCoCodeCrcy .

endIF.
      " 1️⃣ Calculate Net Amount
      lv_netamt = lv_gross - lv_deduction.

      " 2️⃣ Deduction (Put correct field if available)
      IF lv_deduction = 0.
        lv_deduction_disp = ''.
      ELSE.
        lv_deduction_disp = lv_deduction.
      ENDIF.

      " 3️⃣ Paid Amount Logic
      lv_paidamt = lv_netamt.

      "5 Difference amount
      lv_diffamnt = lv_deduction.
      IF 0 = 0.   " Replace with real diff logic if any
        lv_diffamt_disp = ''.
      ENDIF.

      lv_total_gross += lv_gross.
      lv_total_net   += lv_netamt.
      lv_total_paid  += lv_paidamt.
      lv_total_ded   += lv_deduction.
      lv_total_diff  += lv_diffamnt.

      lv_xml_items = lv_xml_items &&                    "#EC CI_NOORDER

*                 |<Row1>| &&
*                 |<docno>{ ls_row2-accountingdocument }</docno>| &&
*                 |<invno>{ ls_row2-DocumentReferenceID }</invno>| &&
*                 |<grossamt>{ lv_netamt }</grossamt>| &&
*                 |<deduction>{ lv_deduction_disp }</deduction>| &&
*                 |<netamnt>{ lv_netamt }</netamnt>| &&
*                 |<paidamnt>{ lv_paidamt }</paidamnt>| &&
*                 |<diffamnt>{ lv_diffamt_disp }</diffamnt>| &&
*                 |</Row1>|.


|<Row1>| &&
|<docno>{ zcl_escape_xml=>escape_xml( ls_row2-accountingdocument ) }</docno>| &&
|<invno>{ zcl_escape_xml=>escape_xml( ls_row2-DocumentReferenceID ) }</invno>| &&
|<grossamt>{ zcl_escape_xml=>escape_xml( |{ lv_netamt }| ) }</grossamt>| &&
|<deduction>{ zcl_escape_xml=>escape_xml( |{ lv_deduction_disp }| ) }</deduction>| &&
|<netamnt>{ zcl_escape_xml=>escape_xml( |{ lv_netamt }| ) }</netamnt>| &&
|<paidamnt>{ zcl_escape_xml=>escape_xml( |{ lv_paidamt }| ) }</paidamnt>| &&
|<diffamnt>{ zcl_escape_xml=>escape_xml( |{ lv_diffamt_disp }| ) }</diffamnt>| &&
|</Row1>| .
    ENDLOOP.

    " ---------------------------------------------------------------------

*    DATA(lv_xml_footer) = |<Row2>| &&
*                          |<grostotal>{ lv_total_gross }</grostotal>| &&
*                          |<deduction>{ lv_deduction }</deduction>| &&
*                          |<ntamnttotal>{ abs( lv_total_net ) }</ntamnttotal>| &&
*                          |<paidamntotal>{ lv_total_paid }</paidamntotal>| &&
*                          |<diffamnt>{ lv_diffamnt }</diffamnt>| &&
*                          |</Row2>| &&
*                          |</Table2>| &&
*                          |</Subform3>| &&
*                          |<usernamid>{ lv_userid }</usernamid>| &&
*                          |</form1>|.

DATA(lv_xml_footer) =
  |<Row2>| &&
  |<grostotal>{ zcl_escape_xml=>escape_xml( |{ lv_total_gross }| ) }</grostotal>| &&
  |<deduction>{ zcl_escape_xml=>escape_xml( |{ lv_deduction }| ) }</deduction>| &&
  |<ntamnttotal>{ zcl_escape_xml=>escape_xml( |{ abs( lv_total_net ) }| ) }</ntamnttotal>| &&
  |<paidamntotal>{ zcl_escape_xml=>escape_xml( |{ lv_total_paid }| ) }</paidamntotal>| &&
  |<diffamnt>{ zcl_escape_xml=>escape_xml( |{ lv_diffamnt }| ) }</diffamnt>| &&
  |</Row2>| &&
  |</Table2>| &&
  |</Subform3>| &&
  |<usernamid>{ zcl_escape_xml=>escape_xml( lv_userid ) }</usernamid>| &&
  |</form1>|.


    rv_xml = |{ lv_xml_header }{ lv_xml_items }{ lv_xml_footer }|.


  ENDMETHOD.
ENDCLASS.
