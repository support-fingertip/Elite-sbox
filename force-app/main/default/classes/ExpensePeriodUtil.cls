public class ExpensePeriodUtil {

    // Returns a map with 'startDate' and 'endDate' for the cycle that includes 'today'
    public static Map<String, Date> getExpenseCycleDates(Date today, Integer startDay, Integer endDay) {
        if (today == null) today = Date.today();
        Integer S = (startDay == null) ? 25 : startDay;
        Integer E = (endDay == null)   ? 24 : endDay;

        Date startDate = null;
        Date endDate   = null;

        // CASE A: startDay <= endDay (e.g., 1..15). There are two complementary windows:
        //    A: S_of_M .. E_of_M
        //    B: (E+1)_of_M .. (S-1)_of_(M+1)  (if S==1 then B ends at last day of same month)
        if (S <= E) {
            for (Integer offset = 0; offset >= -1; offset--) {
                Integer m = today.month() + offset;
                Integer y = today.year();

                // Candidate A (S..E in same month M)
                Date sA = buildSafeDate(y, m, S);
                Date eA = buildSafeDate(y, m, E);
                if (sA <= today && eA >= today) {
                    startDate = sA; endDate = eA; break;
                }

                // Candidate B (E+1 .. S-1 (may cross to next month))
                Integer lastOfM = lastDayOfMonth(y, m);
                Integer sBDay = E + 1;
                Integer sBMonth = m;
                if (sBDay > lastOfM) {
                    // if E is last day then B would start next month at day 1
                    sBDay = 1;
                    sBMonth = m + 1;
                }

                Integer eBDay;
                Integer eBMonth;
                if (S == 1) {
                    // if S==1, B ends at last day of same month M
                    eBDay = lastOfM;
                    eBMonth = m;
                } else {
                    // normal case: B ends on S-1 of next month
                    eBDay = S - 1;
                    eBMonth = m + 1;
                }

                Date sB = buildSafeDate(y, sBMonth, sBDay);
                Date eB = buildSafeDate(y, eBMonth, eBDay);
               if (sB <= today && eB >= today) {
                   startDate = sB; endDate = eB; break;
               }
            }
        }
        // CASE B: startDay > endDay (cross-month cycle, e.g. 25..24)
        else {
            for (Integer offset = 0; offset >= -1; offset--) {
                Integer m = today.month() + offset;
                Integer y = today.year();

                Date s1 = buildSafeDate(y, m, S);
                Date e1 = buildSafeDate(y, m + 1, E);
                if (s1 <= today && e1 >= today) {
                    startDate = s1; endDate = e1; break;
                }
            }
        }

        // Fallback if not found (safe default similar to your original approach)
        if (startDate == null) {
            if (S > E) {
                if (today.day() <= E) {
                    startDate = buildSafeDate(today.year(), today.month() - 1, S);
                    endDate   = buildSafeDate(today.year(), today.month(), E);
                } else {
                    startDate = buildSafeDate(today.year(), today.month(), S);
                    endDate   = buildSafeDate(today.year(), today.month() + 1, E);
                }
            } else { // S <= E fallback
                if (today.day() >= S && today.day() <= E) {
                    startDate = buildSafeDate(today.year(), today.month(), S);
                    endDate   = buildSafeDate(today.year(), today.month(), E);
                } else if (today.day() < S) {
                    Integer prevMonth = today.month() - 1;
                    startDate = buildSafeDate(today.year(), prevMonth, E + 1);
                    Integer eBDay = (S == 1) ? lastDayOfMonth(today.year(), prevMonth) : (S - 1);
                    endDate   = buildSafeDate(today.year(), prevMonth + 1, eBDay);
                } else {
                    startDate = buildSafeDate(today.year(), today.month(), E + 1);
                    Integer eBDay = (S == 1) ? lastDayOfMonth(today.year(), today.month()) : (S - 1);
                    endDate   = buildSafeDate(today.year(), today.month() + 1, eBDay);
                }
            }
        }

        return new Map<String, Date>{ 'startDate' => startDate, 'endDate' => endDate };
    }

    // Build a Date while normalizing month overflows and clamping day to last day of the month
    private static Date buildSafeDate(Integer year, Integer month, Integer day) {
        Integer yr = year;
        Integer mo = month;
        while (mo > 12) { mo -= 12; yr++; }
        while (mo < 1)  { mo += 12; yr--; }

        Date firstOfMonth = Date.newInstance(yr, mo, 1);
        Integer lastDay = firstOfMonth.addMonths(1).addDays(-1).day();

        Integer dd;
        if (day <= 0) {
            // if caller supplies 0 (S-1 when S==1) fall back to last day of the month
            dd = lastDay;
        } else {
            dd = (day > lastDay) ? lastDay : day;
        }
        return Date.newInstance(yr, mo, dd);
    }

    private static Integer lastDayOfMonth(Integer year, Integer month) {
        Integer yr = year;
        Integer mo = month;
        while (mo > 12) { mo -= 12; yr++; }
        while (mo < 1)  { mo += 12; yr--; }
        Date first = Date.newInstance(yr, mo, 1);
        return first.addMonths(1).addDays(-1).day();
    }
}