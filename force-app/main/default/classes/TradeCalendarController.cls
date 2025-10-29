public with sharing class TradeCalendarController {
    public class DayStat {
        @AuraEnabled public String isoDate;   // YYYY-MM-DD
        @AuraEnabled public Decimal totalPnl; // sum for the day
        @AuraEnabled public Decimal pnlPercentage;
        @AuraEnabled public Integer trades;   // count
        @AuraEnabled public Integer wins;     // count of positive pnl
    }

    @AuraEnabled(cacheable=true)
    public static List<DayStat> getMonthlyStats(Integer year, Integer month, Id recordId) {
        if (year == null || month == null) return new List<DayStat>();

        // Start and endDate of requested month
        Date start = Date.newInstance(year, month, 1);
        Date endDate   = start.addMonths(1);
        String recordIdString = String.valueOf(recordId);
        List<SR_Hedge__c> hedges;
        if (recordIdString.startsWith('001')) {
             hedges = [
                SELECT Id, Final_Profit__c, Final_Close_Date__c, Close_Date_Time__c, Profit_Percentage__c
                FROM SR_Hedge__c
                WHERE Final_Close_Date__c >= :start
                AND Final_Close_Date__c <  :endDate AND Actual_Trading_Account__r.Account__c = :recordId
            ];

            List<Archived_Trade__x> archivedRows = [SELECT Id, profit__c, close_date_time__c, currency__r.Name
                                                FROM Archived_Trade__x
                                               WHERE close_date_time__c >= :start
                                              AND close_date_time__c <= :endDate
                                              AND Trading_Account__r.Account__c = :recordId
                                            LIMIT 5000];

            for (Archived_Trade__x r : archivedRows) {
                hedges.add(new SR_Hedge__c(
                    X1st_Trade_Profit__c = r.profit__c,
                    Close_Date_Time__c = r.close_date_time__c
                ));
            }
        } else if (recordIdString.startsWith('a0G')) {
            hedges = [
                SELECT Id, Final_Profit__c, Final_Close_Date__c, Close_Date_Time__c, Profit_Percentage__c
                FROM SR_Hedge__c
                WHERE Final_Close_Date__c >= :start
                AND Final_Close_Date__c <  :endDate AND Actual_Trading_Account__c = :recordId
            ];

            List<Archived_Trade__x> archivedRows = [SELECT Id, profit__c, close_date_time__c, currency__r.Name
                                                FROM Archived_Trade__x
                                               WHERE close_date_time__c >= :start
                                              AND close_date_time__c <= :endDate
                                              AND Trading_Account__c = :recordId
                                            LIMIT 5000];

            for (Archived_Trade__x r : archivedRows) {
                hedges.add(new SR_Hedge__c(
                    X1st_Trade_Profit__c = r.profit__c,
                    Close_Date_Time__c = r.close_date_time__c
                ));
            }
        } else if (recordIdString.startsWith('005')) {

            Id accountRecordId = [SELECT Contact.AccountId FROM User WHERE Id = :recordId LIMIT 1].Contact.AccountId;

            hedges = [
                SELECT Id, Final_Profit__c, Final_Close_Date__c, Close_Date_Time__c, Profit_Percentage__c
                FROM SR_Hedge__c
                WHERE Final_Close_Date__c >= :start
                AND Final_Close_Date__c <  :endDate AND  Actual_Trading_Account__r.Account__c = :accountRecordId
            ];

            List<Archived_Trade__x> archivedRows = [SELECT Id, profit__c, close_date_time__c, currency__r.Name
                                                FROM Archived_Trade__x
                                               WHERE close_date_time__c >= :start
                                              AND close_date_time__c <= :endDate
                                              AND Trading_Account__r.Account__c = :accountRecordId
                                            LIMIT 5000];

            for (Archived_Trade__x r : archivedRows) {
                hedges.add(new SR_Hedge__c(
                    X1st_Trade_Profit__c = r.profit__c,
                    Close_Date_Time__c = r.close_date_time__c
                ));
            }
        }

        Map<Date, DayStat> byDay = new Map<Date, DayStat>();

        for (SR_Hedge__c h : hedges) {
            Date d;
            if (h.Final_Close_Date__c == null && h.Close_Date_Time__c == null) continue;

            // Handle both Date and DateTime fields safely
            // if (h.Final_Close_Date__c == null) {

            if (h.Final_Close_Date__c == null) {
                d = ((Datetime)h.Close_Date_Time__c).date();
            } else {
                d = ((Datetime)h.Final_Close_Date__c).date();
            }


            // // }
            // if (h.Final_Close_Date__c instanceof Date) {
            //     d = (Date)h.Final_Close_Date__c;
            // } else if (h.Close_Date_Time__c instanceof Date) {
            //     d = (Date)h.Close_Date_Time__c;
            // } else {
            //     d = ((Datetime)h.Final_Close_Date__c).date();
            // }

            DayStat s = byDay.get(d);
            if (s == null) {
                s = new DayStat();
                s.isoDate = d.year() + '-' +
                            String.valueOf(d.month()).leftPad(2, '0') + '-' +
                            String.valueOf(d.day()).leftPad(2, '0');
                s.totalPnl = 0;
                s.pnlPercentage = 0;
                s.trades = 0;
                s.wins = 0;
                byDay.put(d, s);
            }

            Decimal pnl = (h.Final_Profit__c == null) ? (h.X1st_Trade_Profit__c == null) ? 0 : h.X1st_Trade_Profit__c : h.Final_Profit__c;
            Decimal pnlPercentage = (h.Profit_Percentage__c == null) ? (h.Profit_Percentage__c == null) ? 0 : h.Profit_Percentage__c : h.Profit_Percentage__c;
            s.totalPnl += pnl;
            s.pnlPercentage += pnlPercentage;
            s.trades += 1;
            if (pnl > 0) s.wins += 1;
        }

        return new List<DayStat>(byDay.values());
    }
}
