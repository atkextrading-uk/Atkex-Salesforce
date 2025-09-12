public class RESTResponse {
    public RESTResponse() {

    }

    public class OandaTransactions {
        public String start;	//2023-06-20T20:18:06.052283597Z
        public String to;	//2023-06-27T20:18:06.052283597Z
        public Integer pageSize;	//100
        public Integer count;	//149
        public List<String> pages = New List<String>();
        public String lastTransactionID;	//6116
        
        /*public static OandaTransactions parse(String json){
            return (OandaTransactions) System.JSON.deserialize(json, OandaTransactions.class);
        }*/
    }

    //Inner classes
    /*public class cls_pages {
        String page; //"https://api-fxtrade.oanda.com/v3/accounts/001-004-6038873-004/transactions/idrange?from=5968&to=6067"
    }*/

    public class OandaTransactionsPage {
        public List<cls_transactions> transactions = new List<cls_transactions>();
        public String lastTransactionID;	//6118
        
    }

    public class cls_transactions {
        public Integer id;	//6114
        public Integer tradeID;	//6114
        public String accountID;	//001-004-6038873-004
        public Integer userID;	//6038873
        public String batchID;	//6113
        public String requestID;	//169209121339398203
        //@JsonProperty('time')  // Specify a different name for deserialization
        public String transactionTime; //2023-06-27T19:03:36.756635377Z
        public String type;	//ORDER_FILL
        public String orderID;	//6113
        public String instrument;	//EUR_AUD
        public Decimal units;	//-174
        public String requestedUnits;	//-174
        public Decimal price;	//1.63833
        public Decimal pl;	//0.0000
        public String quotePL;	//0
        public String financing;	//0.0000
        public String baseFinancing;	//0
        public String commission;	//0.0000
        public Decimal accountBalance;	//590.7865
        public String gainQuoteHomeConversionFactor;	//0.521941202427
        public String lossQuoteHomeConversionFactor;	//0.527186842652
        public String guaranteedExecutionFee;	//0.0000
        public String quoteGuaranteedExecutionFee;	//0
        public String halfSpreadCost;	//0.0096
        public String fullVWAP;	//1.63833
        public String reason;	//MARKET_ORDER
        public cls_tradeOpened tradeOpened;
        public List<cls_tradesClosed> tradesClosed = new List<cls_tradesClosed>();
        public cls_tradeClose tradeClose;
        public cls_fullPrice fullPrice;
        public cls_tradeReduced tradeReduced;
        public cls_homeConversionFactors homeConversionFactors;
        public String plHomeConversionCost;	//0.00000000000000
        public String baseFinancingHomeConversionCost;	//0.00000000
        public String guaranteedExecutionFeeHomeConversionCost;	//0.00000000000000
        public String homeConversionCost;	//0.00000000000000
    
    }
    public class cls_tradeReduced {
		public Integer tradeID;	//13786
		public Decimal units;	//500
		public Decimal realizedPL;	//1.5181
		public String financing;	//0.0000
		public String baseFinancing;	//0.00000000000000
		public Decimal price;	//1.24536
		public String guaranteedExecutionFee;	//0.0000
		public String quoteGuaranteedExecutionFee;	//0
		public String halfSpreadCost;	//0.0241
		public String plHomeConversionCost;	//-0.00751841623670
		public String baseFinancingHomeConversionCost;	//0.00000000000000
		public String guaranteedExecutionFeeHomeConversionCost;	//0.00000000000000
		public String homeConversionCost;	//-0.00751841623670
	}
    public class cls_tradeClose { 
        public Integer units;
        public Integer tradeID;
    }
    public class cls_tradesClosed { 
        public Integer tradeID;
    }
	public class cls_tradeOpened {
		public String price;	//1.63833
		public String tradeID;	//6114
		public String units;	//-174
		public String guaranteedExecutionFee;	//0.0000
		public String quoteGuaranteedExecutionFee;	//0
		public String halfSpreadCost;	//0.0096
		public String initialMarginRequired;	//7.4775
		public String guaranteedExecutionFeeHomeConversionCost;	//0.00000000000000
	}
	public class cls_fullPrice {
		public String closeoutBid;	//1.63833
		public String closeoutAsk;	//1.63854
		public String timestamp;	//2023-06-27T19:03:36.399733349Z
		public cls_bids[] bids;
		public cls_asks[] asks;
	}
	public class cls_bids {
		public String price;	//1.63833
		public String liquidity;	//10000000
	}
	public class cls_asks {
		public String price;	//1.63854
		public String liquidity;	//10000000
	}
	public class cls_homeConversionFactors {
		public cls_gainQuoteHome gainQuoteHome;
		public cls_lossQuoteHome lossQuoteHome;
		public cls_gainBaseHome gainBaseHome;
		public cls_lossBaseHome lossBaseHome;
	}
	public class cls_gainQuoteHome {
		public String factor;	//0.52194120242667
	}
	public class cls_lossQuoteHome {
		public String factor;	//0.52718684265207
	}
	public class cls_gainBaseHome {
		public String factor;	//0.85518260
	}
	public class cls_lossBaseHome {
		public String factor;	//0.86377740
	}
    
}