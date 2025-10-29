import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMonthlyStats from '@salesforce/apex/TradeCalendarController.getMonthlyStats';
import { CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';


const CURRENCY_FMT = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 1 });
const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const MONTH_INDEX = MONTHS.reduce((m, n, i) => (m[n.toLowerCase()] = i, m), {});


export default class TradeCalendar extends LightningElement {
  @api month; // "October" or 10
  @api year;  // 2025
  @api recordId;

  // Internal nav state
  curMonthIndex;
  curYear;

  // wire data
  statsByKey = {};
  wiredResult; // holds last wire to refresh explicitly

  showPnl;
  

  @wire(CurrentPageReference)
  handlePageRef(pageRef) {
    if (!pageRef) return;

    // 1) Preferred: Experience Cloud record detail pages expose this
    this.recordId =
      pageRef?.attributes?.recordId ||
      // 2) Other possibilities (depends on template/routing)
      pageRef?.state?.recordId ||
      pageRef?.state?.c__recordId ||
      pageRef?.state?.id ||
      // 3) Last resort: parse from URL path (/s/detail/xxxx)
      this._recordIdFromUrl() ||
      this.recordId;
      if (this.recordId === undefined) {
        this.recordId = Id;
      }
  }

  _recordIdFromUrl() {
    try {
      const match = window.location.pathname.match(/\/s\/detail\/([a-zA-Z0-9]{15,18})/);
      return match ? match[1] : null;
    } catch (e) {
      return null;
    }
  }

  connectedCallback() {
    const today = new Date();
    if (typeof this.month === 'number') this.curMonthIndex = Math.min(11, Math.max(0, this.month - 1));
    else if (this.month) {
      const idx = MONTH_INDEX[String(this.month).toLowerCase()];
      this.curMonthIndex = Number.isInteger(idx) ? idx : today.getMonth();
    } else this.curMonthIndex = today.getMonth();

    this.curYear = this.year || today.getFullYear();
  }

  // reactive getters used by wire + UI
  get computedMonthIndex() { return this.curMonthIndex; }
  get computedYear() { return this.curYear; }
  get computedMonthNumber() { return this.curMonthIndex + 1; }
  get monthLabel() { return MONTHS[this.curMonthIndex]; }

  @wire(getMonthlyStats, { year: '$computedYear', month: '$computedMonthNumber', recordId: '$recordId' })
  wiredStats(value) {
    this.wiredResult = value;
    const { data, error } = value;
    if (data) {
      const map = {};
      data.forEach(d => {
        const trades = d.trades || 0;
        const wins = d.wins || 0;
        const total = Number(d.totalPnl || 0);
        const percentage = Number(d.pnlPercentage || 0);
        const winRate = trades ? (wins / trades) * 100 : 0;
        map[d.isoDate] = { amount: Math.round(total), trades, winRate: Math.round(winRate * 10) / 10, percentage: percentage };
      });
      this.statsByKey = map;
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error('getMonthlyStats error', JSON.stringify(error));
      this.statsByKey = {};
    }
  }

  // ---- Header controls ----
  get monthOptions() { return MONTHS.map((label, idx) => ({ label, value: String(idx) })); }
  get curMonthValue() { return String(this.curMonthIndex); }

  async prevMonth() {
    let m = this.curMonthIndex - 1, y = this.curYear;
    if (m < 0) { m = 11; y -= 1; }
    this.curMonthIndex = m; this.curYear = y;
    if (this.wiredResult) await refreshApex(this.wiredResult);
  }

  async nextMonth() {
    let m = this.curMonthIndex + 1, y = this.curYear;
    if (m > 11) { m = 0; y += 1; }
    this.curMonthIndex = m; this.curYear = y;
    if (this.wiredResult) await refreshApex(this.wiredResult);
  }

  async onMonthSelect(e) {
    this.curMonthIndex = parseInt(e.detail.value, 10);
    if (this.wiredResult) await refreshApex(this.wiredResult);
  }

  async onYearInput(e) {
    const v = parseInt(e.target.value, 10);
    if (!isNaN(v)) {
      this.curYear = v;
      if (this.wiredResult) await refreshApex(this.wiredResult);
    }
  }

  goToday() {
    const t = new Date();
    this.curMonthIndex = t.getMonth();
    this.curYear = t.getFullYear();
    if (this.wiredResult) refreshApex(this.wiredResult);
  }

  // ---- Build grid by weeks (7 days + 1 total cell per row) ----
  get weeks() {
    const y = this.computedYear;
    const m = this.computedMonthIndex;
    const first = new Date(y, m, 1);
    const startWeekday = first.getDay(); // 0..6 (Sun..Sat)
    const daysInMonth = new Date(y, m + 1, 0).getDate();

    const totalCells = 42; // 6 rows * 7 cols
    const prevMonthDays = startWeekday;
    const pad = n => (n < 10 ? '0' + n : '' + n);
    const keyOf = (yr, moIdx, day) => `${yr}-${pad(moIdx + 1)}-${pad(day)}`;
    const prevLastDate = new Date(y, m, 0).getDate();

    const allCells = [];
    for (let i = 0; i < totalCells; i++) {
        let inMonth = false,
            dayNum,
            dateStr;

        if (i < prevMonthDays) {
            // previous month
            dayNum = prevLastDate - prevMonthDays + 1 + i;
            const prev = new Date(y, m, 0);
            dateStr = keyOf(prev.getFullYear(), prev.getMonth(), dayNum);
        } else if (i < prevMonthDays + daysInMonth) {
            // current month
            inMonth = true;
            dayNum = i - prevMonthDays + 1;
            dateStr = keyOf(y, m, dayNum);
        } else {
            // next month
            const d = i - (prevMonthDays + daysInMonth) + 1;
            const next = new Date(y, m + 1, 1);
            dayNum = d;
            dateStr = keyOf(next.getFullYear(), next.getMonth(), dayNum);
        }

        const raw = this.statsByKey[dateStr];

        const data = raw
            ? {
                  amount: raw.amount,
                  percentage: raw.percentage,
                  percentFormatted: `${raw.percentage}%`,
                  trades: raw.trades,
                  winRate: Math.round((raw.winRate + Number.EPSILON) * 10) / 10, // 1dp
                  amountFormatted: CURRENCY_FMT.format(raw.amount)
              }
            : null;

        const classList = [
            'tc__cell',
            inMonth ? '' : 'tc__cell--muted',
            data && data.amount > 0 ? 'tc__cell--pos' : '',
            data && data.amount < 0 ? 'tc__cell--neg' : ''
        ]
            .filter(Boolean)
            .join(' ');

        allCells.push({
            key: dateStr,
            inMonth,
            classList,
            dayNum,
            data,
            title: data
                ? `${dateStr}: ${data.amountFormatted} • ${data.trades} trades • ${data.winRate}%`
                : dateStr
        });
    }

    // chunk into 6 weeks
    const weeks = [];
    for (let r = 0; r < 6; r++) {
        const days = allCells.slice(r * 7, r * 7 + 7);

        // aggregate weekly metrics
        let totalAmount = 0;
        let totalTrades = 0;
        let totalWins = 0;
        let totalLosses = 0;
        let totalPercentage = 0; // sum of percentage field

        for (const c of days) {
            if (c.inMonth && c.data) {
                // money
                totalAmount += c.data.amount;

                // trades
                const tradesToday = c.data.trades ?? 0;
                totalTrades += tradesToday;

                // derive wins/losses for the day from winRate
                const winsToday = Math.round(
                    tradesToday * (c.data.winRate / 100)
                );
                const lossesToday = tradesToday - winsToday;
                totalWins += winsToday;
                totalLosses += lossesToday;

                // percentage
                totalPercentage += c.data.percentage ?? 0;
            }
        }

        // compute weekly win rate
        const weeklyWinRate =
            totalTrades > 0
                ? Math.round(
                      ((totalWins / totalTrades) * 100 + Number.EPSILON) * 10
                  ) / 10
                : 0;

        // formatters
        const totalFormatted = CURRENCY_FMT.format(totalAmount);
        const percentFormatted = `${Math.round(
            (totalPercentage + Number.EPSILON) * 100
        ) / 100}%`; // 2dp on the sum %

        const data = `${totalTrades} trades (${totalWins}W / ${totalLosses}L, ${weeklyWinRate}%)`;

        weeks.push({
            row: r,
            days,
            total: totalAmount,
            totalTrades,
            totalWins,
            totalLosses,
            weeklyWinRate,
            totalPercentage,
            totalFormatted,
            percentFormatted,
            data
        });
    }

    return weeks;
}

  // ---- Get month total ----
  get monthTotal() {
    // sum all amounts in the current month (ignore muted cells)
    const y = this.computedYear;
    const m = this.computedMonthIndex;
    const pad = n => (n < 10 ? '0' + n : '' + n);

    let sum = 0;
    for (const [dateStr, d] of Object.entries(this.statsByKey)) {
      const [yr, mo] = dateStr.split('-').map(Number);
      if (yr === y && mo === m + 1) {
        sum += d.amount || 0;
      }
    }
    return sum;
  }

  get monthTotalFormatted() {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 1
    }).format(this.monthTotal);
  }

  handleTogglePnl() {
    this.showPnl = !this.showPnl;
  }
}
