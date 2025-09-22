trigger StrategyTrigger on Strategy__c (before insert, before update, after insert) {
    StrategyTriggerHandler.TriggerWrapper tw = new StrategyTriggerHandler.TriggerWrapper(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );
    StrategyTriggerHandler.run(tw);
}

