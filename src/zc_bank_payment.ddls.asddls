@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for bank payment'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@UI: {
    headerInfo: {
        typeName: 'Accounting Document',
        typeNamePlural: 'Accounting Document'
    },
    presentationVariant: [
        {
            sortOrder: [
                {
                    by: 'AccountingDocument',
                    direction: #DESC
                }
            ]
        }
    ]
}

define root view entity ZC_BANK_PAYMENT
provider contract transactional_query
 as projection on ZI_BANK_PAYMENT_n
{

 @UI.facet: [{ id : 'AccountingDoc',
        purpose: #STANDARD,
        type: #IDENTIFICATION_REFERENCE,
        label: 'Out Payment',
         position: 10 }]

      @UI.lineItem:       [{ position: 10, label: 'AccountingDocument' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
      @UI.identification: [{ position: 10, label: 'AccountingDocument' }]
      @UI.selectionField: [{ position: 10 }]
    key AccountingDocument,

  @UI.lineItem:       [{ position: 20, label: 'CompanyCode' }]
      @UI.identification: [{ position: 20, label: 'CompanyCode' }]
      @UI.selectionField: [{ position: 20 }]
    key CompanyCode,
       
     @UI.lineItem:       [{ position: 30, label: 'FiscalYear' }]
      @UI.identification: [{ position: 30, label: 'FiscalYear' }]
      @UI.selectionField: [{ position: 30 }]
    key FiscalYear,
    
  @UI.lineItem:       [{ position: 40, label: 'AccountingDocumentType' }]
      @UI.identification: [{ position: 40, label: 'AccountingDocumentType' }]
   AccountingDocumentType,
   
    base64,
//
//      @UI.lineItem:       [{ position: 50, label: 'Y/N' }]
//      @UI.identification: [{ position: 50, label: 'Y/N' }]
//    m_ind

  @UI.lineItem:       [{ position: 50, label: 'PDF Status', criticality: 'Criticality', criticalityRepresentation: #WITH_ICON }]
  @UI.identification: [{ position: 50, label: 'PDF Status', criticality: 'Criticality', criticalityRepresentation: #WITH_ICON }]
  m_ind,

  @UI.hidden: true
  Criticality,
  
  @UI.selectionField: [{ position: 40 }]
  documentdate
}
