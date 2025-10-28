import { LightningElement, api } from 'lwc';

export default class TradeSidePanel extends LightningElement {
  /** Optional: control height (px) of the scrollable area. Default 280 */
  @api height = 280;

  get tableStyle() {
    return `max-height:${this.height}px`;
  }

  // ===== Columns =====
  recentColumns = [
    {
      label: 'Close Date',
      fieldName: 'closeDate',
      type: 'date-local',
      typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' },
      initialWidth: 130
    },
    { label: 'Symbol', fieldName: 'symbol', initialWidth: 110 },
    {
      label: 'Net P&L',
      fieldName: 'pnl',
      type: 'currency',
      typeAttributes: { currencyCode: 'USD', maximumFractionDigits: 0 },
      cellAttributes: { class: { fieldName: 'pnlClass' }, alignment: 'left' }
    }
  ];

  openColumns = [
    { label: 'Symbol', fieldName: 'symbol', initialWidth: 110 },
    { label: 'Side', fieldName: 'side', initialWidth: 90 },
    {
      label: 'Qty',
      fieldName: 'qty',
      type: 'number',
      typeAttributes: { maximumFractionDigits: 0 },
      initialWidth: 80
    },
    {
      label: 'Entry',
      fieldName: 'entry',
      type: 'number',
      typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    },
    {
      label: 'Current',
      fieldName: 'current',
      type: 'number',
      typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 }
    },
    {
      label: 'P&L',
      fieldName: 'pnl',
      type: 'currency',
      typeAttributes: { currencyCode: 'USD', maximumFractionDigits: 0 },
      cellAttributes: { class: { fieldName: 'pnlClass' }, alignment: 'left' }
    }
  ];

  // ===== Mock data (edit freely) =====
  recentTrades = [
    this.rowTrade(1, '2025-10-09', 'NAS100', -27920),
    this.rowTrade(2, '2025-10-09', 'NAS100', -33820),
    this.rowTrade(3, '2025-10-09', 'NAS100',  7880),
    this.rowTrade(4, '2025-10-08', 'NAS100', 35427),
    this.rowTrade(5, '2025-10-07', 'SPX500',  9280),
    this.rowTrade(6, '2025-10-07', 'SPX500',  9280)
  ];

  openPositions = [
    this.rowPosition(101, 'NAS100', 'Long', 2, 17345.20, 17410.55, 1300),
    this.rowPosition(102, 'SPX500', 'Short', 1, 5120.00, 5098.25, 2175),
    this.rowPosition(103, 'GOLD', 'Long', 3, 2421.50, 2412.10, -840),
    this.rowPosition(104, 'EURUSD', 'Short', 20000, 1.0920, 1.0942, -440)
  ];

  // ===== Helpers to shape rows =====
  rowTrade(id, dateStr, symbol, pnl) {
    return {
      id,
      closeDate: dateStr,
      symbol,
      pnl,
      pnlClass: pnl > 0 ? 'cell-pos' : pnl < 0 ? 'cell-neg' : 'cell-flat'
    };
  }

  rowPosition(id, symbol, side, qty, entry, current, pnl) {
    return {
      id,
      symbol,
      side,
      qty,
      entry,
      current,
      pnl,
      pnlClass: pnl > 0 ? 'cell-pos' : pnl < 0 ? 'cell-neg' : 'cell-flat'
    };
  }
}
