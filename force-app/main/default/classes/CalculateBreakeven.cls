public class CalculateBreakeven {

    @InvocableMethod(label='Calculate Breakeven 2 Trade' description='Calculate BE Price')
    public static List<SR_Hedge__c> calculate(List<SR_Hedge__c> inputList) {
        SR_Hedge__c currentTrade = inputList.get(0);
        
        Double currentPrice = currentTrade.X2nd_Trade_Open_Price__c;
        Double currentProfit = calculateProfit2Trade(currentPrice,
                                                    currentTrade.X1st_Trade_Open_Price__c,
                                                    currentTrade.X2nd_Trade_Open_Price__c,
                                                    currentTrade.X1st_Trade_Units__c,
                                                    currentTrade.X2nd_Trade_Units__c);
        while(currentProfit < 0) {
            currentPrice += currentTrade.Pip_Amount__c;
            currentProfit = calculateProfit2Trade(currentPrice,
                                                    currentTrade.X1st_Trade_Open_Price__c,
                                                    currentTrade.X2nd_Trade_Open_Price__c,
                                                    currentTrade.X1st_Trade_Units__c,
                                                    currentTrade.X2nd_Trade_Units__c);
        }
        
        
        currentTrade.Breakeven_Price__c = currentPrice;
        
        List<SR_Hedge__c> newList = new List<SR_Hedge__c>();
        newList.add(currentTrade);
        return newList;
    } 
    
    public static Double calculateProfit2Trade(Double cP, Decimal openOne, Decimal openTwo, Decimal unitOne, Decimal unitTwo) {
        return ((cP - openOne) * unitOne) + ((cP - openTwo) * unitTwo);
    }
}