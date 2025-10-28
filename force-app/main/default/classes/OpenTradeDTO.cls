public with sharing class OpenTradeDTO {
    @AuraEnabled public String   id         { get; set; }
    @AuraEnabled public String   type       { get; set; }
    @AuraEnabled public String   symbol     { get; set; }
    @AuraEnabled public String   timeString { get; set; }
    @AuraEnabled public Decimal   stopLoss { get; set; }
    @AuraEnabled public Decimal   takeProfit { get; set; }
    @AuraEnabled public Decimal   openPrice { get; set; }


    public OpenTradeDTO() {}
}
