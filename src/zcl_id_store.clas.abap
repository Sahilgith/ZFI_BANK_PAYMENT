CLASS zcl_id_store DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

  inTERFACES if_oo_adt_classrun.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ID_STORE IMPLEMENTATION.


metHOD if_oo_adt_classrun~main.

select * from   "#EC CI_NOWHERE
zdb_bank_auth
into table @data(lt_auth).

if sy-subrc = 0.
deleTE zdb_bank_auth from table @lt_auth.
enDIF.

clear : lt_auth.

    lt_auth = VALUE #( ( id = '1' name = 'CB9980000000' )  ).


    IF  lt_auth IS NOT INITIAL.
      INSERT zdb_bank_auth FROM TABLE @lt_auth.
      COMMIT WORK.
    ENDIF.





eNDMETHOD.
ENDCLASS.
