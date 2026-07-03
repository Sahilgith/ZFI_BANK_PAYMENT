@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for Bank Payment'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BANK_PAYMENT
  
  as select from    I_AccountingDocumentJournal( P_Language: $session.system_language ) as a
 
    left outer join zdb_bank_payment                                                    as b on a.AccountingDocument = b.accountingdocument
{
  key a.AccountingDocument,
  key a.CompanyCode,
  key a.FiscalYear,
  a.AccountingDocumentType,

      b.from_date,
      b.to_date,
      b.base64,
      b.m_ind
}

where
      a.LedgerGLLineItem = '000001'
  and a.Ledger           = '0L'
  and ( a.AccountingDocumentType = 'KZ' or a.AccountingDocumentType = 'SK' or a.AccountingDocumentType = 'MP' or a.AccountingDocumentType = 'MR' )
