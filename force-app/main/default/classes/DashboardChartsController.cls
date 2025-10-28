public with sharing class DashboardChartsController {
    public class HedgeRecord {
        @AuraEnabled public Date tradeDate;
        @AuraEnabled public Decimal profit;
        @AuraEnabled public String pair;
        @AuraEnabled public String outcome; // 'Win' or 'Loss' (if null, we infer from profit)
        public HedgeRecord(Date d, Decimal p, String pr, String o) {
            tradeDate = d; profit = p; pair = pr; outcome = o;
        }
    }
    public class HedgeResult {
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public List<HedgeRecord> records;
    }

    @AuraEnabled(cacheable=true)
    public static HedgeResult getHedges(Date startDate, Date endDate, Id recordId) {
        // Default to current month if not provided
        if (startDate == null || endDate == null) {
            Date today = Date.today();
            Date first = Date.newInstance(today.year(), today.month(), 1);
            Date last  = first.addMonths(1).addDays(-1);
            if (startDate == null) startDate = first;
            if (endDate == null) endDate = last;
        }

        // Adjust field API names below to match your org exactly
        List<sr_hedge__c> rows = [
            SELECT Id,
                   Final_Close_Date__c,
                   Final_Profit__c,
                   Currency__r.Name,
                   Outcome__c
            FROM sr_hedge__c
            WHERE Final_Close_Date__c >= :startDate
              AND Final_Close_Date__c <= :endDate
              AND Actual_Trading_Account__c = :recordId
            ORDER BY Final_Close_Date__c ASC, CreatedDate ASC
            LIMIT 5000
        ];
        
        List<Archived_Trade__x> archivedRows = [SELECT Id, profit__c, close_date_time__c, currency__r.Name
                                                FROM Archived_Trade__x
                                               WHERE close_date_time__c >= :startDate
                                              AND close_date_time__c <= :endDate
                                              AND Trading_Account__c = :recordId
                                            LIMIT 5000];

        List<Archived_Trade__x> archivedRowsSorted = sortByCloseDateTimeAsc(archivedRows);

        HedgeResult res = new HedgeResult();
        res.startDate = startDate;
        res.endDate   = endDate;
        res.records   = new List<HedgeRecord>();
        
        for (Archived_Trade__x r : archivedRows) {
            res.records.add(new HedgeRecord(
                r.close_date_time__c.date(),
                (Decimal)(r.profit__c == null ? 0 : r.profit__c),
                (String) r.Currency__r.Name,
                (String) (r.profit__c > 0 ? 'Win' : 'Loss')
            ));
        }

        for (sr_hedge__c r : rows) {
            res.records.add(new HedgeRecord(
                r.Final_Close_Date__c.date(),
                (Decimal)(r.Final_Profit__c == null ? 0 : r.Final_Profit__c),
                (String) r.Currency__r.Name,
                (String) (r.Final_Profit__c > 0 ? 'Win' : 'Loss')
            ));
        }
        return res;
    }

    private static List<Archived_Trade__x> sortByCloseDateTimeAsc(List<Archived_Trade__x> records) {
        if (records == null || records.isEmpty()) {
            return new List<Archived_Trade__x>();
        }

        records.sort(new CloseDateAscComparator());
        return records;
    }

    private class CloseDateAscComparator implements Comparator<Archived_Trade__x> {
        public Integer compare(Archived_Trade__x r1, Archived_Trade__x r2) {
            if (r1.Close_Date_Time__c == r2.Close_Date_Time__c) return 0;
            if (r1.Close_Date_Time__c == null) return 1;
            if (r2.Close_Date_Time__c == null) return -1;
            return r1.Close_Date_Time__c.getTime() < r2.Close_Date_Time__c.getTime() ? -1 : 1;
        }
    }


    public class EquityPoint {
        @AuraEnabled public String brokerTime;
        @AuraEnabled public Decimal averageBalance;
        @AuraEnabled public Decimal averageEquity;
        @AuraEnabled public Decimal balanceSum;
        @AuraEnabled public Long duration;
        @AuraEnabled public String endBrokerTime;
        @AuraEnabled public Decimal equitySum;
        @AuraEnabled public Decimal lastBalance;
        @AuraEnabled public Decimal lastEquity;
        @AuraEnabled public Decimal maxBalance;
        @AuraEnabled public Decimal maxEquity;
        @AuraEnabled public Decimal minBalance;
        @AuraEnabled public Decimal minEquity;
        @AuraEnabled public Decimal startBalance;
        @AuraEnabled public String startBrokerTime;
        @AuraEnabled public Decimal startEquity;
    }


    public class EquityResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public List<EquityPoint> raw;
    }

    @AuraEnabled(cacheable=false)
    public static EquityResult getEquity(Date startDate, Date endDate, Id recordId) {
        EquityResult res = new EquityResult();

        Trading_Account__c ta = [
            SELECT Id, MetaTrader_ID__c
            FROM Trading_Account__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        String metaTraderAccount = ta.MetaTrader_ID__c;

        try {
            // ---- validation ----
            if (startDate == null || endDate == null) {
                throw new AuraHandledException('Start date and end date are required.');
            }
            if (endDate < startDate) {
                throw new AuraHandledException('End date must be on or after start date.');
            }
            if (String.isBlank(metaTraderAccount)) {
                throw new AuraHandledException('Record Id / MetaTrader account is required.');
            }

            // ---- callout ----
            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                'callout:Atkex_Trading/api/accounts/equity-information?mtAccountId=' +
                EncodingUtil.urlEncode(metaTraderAccount, 'UTF-8')
            );
            req.setMethod('GET');
            req.setTimeout(20000);

            Http http = new Http();
            HTTPResponse resp = http.send(req);

            if (resp == null) {
                res.success = false;
                res.message = 'No response from external service.';
                return res;
            }

            Integer statusCode = resp.getStatusCode();
            String body = resp.getBody();

            if (statusCode == 200) {
                // Deserialize raw response
                EquityResult rawData = (EquityResult)JSON.deserialize(body, EquityResult.class);

                // rawData.raw is expected to be a List<EquityPoint>-like structure,
                // but your EquityPoint class currently only has
                // brokerTime, maxEquity, minEquity.
                // You showed more fields (maxBalance, lastEquity, etc),
                // so update EquityPoint so it includes those new fields!
                //
                // public class EquityPoint {
                //   @AuraEnabled public String brokerTime;
                //   @AuraEnabled public Decimal maxBalance;
                //   @AuraEnabled public Decimal minBalance;
                //   @AuraEnabled public Decimal lastBalance;
                //   @AuraEnabled public Decimal maxEquity;
                //   @AuraEnabled public Decimal minEquity;
                //   @AuraEnabled public Decimal lastEquity;
                //   // ...anything else you care about
                // }

                // Now filter rawData.raw by the requested date range
                List<EquityPoint> filtered = new List<EquityPoint>();
                if (rawData != null && rawData.raw != null) {
                    for (EquityPoint p : rawData.raw) {
                        if (p == null || String.isBlank(p.brokerTime)) continue;

                        // brokerTime e.g. "2025-10-27 14:59:56.647"
                        // We only care about the date portion for filtering.
                        // We'll parse to Date.
                        Date brokerDate;

                        try {
                            // extract "yyyy-MM-dd" from "yyyy-MM-dd HH:mm:ss.SSS"
                            String datePart = p.brokerTime.substring(0, 10); // "2025-10-27"
                            brokerDate = Date.valueOf(datePart);
                        } catch (Exception parseEx) {
                            // if parsing fails, just skip this row
                            continue;
                        }

                        if (brokerDate >= startDate && brokerDate <= endDate) {
                            filtered.add(p);
                        }
                    }
                }

                // Build response
                res.success = true;
                res.message = 'OK';
                res.raw = filtered;
                return res;

            } else {
                res.success = false;
                res.message = 'Callout failed: ' + statusCode + ' ' + resp.getStatus();
                return res;
            }

        } catch (AuraHandledException ahe) {
            res.success = false;
            res.message = ahe.getMessage();
            return res;

        } catch (CalloutException ce) {
            res.success = false;
            res.message = 'Callout exception: ' + ce.getMessage();
            return res;

        } catch (Exception e) {
            res.success = false;
            res.message = 'Unexpected error: ' + e.getMessage();
            return res;
        }
    }
}