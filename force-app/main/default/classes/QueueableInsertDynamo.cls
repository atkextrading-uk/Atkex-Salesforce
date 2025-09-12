public class QueueableInsertDynamo implements Queueable {
    Algorithmic_Trade__x trade;
    String action;
    public QueueableInsertDynamo(Algorithmic_Trade__x t, String a) {
        trade = t;
        action = a;
    }
    
    public void execute(QueueableContext context) {
        if (action == 'insert') {
            Database.insertImmediate(trade);
        } else if (action == 'update') {
            Database.updateImmediate(trade);
        }
    }
}