@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for Bank Payment'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_BANK_PAYMENT_n
  
  as select from    I_AccountingDocumentJournal( P_Language: $session.system_language ) as a
 
   left outer join zdb_bank_pay_n as b 
  on a.AccountingDocument = b.accountingdocument
 and a.CompanyCode        = b.companycode
 and a.FiscalYear         = b.fiscalyear
                                         
{
  key a.AccountingDocument,
  key a.CompanyCode,
  key a.FiscalYear,
  a.AccountingDocumentType,
 a.PostingDate as documentdate,
      b.from_date,
      b.to_date,
      b.base64,
      b.m_ind,
cast(
  case b.m_ind
    when 'X' then 3   
    else          1   
  end as abap.int1
) as Criticality
      
      
}

where
      a.LedgerGLLineItem = '000001'
  and a.Ledger           = '0L'
  and ( a.AccountingDocumentType = 'KZ' or a.AccountingDocumentType = 'SK' or a.AccountingDocumentType = 'MP' or a.AccountingDocumentType = 'MR' or a.AccountingDocumentType = 'DZ')
