public class FactoryOperacion {

  
  public static InterfaceOperacion create(List<Item__c> items){
    InterfaceOperation interfaceOperation;
    
    // Helper Business Rules validate specific Business Details
    // Like Product Lines cannot repeat
    Helper_BusinessRules.enforceUniqueProducto(items);
    
    // Create an Invoice Document from multiple order item lines.
    Documento__c doc = Helper_Documentos.documento_from_movimientos(movimientos);
    insert doc;
    
    for(Movimiento__c m : movimientos){
      m.documento__c = doc.id;
    }
   
    // Run different Operations depending of additional circumstances
   
    if(doc.Tipo_de_Documento__c == 'FA' && !doc.isRetail__c){
    	interfaceOperation = new OperationCreditInvoice(doc,orderItems); 
    }
       
    else if(doc.Tipo_de_Documento__c == 'FA' && doc.isReatil__c){
    	interfaceOperation = new OperationRetailInvoice(doc,orderItems); 
    }

    return interfaceOperation;
  } 

    
}