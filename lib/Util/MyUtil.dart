import 'dart:math';

import 'package:intl/intl.dart';

class MyUtil{
    static double getWidthWithFontSize(double fontSize){
        return fontSize * 0.5;
    }

    static double getHeightWithFontSize(double fontSize){
        return fontSize * 1.2;
    }

    static int getMonthIntFromString(String monthString){

        String _monthString = monthString.toLowerCase();

        int month = _monthString == "january" ? 1 :
                    _monthString == "february" ? 2 :
                    _monthString == "march" ? 3 :
                    _monthString == "april" ? 4 :
                    _monthString == "may" ? 5 :
                    _monthString == "june" ? 6 :
                    _monthString == "july" ? 7 :
                    _monthString == "august" ? 8 :
                    _monthString == "september" ? 9 :
                    _monthString == "october" ? 10 :
                    _monthString == "november" ? 11 :
                    _monthString == "december" ? 12 : -1;

        return month;
    }

    static String getMonthStringFromInt(int month, {int subStringLength = -1}){


      String monthString = month == 1 ? "January" :
                            month == 2 ? "February" :
                            month == 3 ? "March" :
                            month == 4 ? "April" :
                            month == 5 ? "May" :
                            month == 6 ? "June" :
                            month == 7 ? "July" :
                            month == 8 ? "August" :
                            month == 9 ? "September" :
                            month == 10 ? "October" :
                            month == 11 ? "November" :
                            month == 12 ? "December" : throw Exception();

      if(subStringLength != -1){
        int _subStringLength = min(monthString.length, subStringLength);
        monthString = monthString.substring(0, _subStringLength);
      }

      return monthString;
    }

    static DateFormat getDefaultDateFormat(){
      return DateFormat("yyyy-MM-dd");
    }

    static String padStringLeft(String oriString, int minStringLength, String pad){

        if(pad.length > 1){
          throw Exception();
        }

        String result = oriString;

        if(oriString.length < minStringLength){
          int diff = minStringLength - oriString.length;

          for(int i = diff; i > 0; i--){
            result = pad+result;
          }
        }

        return result;
    }
}