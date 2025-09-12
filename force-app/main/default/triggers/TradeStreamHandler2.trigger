trigger TradeStreamHandler2 on TradeEvents__e (after insert) {
	List<TradeEvents__e> tradeEvents = Trigger.new;
    for (TradeEvents__e tradeEvent : tradeEvents) {
        String tradeData = tradeEvent.Id;
        // Handle the incoming trade data here
        system.debug(tradeData);
    }
}