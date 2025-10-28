public with sharing class OandaTradeController {

    public class FieldInfo {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
    }

    public class PageRequest {
        @AuraEnabled public Integer pageNumber;   // ignored (client paginates)
        @AuraEnabled public Integer pageSize;     // ignored (client paginates)
        @AuraEnabled public List<String> fieldApiNames;
        @AuraEnabled public String sortField;     // ignored (client sorts)
        @AuraEnabled public String sortDir;       // ignored (client sorts)
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
    }

    public class PageResult {
        @AuraEnabled public Integer pageNumber;    // 1
        @AuraEnabled public Integer pageSize;      // records.size()
        @AuraEnabled public Integer totalRecords;  // records.size()
        @AuraEnabled public Integer totalPages;    // 1
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public String error;
        @AuraEnabled public String effectiveSoql;
    }

    private static final String SOBJECT_API = 'Oanda_Trade__x';

    // UI-exposed fields (Id is always queried, but not shown in picker)
    private static final Set<String> ALLOWED_FIELDS = new Set<String>{
        'Name__c','Oanda_Id__c','Index__c','Side__c','Currency__r.Name',
        'Open_Date_Time__c','Close_Date_Time__c','Open_URL__c','Close_URL__c',
        'Second_Screenshot__c','Open_Comments__c','Close_Comments__c',
        'Outcome__c','Profit_Loss__c','Profit_Percentage__c',
        'Balance_On_Close__c','Monthly_Transaction__c'
    };

    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getFieldOptions() {
        List<FieldInfo> out = new List<FieldInfo>();
        Map<String,String> labels = new Map<String,String>{
            'ExternalId'=>'Id','Name__c'=>'Name','Oanda_Id__c'=>'Oanda Id','Index__c'=>'Index',
            'Side__c'=>'Side','Currency__r.Name'=>'Currency','Open_Date_Time__c'=>'Open Date/Time',
            'Close_Date_Time__c'=>'Close Date/Time','Open_URL__c'=>'Open Screenshot URL',
            'Close_URL__c'=>'Close Screenshot URL','Second_Screenshot__c'=>'Second Screenshot URL',
            'Open_Comments__c'=>'Open Comments','Close_Comments__c'=>'Close Comments',
            'Outcome__c'=>'Outcome','Profit_Loss__c'=>'Profit/Loss','Profit_Percentage__c'=>'Profit %',
            'Balance_On_Close__c'=>'Balance On Close','Monthly_Transaction__c'=>'Monthly Transaction'
        };
        Map<String,String> types = new Map<String,String>{
            'ExternalId'=>'text','Name__c'=>'text','Oanda_Id__c'=>'number','Index__c'=>'number',
            'Side__c'=>'text','Currency__r.Name'=>'text','Open_Date_Time__c'=>'datetime',
            'Close_Date_Time__c'=>'datetime','Open_URL__c'=>'url','Close_URL__c'=>'url',
            'Second_Screenshot__c'=>'url','Open_Comments__c'=>'text','Close_Comments__c'=>'text',
            'Outcome__c'=>'text','Profit_Loss__c'=>'currency','Profit_Percentage__c'=>'percent',
            'Balance_On_Close__c'=>'currency','Monthly_Transaction__c'=>'lookup'
        };
        for (String f : ALLOWED_FIELDS) {
            FieldInfo fi = new FieldInfo();
            fi.apiName = f;
            fi.label   = labels.containsKey(f) ? labels.get(f) : f;
            fi.type    = types.containsKey(f)  ? types.get(f)  : 'text';
            out.add(fi);
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static PageResult fetchPage(PageRequest req) {
        PageResult result = new PageResult();
        try {
            // Defaults for dates
            Date today = Date.today();
            Date defaultStart = today.addYears(-1);
            Date startDate = (req != null && req.startDate != null) ? req.startDate : defaultStart;
            Date endDate   = (req != null && req.endDate   != null) ? req.endDate   : today;

            // Swap if inverted
            if (startDate != null && endDate != null && endDate < startDate) {
                Date tmp = startDate; startDate = endDate; endDate = tmp;
            }

            // Requested fields (whitelisted)
            List<String> requested = (req == null || req.fieldApiNames == null || req.fieldApiNames.isEmpty())
                ? new List<String>{ 'Name__c','Side__c','Currency__r.Name','Open_Date_Time__c','Close_Date_Time__c','Profit_Loss__c','Profit_Percentage__c','Open_URL__c','Close_URL__c' }
                : req.fieldApiNames;

            Set<String> finalSet = new Set<String>();
            for (String f : requested) {
                if (f != null && ALLOWED_FIELDS.contains(f)) finalSet.add(f);
            }
            List<String> fieldList = new List<String>(finalSet);
            if (fieldList.isEmpty()) fieldList.add('Name__c');

            // Always include Id for LWC key-field, but don't expose in picker list
            if (!fieldList.contains('Id')) fieldList.add('Id');

            // WHERE with binds
            List<String> whereParts = new List<String>();
            Datetime startDT = (startDate != null) ? Datetime.newInstance(startDate, Time.newInstance(0,0,0,0)) : null;
            Datetime endDT   = (endDate   != null) ? Datetime.newInstance(endDate,   Time.newInstance(23,59,59,999)) : null;
            if (startDT != null) whereParts.add('Open_Date_Time__c >= :startDT');
            if (endDT   != null) whereParts.add('Close_Date_Time__c <= :endDT');
            String whereClause = whereParts.isEmpty() ? '' : (' WHERE ' + String.join(whereParts, ' AND '));

            // Build SOQL WITHOUT ORDER BY/LIMIT/OFFSET
            String soql = 'SELECT ' + String.join(fieldList, ', ') + ' FROM ' + SOBJECT_API + whereClause;

            // Single query (no SOQL in loops)
            List<SObject> rows = new List<SObject>();
            try {
                rows = Database.query(soql);
            } catch (Exception qe) {
                // Null-pointer safe fallback
                rows = new List<SObject>();
                System.debug(LoggingLevel.ERROR, 'Query failed: ' + qe.getMessage());
            }

            // Compose result (client paginates)
            Integer count = (rows == null) ? 0 : rows.size();
            result.pageNumber   = 1;
            result.pageSize     = count;
            result.totalRecords = count;
            result.totalPages   = 1;
            result.records      = (rows == null) ? new List<SObject>() : rows;
            result.effectiveSoql = soql;

        } catch (Exception e) {
            result.error = 'Failed to load Oanda_Trade__x data: ' + e.getMessage();
            result.pageNumber   = 1;
            result.pageSize     = 0;
            result.records      = new List<SObject>();
            result.totalRecords = 0;
            result.totalPages   = 0;
            System.debug(LoggingLevel.ERROR, 'OandaTradeController.fetchPage error: ' + e);
        }
        return result;
    }
}
