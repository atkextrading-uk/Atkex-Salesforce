global with sharing class ImportMetatraderSchedule implements Schedulable {

    private static final Integer CHUNK_SIZE = 1;

    global void execute(SchedulableContext sc) {
        // Get all trading accounts with Live_Importing__c = true
        List<Id> taIds = new List<Id>();
        for (Trading_Account__c ta : [
            SELECT Id
            FROM Trading_Account__c
            WHERE Live_Importing__c = true
            AND IsDeleted = false
        ]) {
            taIds.add(ta.Id);
        }
        if (taIds.isEmpty()) return;

        Integer enqueues = 0;

        // Process in chunks of CHUNK_SIZE
        for (Integer i = 0; i < taIds.size(); i += CHUNK_SIZE) {
            Integer endIdx = Math.min(i + CHUNK_SIZE, taIds.size());
            List<Id> chunk = new List<Id>();

            // Manual sublist clone since List<Id>.subList() is unsupported
            for (Integer j = i; j < endIdx; j++) {
                chunk.add(taIds[j]);
            }

            System.enqueueJob(new ImportMetatraderQueue(chunk));
            enqueues++;

            if (enqueues == 50) break; // platform safeguard
        }
    }

    // =====================================
    // 🕐 Scheduling Utilities
    // =====================================

    /**
     * Schedules this job to run every X minutes across the hour.
     * Example: scheduleEveryXMinutes(5) → 12 jobs/hour
     */
    public static void scheduleEveryXMinutes(Integer intervalMinutes) {
        if (intervalMinutes == null || intervalMinutes <= 0) {
            throw new IllegalArgumentException('Interval must be greater than 0.');
        }

        cancelAll();

        Integer totalSlots = 60 / intervalMinutes;
        String jobNamePrefix = 'ImportMetatraderScheduled_' + intervalMinutes + 'min_';

        for (Integer i = 0; i < totalSlots; i++) {
            Integer minute = i * intervalMinutes;

            // Run at minute marks throughout the hour
            String cron = '0 ' + minute + ' * * * ?';
            String jobName = jobNamePrefix + String.valueOf(minute).leftPad(2, '0');

            System.schedule(jobName, cron, new ImportMetatraderSchedule());
        }
    }

    /**
     * Cancels all scheduled jobs for this class.
     */
    public static void cancelAll() {
        List<CronTrigger> triggers = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.JobType = '7'
        ];

        for (CronTrigger ct : triggers) {
            if (ct.CronJobDetail.Name.startsWith('ImportMetatraderScheduled')) {
                System.abortJob(ct.Id);
            }
        }
    }
}
