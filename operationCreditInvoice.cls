public  without sharing  class CreditInvoice extends InterfaceOperation {  

	public Document__c document; 
	public List<Item__c> items;

  // Initialize Operation with Parameters
  // Usually the Operation is instantiated from a Factory for complex cases
  // It could also be instantiated from a Trigger or a Rest Controller for simple cases
	public CreditInvoice(document__c document , List<Item__c> items){
		this.document = document;
		this.items = items;
	}

  // Set the commands that will be executed in the near feature
  // Command Execution normally occurs in a Factory Class
	public override void setCommands(){ 
		// Map items to products in order to modify inventory ( trought a command )
		Map<string,sobject> mapItems = mapFieldToObject(items, 'Product__c');
		
		// Retrieve product information like balance and cost
		List<Product__c> productos = [select id,Name , balance__c ,Cost__c , Price__c from Product__c where id in :mapItems.keySet() for update];

    // Retrieve Client information for reference
		Client__c client = [select id,name,balance__c from client__c where id = :this.document.client__c];

		// Change the balance on the client object, this is used for reference
		this.commands.add(new CommandChangeClientBalance(client,this.document.total__c));
		
		// Change the balance in the Document, for concurrency we set the document pending balance trought a command.
		InterfaceCommand commandBalance = new CommandChangeDocumentBalance(this.document, this.document.total__c);
		
		// If there are any Tax Exempt Products, we record them trought a command according to country e
		InterfaceCommand commandExempt = new CommandSetDocumentExempt(this.document);
		
		// We are a CommandList Implementation when we need to modify the same object in two separate commands
		List<InterfaceCommand> commandList =  new InterfaceCommand[]{ commandSaldo,commandExempt };
		this.commands.add(new CommandCompound(commandList)); 	
	 	
	 	// Create system registries for accounting procedures.
		this.commands.add(new CommandCreateRegisry( document.client__c  , 'sales' , document.total__c ));	

		for(producto__c producto : productos){
			Item__c ref = (Item__c)mapItems.get(producto.id); 
		
			// Change the product balance
			this.commands.add(new CommandChangeProductBalance(producto, ref.ProductAmount__c ) );
			
			// Record the product latest Cost in the Invoice ITem
			this.commands.add(new CommandSetCostToItem( ref , producto ));
			
  	 	// Create system registries for accounting procedures.
			this.commands.add(new CommandCreateRegistry( producto.id , 'inventory' , ref.ProductCantidad__c * producto.Costo__c * -1 ));
		}			
	}
}