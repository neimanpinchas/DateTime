package datetime;

import datetime.DateTime;

using datetime.DateTimeMonthUtils;
using StringTools;


/**
* Utility functions for DateTime
*
*/
@:allow(datetime)
@:access(datetime)
class DateTimeUtils {


    /**
    * Parse string into DateTime
    *
    */
    static private function fromString (str:String) : DateTime {
        var ylength : Int = str.indexOf('-');

        if (ylength < 1 || (str.length - ylength != 6 && str.length - ylength != 15)) {
            throw '`$str` - incorrect date/time format. Should be either `YYYY-MM-DD hh:mm:ss` or `YYYY-MM-DD`';
        }

        if (str.length - ylength == 6) {
            str += ' 00:00:00';
        }

        // YYYY-MM-DD hh:mm:ss
        var year    : Null<Int> = Std.parseInt(str.substr(0, ylength));
        var month   : Null<Int> = Std.parseInt(str.substr(ylength + 1, 2));
        var day     : Null<Int> = Std.parseInt(str.substr(ylength + 4, 2));
        var hour    : Null<Int> = Std.parseInt(str.substr(ylength + 7, 2));
        var minute  : Null<Int> = Std.parseInt(str.substr(ylength + 10, 2));
        var second  : Null<Int> = Std.parseInt(str.substr(ylength + 13, 2));

        if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
            throw '`$str` - incorrect date/time format. Should be either `YYYY-MM-DD hh:mm:ss` or `YYYY-MM-DD`';
        }

        return DateTime.make(year, month, day, hour, minute, second);
    }//function fromString()


    /**
    * Make sure `value` is not less than `min` and not greater than `max`
    *
    */
    static private inline function clamp<T:Float> (value:T, min:T, max:T) : T {
        return (value < min ? min : (value > max ? max : value));
    }//function clamp()


    /**
    * Convert year number (4 digits) to DateTime-timestamp (seconds since 1 a.d.)
    *
    */
    static private function yearToStamp (year:Int) : Float {
        year --;
        return Std.int(year / 4) * DateTime.SECONDS_IN_QUAD + (year - Std.int(year / 4) * 4) * DateTime.SECONDS_IN_YEAR;
    }//function yearToStamp()


    /**
    * Add specified amount of years to `dt`.
    * Returns unix timestamp.
    */
    static private function addYear (dt:DateTime, amount:Int) : Float {
        var year : Int = dt.getYear() + amount;
        var time : Float = dt.getTime() - (dt.yearStart() + dt.getMonth().toSeconds( dt.isLeapYear() ));

        return yearToStamp(year)
                + dt.getMonth().toSeconds(DateTime.isLeap(year))
                + time
                - DateTime.UNIX_EPOCH_DIFF;
    }//function addYear()


    /**
    * Add specified amount of years to `dt`
    *
    */
    static private function addMonth (dt:DateTime, amount:Int) : Float {
        var month : Int = dt.getMonth() + amount;

        if (month >= 12) {
            var years : Int = Std.int(month / 12);
            dt = addYear(dt, years);
            month -= years * 12;
        } else if (month < 0) {
            var years : Int = Std.int(month / 12) - 1;
            dt = addYear(dt, years);
            month -= years * 12;
        }

        var isLeap : Bool = dt.isLeapYear();
        var day    : Int  = clamp(dt.getDay(), 1, month.days(isLeap));

        return dt.yearStart()
                + month.toSeconds(isLeap)
                + (day - 1) * DateTime.SECONDS_IN_DAY
                + dt.getHour() * DateTime.SECONDS_IN_HOUR
                + dt.getMinute() * DateTime.SECONDS_IN_MINUTE
                + dt.getSecond();
    }//function addMonth()


    /**
    * Limited strftime implementation
    *
    */
    static private function strftime (dt:DateTime, format:String) : String {
        var prevPos : Int = 0;
        var pos     : Int    = format.indexOf('%');
        var str     : String = '';

        while (pos >= 0) {
            str += format.substring(prevPos, pos);
            pos ++;

            switch (format.fastCodeAt(pos)) {
                // %d  Two-digit day of the month (with leading zeros) 01 to 31
                case 'd'.code:
                    str += (dt.getDay() + '').lpad('0', 2);
                // %e  Day of the month, with a space preceding single digits.  1 to 31
                case 'e'.code:
                    str += (dt.getDay() + '').lpad(' ', 2);
                // %j  Day of the year, 3 digits with leading zeros    001 to 366
                case 'j'.code:
                    var day : Int = Std.int( (dt.getTime() - dt.yearStart()) / DateTime.SECONDS_IN_DAY ) + 1;
                    str += '$day'.lpad('0', 3);
                // %u  ISO-8601 numeric representation of the day of the week  1 (for Monday) though 7 (for Sunday)
                case 'u'.code:
                    str += dt.getWeekDay(true) + '';
                // %w  Numeric representation of the day of the week   0 (for Sunday) through 6 (for Saturday)
                case 'w'.code:
                    str += dt.getWeekDay() + '';
                // %m  Two digit representation of the month   01 (for January) through 12 (for December)
                case 'm'.code:
                    str += (dt.getMonth() + '').lpad('0', 2);
                // %C  Two digit representation of the century (year divided by 100, truncated to an integer)  19 for the 20th Century
                case 'C'.code:
                    str += (Std.int(dt.getYear() / 100) + '').lpad('0', 2);
                // %y  Two digit representation of the year    Example: 09 for 2009, 79 for 1979
                case 'y'.code:
                    str += (dt.getYear() + '').substr(-2).lpad('0', 2);
                // %Y  Four digit representation for the year  Example: 2038
                case 'Y'.code:
                    str += dt.getYear() + '';
                // %H  Two digit representation of the hour in 24-hour format  00 through 23
                case 'H'.code:
                    str += (dt.getHour() + '').lpad('0', 2);
                // %k  Two digit representation of the hour in 24-hour format, with a space preceding single digits    0 through 23
                case 'k'.code:
                    str += (dt.getHour() + '').lpad(' ', 2);
                // %I  Two digit representation of the hour in 12-hour format  01 through 12
                case 'I'.code:
                    str += (dt.getHour12() + '').lpad('0', 2);
                // %l  (lower-case 'L') Hour in 12-hour format, with a space preceding single digits    1 through 12
                case 'l'.code:
                    str += (dt.getHour12() + '').lpad(' ', 2);
                // %M  Two digit representation of the minute  00 through 59
                case 'M'.code:
                    str += (dt.getMinute() + '').lpad('0', 2);
                // %p  UPPER-CASE 'AM' or 'PM' based on the given time Example: AM for 00:31, PM for 22:23
                case 'p'.code:
                    str += (dt.getHour() < 12 ? 'AM' : 'PM');
                // %P  lower-case 'am' or 'pm' based on the given time Example: am for 00:31, pm for 22:23
                case 'P'.code:
                    str += (dt.getHour() < 12 ? 'am' : 'pm');
                // %r  Same as "%I:%M:%S %p"   Example: 09:34:17 PM for 21:34:17
                case 'r'.code:
                    str += (dt.getHour12() + ':').lpad('0', 3) + (dt.getMinute() + ':').lpad('0', 3) + (dt.getSecond() + '').lpad('0', 2);
                // %R  Same as "%H:%M" Example: 00:35 for 12:35 AM, 16:44 for 4:44 PM
                case 'R'.code:
                    str += (dt.getHour() + ':').lpad('0', 3) + (dt.getMinute() + '').lpad('0', 2);
                // %S  Two digit representation of the second  00 through 59
                case 'S'.code:
                    str += (dt.getSecond() + '').lpad('0', 2);
                // %T  Same as "%H:%M:%S"  Example: 21:34:17 for 09:34:17 PM
                case 'T'.code:
                    str += (dt.getHour() + ':').lpad('0', 3) + (dt.getMinute() + ':').lpad('0', 3) + (dt.getSecond() + '').lpad('0', 2);
                // %D  Same as "%m/%d/%y"  Example: 02/05/09 for February 5, 2009
                case 'D'.code:
                    str += (dt.getMonth() + '/').lpad('0', 3) + (dt.getDay() + '/').lpad('0', 3) + (dt.getYear() + '').substr(-2).lpad('0', 2);
                // %F  Same as "%Y-%m-%d" (commonly used in database datestamps)   Example: 2009-02-05 for February 5, 2009
                case 'F'.code:
                    str += dt.getYear() + '-' + (dt.getMonth() + '-').lpad('0', 3) + (dt.getDay() + '').lpad('0', 2);
                // %s  Unix Epoch Time timestamp Example: 305815200 for September 10, 1979 08:40:00 AM
                case 's'.code:
                    str += dt.getTime() + '';
                // %%  A literal percentage character ("%")
                case '%'.code:
                    str += '%';
            }//switch()

            prevPos = pos + 1;
            pos = format.indexOf('%', pos + 1);
        }
        str += format.substring(prevPos);

        return str;
    }//function strftime()


    /**
    * Instantiating is not allowed
    *
    */
    private function new () : Void {
    }//function new()



}//class DateTimeUtils