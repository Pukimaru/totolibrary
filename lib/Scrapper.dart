import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/DataManager.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Object/PrizeObj.dart';
import 'package:toto/Util/MyConst.dart';
import 'package:toto/Util/MyUtil.dart';

import 'Progressor.dart';
import 'Util/Pair.dart';

class Scrapper implements Progressor{

  static final Scrapper _instance = Scrapper._internal();
  static const Duration _defaultTimeOut = Duration(seconds: 45);

  Scrapper._internal();

  bool _isCancelling = false;
  bool isActive = true;
  Browser? browser;

  final StreamController<double> _scrapProgressStreamController = StreamController.broadcast();
  final StreamController<Pair<String,DayPrizesObj?>> _scrapDetailStreamController = StreamController.broadcast();

  static Scrapper getInstance(){
    return _instance;
  }

  Future<void> startScrapDriver() async {

    await closeScrapDriver();

    print("starting");
    browser = await puppeteer.launch(
      headless: true,
      defaultViewport: null,
      timeout: const Duration(minutes: 2),
      //userDataDir: "./tmp",
    );
    print("started");
  }

  Future<void> closeScrapDriver() async {
    if(browser != null){
      if(browser!.isConnected){
        print("disposing browser");
        await browser!.close();
      }

      browser = null;
    }
  }

  Future<ScrapDetail> scrapAll(Map<String, List<DateTime>> missingEntryMap) async {

      /*ScrapResult scrapResult = ScrapResult.Success;
      int doneCount = 0;
      int toDoCount = 0;
      List<DayPrizesObj> scrappedDayPrizesObjList = [];

      for(MapEntry<String, List<DateTime>> entry in missingEntryMap.entries){
          String type = entry.key;
          List<DateTime> dateTimeList = entry.value;

          toDoCount += dateTimeList.length;

          ScrapDetail? scrapDetail;

          switch(type){
            case PrizeObj.TYPE_MAGNUM4D:
              scrapDetail = await scrapMAGNUM(dateTimeList, doneCount, toDoCount);
              break;

            case PrizeObj.TYPE_TOTO:
              scrapDetail = await scrapTOTO(dateTimeList, doneCount, toDoCount);
              break;

            case PrizeObj.TYPE_DAMACAI:
              scrapDetail = await scrapDAMACAI(dateTimeList, doneCount, toDoCount);
              break;
          }

          if(scrapDetail != null){
              scrapResult = scrapDetail.scrapResult != ScrapResult.Success ? scrapDetail.scrapResult : scrapResult;
              doneCount = scrapDetail.doneCount;
              scrappedDayPrizesObjList.addAll(scrapDetail.dayPrizesObjList);
          }
          if(_isCancelling){
              return ScrapDetail(scrapResult: scrapResult, dayPrizesObjList: scrappedDayPrizesObjList, doneCount: scrappedDayPrizesObjList.length);
          }
      }*/

      List<DateTime> missingDateList = [];

      for(MapEntry<String, List<DateTime>> entry in missingEntryMap.entries){
        List<DateTime> dateTimeList = entry.value;

        for(DateTime dateTime in dateTimeList){
          if(!missingDateList.contains(dateTime)){
            missingDateList.add(dateTime);
          }
        }
      }

      return await scrapAIO(missingDateList);
  }
  Future<ScrapDetail> scrapAIO(List<DateTime> dateTimeList) async {
    List<DayPrizesObj> dayPrizesObjList = [];
    ScrapResult scrapResult = ScrapResult.Success;

    Map<String, List<DateTime>> invalidDateMap = {};

    //region start browser
    //Start browser if needed
    if (browser == null || !browser!.isConnected) {
      print("restarting browser");
      await startScrapDriver();
    }

    List<Page> pages = await browser!.pages;

    if (pages.isEmpty) {
      browser!.newPage();
    }
    final Page page = pages[0];
    page.defaultTimeout = const Duration(seconds: 120);
    page.defaultNavigationTimeout = _defaultTimeOut;
    //final page = await browser!.newPage();
    print("going for Magnum");
    //endregion

    int doneCount = 0;

    try{
      for(DateTime dateTime in dateTimeList){

        bool runSuccess = true;
        try{
          String lookForDateString = DateFormat("yyyy-MM-dd").format(dateTime);

          print("going url: ${"https://www.4dmoon.com/past-results/$lookForDateString"}");

          //await page.goto("https://giret.moh.gov.my/");
          page.goto(
            "https://www.4dmoon.com/past-results/$lookForDateString",
            wait: Until.load,
            timeout: _defaultTimeOut
          );

          //Wait for page to load
          //Somehow await page.goto hangs for 4dmoon website
          //sleep(Duration(seconds: 3));

          String westMalaysiaButtonSelector = "body > div.main > div > div > ul > li.active > a";
          await page.waitForSelector(westMalaysiaButtonSelector);
          await page.click(westMalaysiaButtonSelector);

          Duration timeout = const Duration(milliseconds: 500);

          //region Magnum
          String firstPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(1)";
          String secondPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(2)";
          String thirdPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(3)";

          bool hasMagnumDraw = false;
          try{
            page.defaultTimeout = timeout;
            await page.waitForSelector(firstPrizeLabelSelector);
            hasMagnumDraw = true;
          }catch(e){
            page.defaultTimeout = _defaultTimeOut;
          }
          page.defaultTimeout = _defaultTimeOut;

          DayPrizesObj? magnumDayPrizesObj;
          //region Generate DayPrizesObj [MAGNUM]
          if(hasMagnumDraw){
            magnumDayPrizesObj = DayPrizesObj();

            magnumDayPrizesObj.dateTime = dateTime;
            magnumDayPrizesObj.firstPrize = await getElementTextContent(page, selector: firstPrizeLabelSelector);
            magnumDayPrizesObj.secondPrize = await getElementTextContent(page, selector: secondPrizeLabelSelector);
            magnumDayPrizesObj.thirdPrize = await getElementTextContent(page, selector: thirdPrizeLabelSelector);
            magnumDayPrizesObj.type = PrizeObj.TYPE_MAGNUM4D;

            print("magnum Result: $lookForDateString: ${magnumDayPrizesObj.firstPrize}-${magnumDayPrizesObj.secondPrize}-${magnumDayPrizesObj.thirdPrize}");

            dayPrizesObjList.add(magnumDayPrizesObj);
          }else{
            if(!invalidDateMap.containsKey(PrizeObj.TYPE_MAGNUM4D)){
              invalidDateMap[PrizeObj.TYPE_MAGNUM4D] = [];
            }

            if(
              !(
                DataManager.getInstance().NoDrawDateMap.containsKey(PrizeObj.TYPE_MAGNUM4D) &&
                DataManager.getInstance().NoDrawDateMap[PrizeObj.TYPE_MAGNUM4D]!.contains(dateTime)
              )
            ){
              invalidDateMap[PrizeObj.TYPE_MAGNUM4D]!.add(dateTime);
            }

          }
          broadCastDayPrizesObj(dateTime, PrizeObj.TYPE_MAGNUM4D, magnumDayPrizesObj);
          //endregion
          //endregion

          //region ToTo
          firstPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.lpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(1)";
          secondPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.lpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(2)";
          thirdPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.lpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(3)";

          bool hasTOTODraw = false;
          try{
            page.defaultTimeout = timeout;
            await page.waitForSelector(firstPrizeLabelSelector);
            hasTOTODraw = true;
          }catch(e){
            page.defaultTimeout = _defaultTimeOut;
          }
          page.defaultTimeout = _defaultTimeOut;

          //region Generate DayPrizesObj [ToTo]
          DayPrizesObj? totoDayPrizesObj;
          if(hasTOTODraw){
            totoDayPrizesObj = DayPrizesObj();

            totoDayPrizesObj.dateTime = dateTime;
            totoDayPrizesObj.firstPrize = await getElementTextContent(page, selector: firstPrizeLabelSelector);
            totoDayPrizesObj.secondPrize = await getElementTextContent(page, selector: secondPrizeLabelSelector);
            totoDayPrizesObj.thirdPrize = await getElementTextContent(page, selector: thirdPrizeLabelSelector);
            totoDayPrizesObj.type = PrizeObj.TYPE_TOTO;

            print("toto Result: $lookForDateString: ${totoDayPrizesObj.firstPrize}-${totoDayPrizesObj.secondPrize}-${totoDayPrizesObj.thirdPrize}");

            dayPrizesObjList.add(totoDayPrizesObj);
          }else{
            if(!invalidDateMap.containsKey(PrizeObj.TYPE_TOTO)){
              invalidDateMap[PrizeObj.TYPE_TOTO] = [];
            }

            if(
            !(
              DataManager.getInstance().NoDrawDateMap.containsKey(PrizeObj.TYPE_TOTO) &&
              DataManager.getInstance().NoDrawDateMap[PrizeObj.TYPE_TOTO]!.contains(dateTime)
            )
            ){
              invalidDateMap[PrizeObj.TYPE_TOTO]!.add(dateTime);
            }
          }
          broadCastDayPrizesObj(dateTime, PrizeObj.TYPE_TOTO, totoDayPrizesObj);
          //endregion
          //endregion

          //region Damacai
          firstPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.rpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(1)";
          secondPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.rpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(2)";
          thirdPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.rpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(3)";

          //6D
          String firstPrize6DLabelSelector = "#sectionA > div:nth-child(5) > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(1)";
          String secondPrize6DLabelSelector = "#sectionA > div:nth-child(5) > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(2)";
          String thirdPrize6DLabelSelector = "#sectionA > div:nth-child(5) > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(3)";


          bool hasDAMACAIDraw = false;
          try{
            page.defaultTimeout = timeout;
            await page.waitForSelector(firstPrizeLabelSelector);
            hasDAMACAIDraw = true;
          }catch(e){
            page.defaultTimeout = _defaultTimeOut;
          }
          page.defaultTimeout = _defaultTimeOut;

          //Verify 6D draw available
          bool has6DDraw = false;
          try{
            page.defaultTimeout = timeout;
            await page.waitForSelector(firstPrize6DLabelSelector);
            has6DDraw = true;
          }catch(e){
            page.defaultTimeout = _defaultTimeOut;
          }
          page.defaultTimeout = _defaultTimeOut;

          //region Generate DayPrizesObj [Damacai]
          DayPrizesObj? damacaiDayPrizesObj;
          if(hasDAMACAIDraw){
            damacaiDayPrizesObj = DayPrizesObj();

            damacaiDayPrizesObj.dateTime = dateTime;
            damacaiDayPrizesObj.firstPrize = await getElementTextContent(page, selector: firstPrizeLabelSelector);
            damacaiDayPrizesObj.secondPrize = await getElementTextContent(page, selector: secondPrizeLabelSelector);
            damacaiDayPrizesObj.thirdPrize = await getElementTextContent(page, selector: thirdPrizeLabelSelector);
            damacaiDayPrizesObj.type = PrizeObj.TYPE_DAMACAI;

            if(has6DDraw){
              damacaiDayPrizesObj.firstPrize6D = await getElementTextContent(page, selector: firstPrize6DLabelSelector);
              damacaiDayPrizesObj.secondPrize6D = await getElementTextContent(page, selector: secondPrize6DLabelSelector);
              damacaiDayPrizesObj.thirdPrize6D = await getElementTextContent(page, selector: thirdPrize6DLabelSelector);
            }

            print("damacai Result: $lookForDateString: ${damacaiDayPrizesObj.firstPrize}-${damacaiDayPrizesObj.secondPrize}-${damacaiDayPrizesObj.thirdPrize}");

            dayPrizesObjList.add(damacaiDayPrizesObj);
          }else{
            if(!invalidDateMap.containsKey(PrizeObj.TYPE_DAMACAI)){
              invalidDateMap[PrizeObj.TYPE_DAMACAI] = [];
            }

            if(
            !(
                DataManager.getInstance().NoDrawDateMap.containsKey(PrizeObj.TYPE_DAMACAI) &&
                    DataManager.getInstance().NoDrawDateMap[PrizeObj.TYPE_DAMACAI]!.contains(dateTime)
            )
            ){
              invalidDateMap[PrizeObj.TYPE_DAMACAI]!.add(dateTime);
            }
          }
          broadCastDayPrizesObj(dateTime, PrizeObj.TYPE_DAMACAI, damacaiDayPrizesObj);
          //endregion
          //endregion

          if(_isCancelling){
            _isCancelling = false;
            scrapResult = ScrapResult.Canceled;
            break;
          }

        }catch(e, ex){
          print("error scrapping run: |${e}| |${ex}|");
          runSuccess = false;
        }finally{
          //region calculate progress
          if(runSuccess){
            doneCount++;
            double progress = doneCount.toDouble()/dateTimeList.length.toDouble();
            _scrapProgressStreamController.sink.add(progress);
          }else{
            throw Exception("error scrapping run");
          }
          //endregion
        }
      }

    }catch(e, ex){
      print("error scrapping: |$e| |$ex|");
      scrapResult = ScrapResult.Error;
    }

    //region update invalidDateStringMap
    if(invalidDateMap.isNotEmpty){
      DataManager.getInstance().updateInvalidDate(invalidDateMap);
    }
    //endregion

    await closeScrapDriver();

    return ScrapDetail(scrapResult: scrapResult, dayPrizesObjList: dayPrizesObjList, doneCount: doneCount);
  }

  /*
  Future<ScrapDetail> scrapMAGNUM(List<DateTime> dateTimeList, int doneCount, int toDoCount) async {
    List<DayPrizesObj> dayPrizesObjList = [];
    ScrapResult scrapResult = ScrapResult.Success;

    List<DateTime> invalidDateList = [];

    //region start browser
    //Start browser if needed
    if (browser == null || !browser!.isConnected) {
      print("restarting browser");
      await startScrapDriver();
    }

    List<Page> pages = await browser!.pages;

    if (pages.isEmpty) {
      browser!.newPage();
    }
    final Page page = pages[0];
    page.defaultTimeout = const Duration(seconds: 120);
    page.defaultNavigationTimeout = _defaultTimeOut;
    //final page = await browser!.newPage();
    print("going for Magnum");
    //endregion

    try{
      for(DateTime dateTime in dateTimeList){

        String lookForDateString = DateFormat("yyyy-MM-dd").format(dateTime);

        await page.goto("https://www.4dmoon.com/past-results/$lookForDateString");

        String westMalaysiaButtonSelector = "body > div.main > div > div > ul > li.active > a";
        await page.waitForSelector(westMalaysiaButtonSelector);
        await page.click(westMalaysiaButtonSelector);

        String firstPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(1)";
        String secondPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(2)";
        String thirdPrizeLabelSelector = "#sectionA > div.col-lg-4.col-md-4.col-sm-6.col-xs-12.col-xxs-12.mpad.text-center > div > table > tbody > tr:nth-child(2) > td > table > tbody > tr:nth-child(2) > td:nth-child(3)";

        try{
          page.defaultTimeout = const Duration(seconds: 15);
          await page.waitForSelector(firstPrizeLabelSelector);
        }catch(e){
          page.defaultTimeout = _defaultTimeOut;
          invalidDateList.add(dateTime);
          continue;
        }
        page.defaultTimeout = _defaultTimeOut;

        //region Generate DayPrizesObj
        DayPrizesObj dayPrizesObj = DayPrizesObj();

        dayPrizesObj.dateTime = dateTime;
        dayPrizesObj.firstPrize = await getElementTextContent(page, selector: firstPrizeLabelSelector);
        dayPrizesObj.secondPrize = await getElementTextContent(page, selector: secondPrizeLabelSelector);
        dayPrizesObj.thirdPrize = await getElementTextContent(page, selector: thirdPrizeLabelSelector);
        dayPrizesObj.type = PrizeObj.TYPE_MAGNUM4D;

        print("result: $lookForDateString");
        print(dayPrizesObj.firstPrize);
        print(dayPrizesObj.secondPrize);
        print(dayPrizesObj.thirdPrize);

        dayPrizesObjList.add(dayPrizesObj);
        //endregion


        /*try{
          String lookForDateString = DateFormat("dd/MM/yyyy").format(dateTime);

          String datePicker = "#result-filters > div > div > div > label";
          await page.waitForSelector(datePicker);
          await page.click(datePicker);
          print("clicked");

          String yearMonthLabel = "body > div.datepicker.datepicker-dropdown.dropdown-menu.datepicker-orient-left.datepicker-orient-bottom > div.datepicker-days > table > thead > tr:nth-child(2) > th.datepicker-switch";

          bool reached = false;

          while(!reached){
            //await page.waitForSelector(yearMonthLabel);
            print("hi");
            await typeInElement(page, "#filter-date-from", "2022-02-01");
            String displayYearMonthString = await getElementTextContent(page, selector: yearMonthLabel);
            String displayYearString = displayYearMonthString.replaceAll(RegExp(r"[^0-9]"), "");
            String displayMonthString = displayYearMonthString.replaceAll(RegExp(r"[^A-Za-z]"), "");

            print(displayYearMonthString);

            int displayYearInt = int.parse(displayYearString);
            int displayMonthInt = MyUtil.getMonthIntFromString(displayMonthString);

            String prevButtonString = "body > div.datepicker.datepicker-dropdown.dropdown-menu.datepicker-orient-left.datepicker-orient-bottom > div.datepicker-days > table > thead > tr:nth-child(2) > th.prev";
            String nextButtonString = "body > div.datepicker.datepicker-dropdown.dropdown-menu.datepicker-orient-left.datepicker-orient-bottom > div.datepicker-days > table > thead > tr:nth-child(2) > th.next";

            if(displayYearInt < dateTime.year || displayMonthInt < dateTime.month){
                await page.click(prevButtonString);
                print("prev");
            }else if(displayYearInt > dateTime.year || displayMonthInt > dateTime.month){
                await page.click(nextButtonString);
                print("next");
            }else{
                print("reached yearmonth");
                reached = true;
            }
          }


          //region pick day
          String table = "body > div.datepicker.datepicker-dropdown.dropdown-menu.datepicker-orient-left.datepicker-orient-bottom > div.datepicker-days > table > tbody";
          await page.waitForSelector(table);
          ElementHandle tableElement = await page.$(table);
          List<ElementHandle> cellElementList = await tableElement.$x(".//td");

          for(ElementHandle element in cellElementList){
              String className = await getElementClass(page, elementHandle: element);
              String textContent = await getElementTextContent(page, elementHandle: element);
              if(className.contains("old")){
                continue;
              }

              if(textContent == "${dateTime.day}"){
                if(className.contains("active")){
                  await element.click();
                  break;
                }else{
                  invalidDateList.add(dateTime);
                }
              }
          }
          //endregion


          //region wait for date to load
          List<ElementHandle> dateLabelList = await page.$$("div:nth-child(1) > div > div > h3 > span.date.margin-left-5");

          int maxWaitInMilliSecond = 15000;
          int waitIntervalInMilliSeconds = 500;
          int milliSecondsWaited = 0;
          bool dateLoaded = false;
          while(!dateLoaded && milliSecondsWaited < maxWaitInMilliSecond){
            for(ElementHandle dateLabelElement in dateLabelList){
              String dateString = (await getElementTextContent(page, elementHandle: dateLabelElement)).replaceAll(RegExp(r'[^0-9/]'), '');

              if(dateString == lookForDateString){
                dateLoaded = true;
                break;
              }
            }

            await Future.delayed(Duration(milliseconds: waitIntervalInMilliSeconds));
          }
          //endregion

          if(!dateLoaded){
            throw Exception();
          }

          List<ElementHandle> firstPriceLabelList = await page.$$("div:nth-child(1) > span.result-number-lg.btn-number-details");
          String firstPrizeString = "";
          for(ElementHandle firstPriceLabel in firstPriceLabelList){
              String textContent = await getElementTextContent(page, elementHandle: firstPriceLabel);

              print("firstPrize: |$textContent|");

              if(textContent.replaceAll(RegExp(r"[^0-9]"), "").length == 4){
                  firstPrizeString = textContent;
                  break;
              }
          }

          List<ElementHandle> secondPriceLabelList = await page.$$("div:nth-child(2) > span.result-number-lg.btn-number-details");
          String secondPrizeString = "";
          for(ElementHandle secondPriceLabel in secondPriceLabelList){
            String textContent = await getElementTextContent(page, elementHandle: secondPriceLabel);

            print("secondPrize: |$textContent|");

            if(textContent.replaceAll(RegExp(r"[^0-9]"), "").length == 4){
              secondPrizeString = textContent;
              break;
            }
          }

          List<ElementHandle> thirdPriceLabelList = await page.$$("div:nth-child(3) > span.result-number-lg.btn-number-details");
          String thirdPrizeString = "";
          for(ElementHandle thirdPriceLabel in thirdPriceLabelList){
            String textContent = await getElementTextContent(page, elementHandle: thirdPriceLabel);

            print("thirdPrize: |$textContent|");

            if(textContent.replaceAll(RegExp(r"[^0-9]"), "").length == 4){
              thirdPrizeString = textContent;
              break;
            }
          }

          if(firstPrizeString.isNotEmpty && secondPrizeString.isNotEmpty && thirdPrizeString.isNotEmpty){
            //region Generate DayPrizesObj
            DayPrizesObj dayPrizesObj = DayPrizesObj();

            dayPrizesObj.dateTime = dateTime;
            dayPrizesObj.firstPrize = firstPrizeString;
            dayPrizesObj.secondPrize = secondPrizeString;
            dayPrizesObj.thirdPrize = thirdPrizeString;
            dayPrizesObj.type = PrizeObj.TYPE_MAGNUM4D;

            print("result: $lookForDateString");
            print(dayPrizesObj.firstPrize);
            print(dayPrizesObj.secondPrize);
            print(dayPrizesObj.thirdPrize);

            dayPrizesObjList.add(dayPrizesObj);
            //endregion
          }else{
            throw Exception();
          }

          if(_isCancelling){
            _isCancelling = false;
            scrapResult = ScrapResult.Canceled;
            break;
          }
        }finally{
          //region calculate progress
          doneCount++;
          double progress = doneCount.toDouble()/toDoCount.toDouble();
          _scrapStreamController.sink.add(progress);
          //endregion
        }*/

      }

    }catch(e, ex){
      print(ex);
      scrapResult = ScrapResult.Error;
    }

    //region update invalidDateStringMap
    if(invalidDateList.isNotEmpty){
      DataManager.getInstance().updateInvalidDate({PrizeObj.TYPE_TOTO : invalidDateList});
    }

    //endregion

    return ScrapDetail(scrapResult: scrapResult, dayPrizesObjList: dayPrizesObjList, doneCount: doneCount);
  }
  Future<ScrapDetail> scrapTOTO(List<DateTime> dateTimeList, int doneCount, int toDoCount) async {
    List<DayPrizesObj> dayPrizesObjList = [];
    ScrapResult scrapResult = ScrapResult.Success;

    List<DateTime> invalidDateList = [];

    //region start browser
    //Start browser if needed
    if (browser == null || !browser!.isConnected) {
      print("restarting browser");
      await startScrapDriver();
    }

    List<Page> pages = await browser!.pages;

    if (pages.isEmpty) {
      browser!.newPage();
    }
    final Page page = pages[0];
    page.defaultTimeout = const Duration(seconds: 120);
    page.defaultNavigationTimeout = _defaultTimeOut;
    //final page = await browser!.newPage();
    print("going for toto");
    //endregion

    try{
      await page.goto("https://www.sportstoto.com.my/results_past.asp");

      for(DateTime dateTime in dateTimeList){

        try{
            String lookForDateString = DateFormat("d/M/yyyy").format(dateTime);
            String monthStringFull = MyUtil.getMonthStringFromInt(dateTime.month);
            String monthStringShort = MyUtil.getMonthStringFromInt(dateTime.month, subStringLength: 3);

            //Select year
            String yearSelectorString = "#content_left2 > form > table > tbody > tr > td:nth-child(2) > select";
            await page.waitForSelector(yearSelectorString);
            await selectElement_Custom(page, yearSelectorString, ["${dateTime.year}"]);

            print("selected ${dateTime.year}");

            //Select month
            String monthSelectorString = "#content_left2 > form > table > tbody > tr > td:nth-child(1) > select";
            await page.waitForSelector(monthSelectorString);
            await selectElement_Custom(page, monthSelectorString, [monthStringShort]);


            //region pick day
            await page.waitForSelector("#Calendar1 > tbody");
            ElementHandle tableElement = await page.$("#Calendar1 > tbody");
            List<ElementHandle> cellElementList = await tableElement.$x(".//td");

            String targetString = "$monthStringFull ${dateTime.day}, ${dateTime.year}";
            for(ElementHandle element in cellElementList){
              String title = await getElementContent(page, "title", elementHandle: element, throwErrorIfInvalidTitle: false);

              String textContent = await getElementTextContent(page, elementHandle: element);

              if(title == targetString){

                if(textContent.contains("/")){
                  print("clicked");
                  await clickWithFunction(page, elementHandle: element);
                  //await element.click();
                }else{
                  throw Exception();
                }

              }
            }
            //endregion

            List<ElementHandle> popUpContainerList = await page.$$("#popup_container");

            bool invalidDate = true;
            for(ElementHandle popContainer in popUpContainerList){
              ElementHandle dateLabelElement = await popContainer.$("#popup_container > div > div.col-sm-12 > div > div.col-sm-4.col-xs-6");
              String dateString = (await getElementTextContent(page, elementHandle: dateLabelElement)).replaceAll(RegExp(r'[^0-9/]'), '');

              ElementHandle modalLabelElement = await popContainer.$("#popup_container > div > div.col-sm-12 > div > div.visible-xs.col-xs-6 > span");
              String modalString = (await getElementTextContent(page, elementHandle: modalLabelElement)).split("/").first;

              if(dateString == lookForDateString){
                ElementHandle closeButtonElement = await page.$("#myModal$modalString > div > div > div.modal-header > h4 > button");

                ElementHandle firstPrizeElement = await popContainer.$("#popup_container > div > div.row > div:nth-child(1) > div:nth-child(1) > div.col-sm-12 > div > div:nth-child(1) > div.txt_black2.row > div:nth-child(1)");
                ElementHandle secondPrizeElement = await popContainer.$("#popup_container > div > div.row > div:nth-child(1) > div:nth-child(1) > div.col-sm-12 > div > div:nth-child(1) > div.txt_black2.row > div:nth-child(2)");
                ElementHandle thirdPrizeElement = await popContainer.$("#popup_container > div > div.row > div:nth-child(1) > div:nth-child(1) > div.col-sm-12 > div > div:nth-child(1) > div.txt_black2.row > div:nth-child(3)");

                //region Generate DayPrizesObj
                DayPrizesObj dayPrizesObj = DayPrizesObj();

                dayPrizesObj.dateTime = dateTime;
                dayPrizesObj.firstPrize = await getElementTextContent(page, elementHandle: firstPrizeElement);
                dayPrizesObj.secondPrize = await getElementTextContent(page, elementHandle: secondPrizeElement);
                dayPrizesObj.thirdPrize = await getElementTextContent(page, elementHandle: thirdPrizeElement);
                dayPrizesObj.type = PrizeObj.TYPE_TOTO;

                print("result: $dateString");
                print(dayPrizesObj.firstPrize);
                print(dayPrizesObj.secondPrize);
                print(dayPrizesObj.thirdPrize);

                dayPrizesObjList.add(dayPrizesObj);
                invalidDate = false;
                //endregion

                await clickWithFunction(page, elementHandle: closeButtonElement);
                break;
              }
            }


            if(invalidDate){
              invalidDateList.add(dateTime);
              print("invalid Date $dateTime");
              continue;
            }

            if(_isCancelling){
              _isCancelling = false;
              scrapResult = ScrapResult.Canceled;
              break;
            }
        }finally{
          //region calculate progress
          doneCount++;
          double progress = doneCount.toDouble()/toDoCount.toDouble();
          _scrapStreamController.sink.add(progress);
          //endregion
        }

      }

    }catch(e, ex){
      print(ex);
      scrapResult = ScrapResult.Error;
    }

    //region update invalidDateStringMap
    if(invalidDateList.isNotEmpty){
      DataManager.getInstance().updateInvalidDate({PrizeObj.TYPE_TOTO : invalidDateList});
    }
    //endregion

    return ScrapDetail(scrapResult: scrapResult, dayPrizesObjList: dayPrizesObjList, doneCount: doneCount);
  }
  Future<ScrapDetail> scrapDAMACAI(List<DateTime> dateTimeList, int doneCount, int toDoCount) async {
    List<DayPrizesObj> dayPrizesObjList = [];
    ScrapResult scrapResult = ScrapResult.Success;
    
    List<DateTime> invalidDateList = [];

    //region start browser
    //Start browser if needed
    if (browser == null || !browser!.isConnected) {
      print("restarting browser");
      await startScrapDriver();
    }

    List<Page> pages = await browser!.pages;

    if (pages.isEmpty) {
      browser!.newPage();
    }
    final Page page = pages[0];
    page.defaultTimeout = _defaultTimeOut;
    page.defaultNavigationTimeout = _defaultTimeOut;
    //final page = await browser!.newPage();
    print("going for damacai");
    //endregion

    print(dateTimeList);

    try{
      await page.goto("https://www.damacai.com.my/past-draw-result");

      for(DateTime dateTime in dateTimeList){

        try{
          String lookForDateString = DateFormat("dd/MM/yyyy").format(dateTime);

          bool resultLoaded = false;
          const int maxAttempt = 5;
          int attemptCount = 0;

          while(!resultLoaded && attemptCount < maxAttempt){
            String datePickerString = "#datetimepicker1";
            await page.waitForSelector(datePickerString);
            await page.click(datePickerString);
            print("clicked");

            //region select year
            bool yearSelectorLoaded = false;
            const int yearSelectorMaxAttempt = 5;
            int yearSelectorAttemptCount = 0;

            page.defaultTimeout = const Duration(seconds: 5);
            while(!yearSelectorLoaded && yearSelectorAttemptCount < yearSelectorMaxAttempt){
              try{
                String yearSelectorString = "#ui-datepicker-div > div > div > select";
                await page.waitForSelector(yearSelectorString);
                await selectElement(page, yearSelectorString, ["${dateTime.year}"]);
                print("selected ${dateTime.year}");
                yearSelectorLoaded = true;
              }catch(e){
                yearSelectorAttemptCount++;
                await page.reload();

                await page.waitForSelector(datePickerString);
                await page.click(datePickerString);
                print("clicked");
              }
            }
            page.defaultTimeout = _defaultTimeOut;
            //endregion

            //region Navigating Month
            String monthString = await getElementTextContent(page, selector: "#ui-datepicker-div > div > div > span");
            int month = MyUtil.getMonthIntFromString(monthString);

            while(month != dateTime.month){
              if(month > dateTime.month){
                await page.click("#ui-datepicker-div > div > a.ui-datepicker-prev.ui-corner-all");
              }else if(month < dateTime.month){
                await page.click("#ui-datepicker-div > div > a.ui-datepicker-next.ui-corner-all");
              }

              monthString = await getElementTextContent(page, selector: "#ui-datepicker-div > div > div > span");
              month = MyUtil.getMonthIntFromString(monthString);
            }
            print("month: $month");
            //endregion

            bool invalidDate = false;
            //region pick day
            ElementHandle tableElement = await page.$("#ui-datepicker-div > table > tbody");
            List<ElementHandle> cellElementList = await tableElement.$x(".//td");

            for(ElementHandle cellElement in cellElementList){
              String textContent = await getElementTextContent(page, elementHandle: cellElement);
              String className = await getElementClass(page, elementHandle: cellElement);

              if(textContent == "${dateTime.day}"){
                if(className.contains("unselectable")){
                  invalidDate = true;
                }else{
                  await cellElement.click();
                }

                break;
              }
              //print(await getElementTextContent(page, elementHandle: cellElement));
            }
            //endregion
            if(invalidDate){
              invalidDateList.add(dateTime);
              continue;
            }

            //region waiting for result to load
            int maxWaitInMilliSecond = 15000;
            int waitIntervalInMilliSeconds = 500;
            int milliSecondsWaited = 0;

            String dateString = (await getElementTextContent(page, selector: "#title > p > strong:nth-child(1)")).replaceAll(RegExp(r'[^0-9/]'), '');

            while(dateString != lookForDateString && milliSecondsWaited < maxWaitInMilliSecond){
              print("LookingFor:$lookForDateString, $dateString");
              await Future.delayed(Duration(milliseconds: waitIntervalInMilliSeconds));
              milliSecondsWaited += waitIntervalInMilliSeconds;

              dateString = (await getElementTextContent(page, selector: "#title > p > strong:nth-child(1)")).replaceAll(RegExp(r'[^0-9/]'), '');
            }

            if(dateString == lookForDateString){
              resultLoaded = true;
            }else{
              await page.reload();
              attemptCount++;
            }
            //endregion
          }

          //region Generate DayPrizesObj
          DayPrizesObj dayPrizesObj = DayPrizesObj();

          dayPrizesObj.dateTime = dateTime;
          dayPrizesObj.firstPrize = await getElementTextContent(page, selector: "#main > div.middle > div > div > section:nth-child(2) > div > div.row.w1p3d > div:nth-child(1) > div.prize-column.old-game > div.row.no-margin.topPrize_0 > div:nth-child(1) > span.prize-number");
          dayPrizesObj.secondPrize = await getElementTextContent(page, selector: "#main > div.middle > div > div > section:nth-child(2) > div > div.row.w1p3d > div:nth-child(1) > div.prize-column.old-game > div.row.no-margin.topPrize_0 > div:nth-child(2) > span.prize-number");
          dayPrizesObj.thirdPrize = await getElementTextContent(page, selector: "#main > div.middle > div > div > section:nth-child(2) > div > div.row.w1p3d > div:nth-child(1) > div.prize-column.old-game > div.row.no-margin.topPrize_0 > div:nth-child(3) > span.prize-number");
          dayPrizesObj.type = PrizeObj.TYPE_DAMACAI;

          print("result: "+await getElementTextContent(page, selector: "#title > p > strong:nth-child(1)"));
          print(dayPrizesObj.firstPrize);
          print(dayPrizesObj.secondPrize);
          print(dayPrizesObj.thirdPrize);
          //endregion

          dayPrizesObjList.add(dayPrizesObj);

          if(_isCancelling){
            _isCancelling = false;
            scrapResult = ScrapResult.Canceled;
            break;
          }
        }finally{
          //region calculate progress
          doneCount++;
          double progress = doneCount.toDouble()/toDoCount.toDouble();
          _scrapStreamController.sink.add(progress);
          //endregion
        }
      }

    }catch(e){
      scrapResult = ScrapResult.Error;
    }

    //region update invalidDateStringMap
    if(invalidDateList.isNotEmpty){
      DataManager.getInstance().updateInvalidDate({PrizeObj.TYPE_DAMACAI : invalidDateList});
    }
    //endregion

    return ScrapDetail(scrapResult: scrapResult, dayPrizesObjList: dayPrizesObjList, doneCount: doneCount);
  }
  Future<List<DayPrizesObj>> scrapPrizesDetail(List<Pair<DateTime, String>> list) async {

      //region start browser
      //Start browser if needed
      if (browser == null || !browser!.isConnected) {
        print("restarting browser");
        await startScrapDriver();
      }

      List<Page> pages = await browser!.pages;

      if (pages.isEmpty) {
        browser!.newPage();
      }
      final Page page = pages[0];
      page.defaultTimeout = const Duration(seconds: 120);
      page.defaultNavigationTimeout = _defaultTimeOut;
      //final page = await browser!.newPage();
      print("going");
      //endregion

      await page.goto("https://my3d.my/draw-winning-history/");

      Map<DateTime, DayPrizesObj> detailMap = {};
      for(int i = 0; i < 10000; i++){
          String prizeString = i.toString();

          while(prizeString.length != 4){
              prizeString = "0$prizeString";
          }

          await typeInElement(page, "#number1_1", prizeString);
          await clickWithFunction(page, selector: "#search");

          ElementHandle containerParent = await page.$("#historyTable > div > div > div.historyRow");
          List<ElementHandle> rowElements = await containerParent.$x(".//div");

          for(ElementHandle row in rowElements){
            String text = await getElementTextContent(page, elementHandle: row);

            if(!(text.contains("Prize Category") && text.contains("Drawn Date"))){
              continue;
            }

            String prizeString =  text.substring(6,10);
            String rank = text.contains("First Prize") ? "First Prize" : text.contains("Second Prize") ? "Second Prize" : text.contains("Third Prize") ? "Third Prize" : "null";

            String dateString = text.split("Drawn Date").last.replaceAll(RegExp(r'[^0-9-]'), "");

            List<int> dateDigitList = dateString.split("-").map((e) => int.parse(e)).toList();


            DateTime dateTime = DateTime(dateDigitList[2], dateDigitList[1], dateDigitList[0]);

            if(rank != "null"){
                if(!detailMap.containsKey(dateTime)){
                    detailMap[dateTime] = DayPrizesObj();
                }

                detailMap[dateTime]!.dateTime ??= dateTime;
                detailMap[dateTime]!.type ??= PrizeObj.TYPE_DAMACAI;

                switch(rank){
                  case "First Prize":
                    if(detailMap[dateTime]!.firstPrize == null){
                      detailMap[dateTime]!.firstPrize = prizeString;
                    }else{
                        print("dupe first prize");
                        if(detailMap[dateTime]!.firstPrize != prizeString){
                          print("conflict");
                        }
                    }

                    break;

                  case "Second Prize":
                    if(detailMap[dateTime]!.secondPrize == null){
                      detailMap[dateTime]!.secondPrize = prizeString;
                    }else{
                      print("dupe second prize");
                      if(detailMap[dateTime]!.secondPrize != prizeString){
                        print("conflict");
                      }
                    }
                    break;

                  case "Third Prize":
                    if(detailMap[dateTime]!.thirdPrize == null){
                      detailMap[dateTime]!.thirdPrize = prizeString;
                    }else{
                      print("dupe first prize");
                      if(detailMap[dateTime]!.thirdPrize != prizeString){
                        print("conflict");
                      }
                    }
                    break;
                }

                print(
                  "${DateFormat("dd/MM/yyyy").format(dateTime)} - $rank $prizeString"
                );
            }
          }
      }

      List<DayPrizesObj> dayPrizesObjList = detailMap.values.toList();

      dayPrizesObjList.removeWhere((element) => element.firstPrize == null || element.secondPrize == null || element.thirdPrize == null);

      return dayPrizesObjList;
      /*

      //region Navigate to calendar
      if(!await checkIfElementExist(page,
          "#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > form > div:nth-child(3) > div > div > div > input",
          null)
      ){

        //GoTo Giret2.0 Website
        await page.goto('http://giret.moh.gov.my/');

        await clickElement(page,
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > div.grid.lg\\:grid-cols-2.ml-auto.mr-auto.mt-7.lg\\:mt-10.h-60 > div > div.flex.items-center.justify-center.rounded-md.shadow-md.p-3.m-1.bg-user3.hover\\:bg-user2.hover\\:text-userWhite.transition-all.hover\\:cursor-pointer");
        await clickElement(page,
            '#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > div.grid.lg\\:grid-cols-2.ml-auto.mr-auto.mt-7.lg\\:mt-10.h-60 > div > div.grid.transition-all.max-h-96 > a.bg-user4.rounded-md.shadow-md.p-3.my-0\\.5.mx-1.hover\\:bg-user3.hover\\:text-userWhite.transition-all');

        await selectElement(page, "#negeri", ["Kedah"]);
        await selectElement(page, "#daerah", ["Kulim"]);
        await selectElement(page, "#klinik", ["K11-005-02"]);

        await typeInElement(page, "#password", penggunaPassword);

        //Log Masuk Button
        await clickElement(page,
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > form > div.grid.lg\\:grid-cols-2.gap-2.mt-7.ml-20.mr-20 > button");

        await page.waitForSelector(
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > form > select",
            timeout: const Duration(seconds: 30));
        ElementHandle penggunaBox = await page.$(
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > form > select");
        List<ElementHandle> penggunaList = await penggunaBox.$x(".//option");
        int count = 0;
        while ((penggunaList.length) <= 1) {
          sleep(Duration(seconds: 1));

          penggunaList = await penggunaBox.$x(".//option");
          print('${count++}');
        }

        await selectElement(page,
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > form > select",
            [penggunaName]);

        await typeInElement(page, "#noMdc-noMdtb", MDCNumber);

        //Pilih Pengguna Button
        await clickElement(page,
            "#root > div.absolute.inset-0.-z-10.flex.bg-user5.text-center.justify-center.items-center.capitalize > div > div > form > button");

        //top left menu
        await clickElement(page, "#root > div:nth-child(4) > div > button");

        //pengisian data
        await clickWithFunction(page,
            selector: "#root > div:nth-child(4) > nav > div:nth-child(3) > div > div.bg-user4.flex.items-center.justify-center.rounded-md.shadow-xl.p-3.m-1.hover\\:bg-user3.transition-all.hover\\:cursor-pointer");

        //umum
        await clickWithFunction(page,
            selector: "#root > div:nth-child(4) > nav > div:nth-child(3) > div:nth-child(3) > div.grid.transition-all.max-h-96 > a:nth-child(1)");
      }
      //endregion

      progbarKey.currentState?.setValue(0.3);

      //calendarMain
      sleep(const Duration(seconds: 5));
      await clickWithFunction(page,
          selector: "#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > form > div:nth-child(3) > div > div > div > input");
      print('calendar clicked');

      progbarKey.currentState?.setValue(0.4);

      //year
      print("selecting ${submitObj.timeStarted.year.toString()}");
      await selectElement(
          page,
          "#root-portal > div > div > div.react-datepicker-popper > div > div > div > div.react-datepicker__header > div.react-datepicker__header__dropdown.react-datepicker__header__dropdown--select > div.react-datepicker__year-dropdown-container.react-datepicker__year-dropdown-container--select > select",
          [submitObj.timeStarted.year.toString()]);

      //month
      sleep(const Duration(seconds: 2));
      int monthSelected = submitObj.timeStarted.month - 1;
      await selectElement(
          page,
          "#root-portal > div > div > div.react-datepicker-popper > div > div > div > div.react-datepicker__header > div.react-datepicker__header__dropdown.react-datepicker__header__dropdown--select > div.react-datepicker__month-dropdown-container.react-datepicker__month-dropdown-container--select > select",
          [monthSelected.toString()]);

      //day
      String selectorString = "#root-portal > div > div > div.react-datepicker-popper > div > div > div > div.react-datepicker__month";
      await page.waitForSelector(
          selectorString);
      ElementHandle weekContainer = await page.$(
          selectorString);
      List<ElementHandle> weekRowList = await weekContainer.$x(".//div");
      for (int weekIndex = 0; weekIndex < weekRowList.length; weekIndex++) {
        List<ElementHandle> dayList = await weekRowList[weekIndex].$x(".//div");
        print("////////// Week: $weekIndex ///////////////////////");
        for (int dayIndex = 0; dayIndex < dayList.length; dayIndex++) {
          final dayText = await dayList[dayIndex].evaluate(
              '(e) => e.textContent');
          final dayLabel = await dayList[dayIndex].evaluate(
              '(e) => e.getAttribute("aria-label")');
          print("$dayIndex. day $dayText $dayLabel");

          if (int.parse(dayText) == submitObj.timeStarted.day &&
              (dayLabel as String).contains(monthMap[monthSelected]!)) {
            dayList[dayIndex].evaluate("(b) => b.click()");
          }
        }
      }

      progbarKey.currentState?.setValue(0.5);

      //Patient Table
      ElementHandle patientTable = await page.$(
          "#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > section > div > table");
      List<ElementHandle> rowList = await patientTable.$x(".//tbody");

      patientTable.ge

      while (rowList.length == 1) {
        List<ElementHandle> columnList = await rowList[0].$x(".//td");

        if (columnList.length >= 3) {
          String thirdelementText = await columnList[2].evaluate(
              '(e) => e.textContent');

          if (thirdelementText.isNotEmpty) {
            print("Not Empty: $thirdelementText");
            break;
          } else {
            rowList = await patientTable.$x(".//tbody");
          }
        }
      }

      bool found = false;
      bool done = false;

      for (int rowIndex = 0; rowIndex < rowList.length; rowIndex++) {
        List<ElementHandle> columnList = await rowList[rowIndex].$x(".//td");

        String daftarNumberString = await getElementTextContent(page, elementHandle: columnList[2]);
        String nameString = await getElementTextContent(page, elementHandle: columnList[3]);
        int daftarNumber = int.parse( daftarNumberString.substring(0, daftarNumberString.indexOf("/")));

        if (daftarNumber == submitObj.pendaftarNumber) {
          print("Found! $nameString");
          found = true;

          if(!(await getElementTextContent(page, elementHandle: columnList[7])).toLowerCase().contains("belum")){
            print("Telah diisi!");
            done = true;
            break;
          }

          await clickWithFunction(page, elementHandle: columnList[8]);

          ElementHandle masukRetenButton = await page.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div > section > div.lg\\:pt-10 > a");
          await clickWithFunction(page, elementHandle: masukRetenButton);

          break;
        }
      }
      print("Row Length: ${rowList.length}");

      progbarKey.currentState?.setValue(0.6);

      //formPage starts here
      if (found && !done) {
        PuppetPage.Page formPage = await (await submitBrowser!.waitForTarget((target) => target.url.contains("form-umum")) ).page;

        bool loadComplete = await checkIfElementExist(formPage, "#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.p-2 > article > div.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-4 > div.text-s.flex.flex-row.pl-5 > p", const Duration(seconds: 30));

        //double check name
        if(loadComplete){
          ElementHandle nameElement = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.p-2 > article > div.grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-4 > div.text-s.flex.flex-row.pl-5 > p");
          String name = await getElementTextContent(formPage, elementHandle: nameElement);
          if(name.toLowerCase().replaceAll(RegExp(r"\s+"), "") != submitObj.name.toLowerCase().replaceAll(RegExp(r"\s+"), "")){
            print("$name \n ${submitObj.pendaftarNumber}");
            throw Error();
          }

        }else{print("Fail to Load"); return;}

        //todo need to allow fill in after JP fill in
        //check if still can isi waktuDipanggil, if cnt isi waktuDipanggil means is done
        done = ! await checkIfElementExist(formPage, "#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > input", const Duration(seconds: 5));

        if(!done){
          //region waktuDiPanggil
          ElementHandle waktuDipanggil_Box = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > input");
          await clickWithFunction(formPage, elementHandle: waktuDipanggil_Box);

          sleep(const Duration(seconds: 1));

          await formPage.waitForSelector("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(1) > div");

          ElementHandle hourBlock = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(1) > div");
          ElementHandle hourUp = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(1) > span:nth-child(1)");
          ElementHandle hourDown = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(1) > span:nth-child(3)");

          ElementHandle minuteBlock = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(3) > div");
          ElementHandle minuteUp = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(3) > span:nth-child(1)");
          ElementHandle minuteDown = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(3) > span:nth-child(3)");

          int daftarHour = int.parse(await getElementTextContent(formPage, elementHandle: hourBlock));
          int daftarMinute = int.parse(await getElementTextContent(formPage, elementHandle: minuteBlock));

          int rawatHour = submitObj.getWaktuPanggil_Hour();
          int rawatMinute = submitObj.getWaktuPanggil_Min();

          int diff_Hour = rawatHour - daftarHour;
          int diff_Minute = rawatMinute - daftarMinute;

          if(diff_Hour != 0){
            print("diffHour: $diff_Hour");

            int clickCount = (diff_Hour).abs();

            for(int i = 0; i < clickCount ; i ++){

              if(diff_Hour > 0){
                await hourUp.click();
              }else{
                await hourDown.click();
              }
            }
          }

          if(diff_Minute != 0){
            print("diffMinute: $diff_Minute");

            int clickCount = (diff_Minute).abs();

            for(int i = 0; i < clickCount ; i++){
              if(diff_Minute > 0){
                await minuteUp.click();
              }else{
                await minuteDown.click();
              }
            }
          }

          ElementHandle AMPM_Block = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(4) > div");
          ElementHandle AMPM_Up = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.pb-1.pr-2.pl-2 > div.grid.gap-2.lg\\:grid-cols-2 > article.flex.flex-wrap.border.border-userBlack.mb-2.pl-3.p-2.rounded-md > div.flex.flex-wrap.lg\\:flex-row.items-center.my-2 > div.flex.flex-row > div > div > div > div > table > tbody > tr > td > div > div:nth-child(4) > span:nth-child(1)");
          String daftarAMPM = await getElementTextContent(formPage, elementHandle: AMPM_Block);
          String rawatAMPM = submitObj.getWaktuPanggil_AMPM();
          bool diff_In_AMPM = rawatAMPM != daftarAMPM;

          if(diff_In_AMPM){
            print("AMPM clicked");
            await AMPM_Up.click();
          }
          //endregion

          //region tekananDarah [(age >= 18 only)]
          if(submitObj.age >= 18){
            Map<String, int> tekananDarahMap = submitObj.getTekananDarah();
            if(tekananDarahMap.isNotEmpty){
              await typeInElement(formPage, "#systolic-tekanan-darah", "${tekananDarahMap['systolic']!}");
              await typeInElement(formPage, "#diastolic-tekanan-darah", "${tekananDarahMap['diastolic']!}");
            }
          }
          //endregion

          progbarKey.currentState?.setValue(0.7);

          //region T2DM-FaktoRisiko [baru Only (age >= 15 only)]
          if(submitObj.bu.toLowerCase().contains("b") && submitObj.age >= 15){
            await selectElement(formPage, "#punca-rujukan", [submitObj.getT2DM()]);
            if(submitObj.generalDetail != null){
              if(submitObj.generalDetail!.diabetes){
                await clickWithFunction(formPage, selector: "#diabetes-faktor-risiko-bpe");
              }
              if(submitObj.generalDetail!.perokok){
                await clickWithFunction(formPage, selector: "#perokok-faktor-risiko-bpe");
              }
            }
          }
          //endregion

          //region DMFX & dfx [Baru Only (all ages)]
          if(submitObj.bu.toLowerCase().contains("b")){
            ElementHandle YaAda_Gigi_RadioButton = await formPage.$("#ya-pesakit-mempunyai-gigi");
            ElementHandle No_Takada_Gigi_RadioButton = await formPage.$("#tidak-pesakit-mempunyai-gigi");

            Map<String, num> DMFX_Map = submitObj.getDMFX();
            Map<String, num> dfx_Map = submitObj.getdfx();

            if(DMFX_Map.isNotEmpty || dfx_Map.isNotEmpty) {

              await clickWithFunction(formPage, elementHandle: YaAda_Gigi_RadioButton);

              if (DMFX_Map.isNotEmpty) {
                ElementHandle adaGigiKekal_RadioButton = await formPage.$("#ada-kekal-pemeriksaan-umum");
                await clickWithFunction(formPage, elementHandle: adaGigiKekal_RadioButton);

                ElementHandle D_EditText = await formPage.$("#d-ada-status-gigi-kekal-pemeriksaan-umum");
                ElementHandle M_EditText = await formPage.$("#m-ada-status-gigi-kekal-pemeriksaan-umum");
                ElementHandle F_EditText = await formPage.$("#f-ada-status-gigi-kekal-pemeriksaan-umum");
                ElementHandle X_EditText = await formPage.$("#x-ada-status-gigi-kekal-pemeriksaan-umum");

                await typeInElement(formPage, "#d-ada-status-gigi-kekal-pemeriksaan-umum", "${DMFX_Map['D']!}");
                await typeInElement(formPage, "#m-ada-status-gigi-kekal-pemeriksaan-umum", "${DMFX_Map['M']!}");
                await typeInElement(formPage, "#f-ada-status-gigi-kekal-pemeriksaan-umum", "${DMFX_Map['F']!}");
                await typeInElement(formPage, "#x-ada-status-gigi-kekal-pemeriksaan-umum", "${DMFX_Map['X']!}");

              }
              if (dfx_Map.isNotEmpty) {
                ElementHandle adaGigiDecidus_RadioButton = await formPage.$("#ada-desidus-pemeriksaan-umum");
                await clickWithFunction(formPage, elementHandle: adaGigiDecidus_RadioButton);

                ElementHandle d_EditText = await formPage.$("#d-ada-status-gigi-desidus-pemeriksaan-umum");
                ElementHandle f_EditText = await formPage.$("#f-ada-status-gigi-desidus-pemeriksaan-umum");
                ElementHandle x_EditText = await formPage.$("#x-ada-status-gigi-desidus-pemeriksaan-umum");

                await typeInElement(formPage, "#d-ada-status-gigi-desidus-pemeriksaan-umum", "${dfx_Map['d']!}");
                await typeInElement(formPage, "#f-ada-status-gigi-desidus-pemeriksaan-umum", "${dfx_Map['f']!}");
                await typeInElement(formPage, "#x-ada-status-gigi-desidus-pemeriksaan-umum", "${dfx_Map['x']!}");

              }
              if(submitObj.age >= 60){
                ElementHandle gigiKekalYangAda_EditText = await formPage.$("#bilangan-gigi-mempunyai-20-gigi-edentulous-warga-emas-pemeriksaan-umum");
                await typeInElement(formPage, "#bilangan-gigi-mempunyai-20-gigi-edentulous-warga-emas-pemeriksaan-umum", "${DMFX_Map['T']!}");
              }

            }else{
              await clickWithFunction(formPage, elementHandle: No_Takada_Gigi_RadioButton);
            }
          }
          //endregion

          //region PlakScore [Baru Only (all ages)]
          if(submitObj.bu.toLowerCase().contains("b") && submitObj.getPlakScore() != null){
            ElementHandle plakScoreContainer = await formPage.$("#kebersihan-mulut-pemeriksaan-umum");
            await selectElement(formPage, "#kebersihan-mulut-pemeriksaan-umum", [submitObj.getPlakScore()!]);
          }
          //endregion

          //region BPE/GIS Score [GIS - Baru Only]
          if(submitObj.getBPE_GIS() != null){

            String bpe_gis = submitObj.getBPE_GIS()!;

            //GIS if below 15 [Baru only]
            if(submitObj.bu.toLowerCase().contains("b") && submitObj.age < 15){
              ElementHandle GIS_ScoreContainer = await formPage.$("#skor-gis-pemeriksaan-umum");
              await selectElement(formPage, "#skor-gis-pemeriksaan-umum", [bpe_gis]);
            }
            //otherwise BPE
            else{
              ElementHandle BPEScoreContainer = await formPage.$("#skor-bpe-pemeriksaan-umum");
              await selectElement(formPage, "#skor-bpe-pemeriksaan-umum", [bpe_gis]);

              //click perlu penskaleran checkbox if bpe > 1 and baru
              int bpeScore = int.tryParse(bpe_gis) ?? -1;
              if(bpeScore > 1 && submitObj.bu.toLowerCase().contains("b")){
                await clickWithFunction(formPage, selector: "#perlu-penskaleran-pemeriksaan-umum");
              }
            }

          }
          //endregion

          //region DisaringKanser [Baru Only (all ages)]
          if(submitObj.bu.toLowerCase().contains("b")){
            ElementHandle disaringYa_RadioButton = await formPage.$("#ya-disaring-program-kanser-mulut-pemeriksaan-umum");
            ElementHandle disaringNo_RadioButton = await formPage.$("#tidak-disaring-program-kanser-mulut-pemeriksaan-umum");

            Map<String, bool> disaringKanserMap = submitObj.getDisaringKanser();
            if(disaringKanserMap.isNotEmpty){
              if(disaringKanserMap['disaring']!){
                await clickWithFunction(formPage, elementHandle: disaringYa_RadioButton);
                sleep(const Duration(milliseconds: 500));

                if(disaringKanserMap['lesi']!){
                  await clickWithFunction(formPage, selector: "#lesi-mulut-pemeriksaan-umum");
                }
                if(disaringKanserMap['tabiat']!){
                  await clickWithFunction(formPage, selector: "#tabiat-berisiko-tinggi-pemeriksaan-umum");
                }

              }else{
                await clickWithFunction(formPage, elementHandle: disaringNo_RadioButton);
              }
            }
          }
          //endregion

          progbarKey.currentState?.setValue(0.8);

          //region rawatan
          //region kes-selesai & DibuatOperatorLain
          if(submitObj.kes_Selesai){
            await clickWithFunction(formPage, selector: "#kes-selesai-rawatan-umum");
          }
          if(submitObj.dibuat_Operator_Lain){
            await clickWithFunction(formPage, selector: "#rawatan-dibuat-operator-lain-umum");
          }
          //endregion

          //region select Lihat Semua
          ElementHandle rawatanSpinner = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div:nth-child(2) > div > section > article.grid.border.border-userBlack.pl-3.px-2.p-2.rounded-md.lg\\:col-span-2 > div");
          await rawatanSpinner.click();

          sleep(const Duration(seconds: 3));

          List<ElementHandle> selectionList = await rawatanSpinner.$$("div");
          ElementHandle? target;
          for (var element in selectionList) {
            String textContext = await getElementTextContent(formPage, elementHandle: element);
            if(textContext.toLowerCase().contains("lihat semua")){
              target = element;
            }
            //print(textContext);
          }
          if(target != null){
            await target.click();
          }
          //endregion

          //region Cabutan
          Map<String, int> cabutanMap = submitObj.getCabutanBiasa();
          if(cabutanMap.isNotEmpty){
            await typeInElement(formPage, "#cabut-desidus-rawatan-umum", "${cabutanMap['desidus']!}");
            await typeInElement(formPage, "#cabut-kekal-rawatan-umum", "${cabutanMap['kekal']!}");
          }
          //endregion
          //region tampalan kekal & sementara & FS & PRR
          Map<String, int> tampalanMap = submitObj.getTampalan();
          if(tampalanMap.isNotEmpty){
            await typeInElement(formPage, "#gd-baru-anterior-sewarna-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["ant desidus warna"]!}');
            await typeInElement(formPage, "#gk-baru-anterior-sewarna-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["ant kekal warna"]!}');
            await typeInElement(formPage, "#gd-baru-posterior-sewarna-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["post desidus warna"]!}');
            await typeInElement(formPage, "#gk-baru-posterior-sewarna-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["post kekal warna"]!}');
            await typeInElement(formPage, "#gd-baru-posterior-amalgam-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["post desidus amalgam"]!}');
            await typeInElement(formPage, "#gk-baru-posterior-amalgam-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["post kekal amalgam"]!}');
            await typeInElement(formPage, "#jumlah-tampalan-sementara-jumlah-tampalan-dibuat-rawatan-umum", '${tampalanMap["sementara"]!}');
            await typeInElement(formPage, "#baru-jumlah-gigi-kekal-dibuat-fs-rawatan-umum", '${tampalanMap["fissure"]!}');
            await typeInElement(formPage, "#baru-jumlah-gigi-kekal-diberi-prr-jenis-1-rawatan-umum", '${tampalanMap["prr"]!}');
          }
          //endregion
          //region Penskaleraan
          if(submitObj.treatmentObjMap.containsKey(TreatmentType.scaling.name.toString())){
            print("Got Scaling");
            await clickWithFunction(formPage, selector: "#penskaleran-rawatan-umum");
          }
          //endregion
          //region Denture
          Map<String, int> dentureMap = submitObj.getDenture();
          if(dentureMap.isNotEmpty){
            await typeInElement(formPage, "#baru-penuh-jumlah-dentur-prostodontik-rawatan-umum", '${dentureMap["penuh"]!}');
            await typeInElement(formPage, "#baru-separa-jumlah-dentur-prostodontik-rawatan-umum", '${dentureMap["separa"]!}');
            await typeInElement(formPage, "#pembaikan-dentur-prostodontik-rawatan-umum", '${dentureMap["repair"]!}');
          }
          //endregion
          //region Fluoride
          if(submitObj.treatmentObjMap.containsKey(TreatmentType.fluoride.name.toString())){
            await clickWithFunction(formPage, selector: "#pesakit-dibuat-fluoride-varnish");
          }
          //endregion

          //endregion

          ElementHandle hantarButton = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div > div.grid.h-full.overflow-scroll.overflow-x-hidden.gap-2 > form > div.grid.grid-cols-1.lg\\:grid-cols-2.col-start-1.md\\:col-start-2.gap-2.col-span-2.md\\:col-span-1 > div > button");
          await clickWithFunction(formPage, elementHandle: hantarButton);

          ElementHandle yaButton = await formPage.$("#root > div.absolute.inset-2.top-\\[7\\.5rem\\].bottom-\\[2rem\\].-z-10.bg-userWhite.text-center.justify-center.items-center.outline.outline-1.outline-userBlack.rounded-md.shadow-xl.capitalize > div.absolute.inset-x-10.inset-y-5.lg\\:inset-x-1\\/3.lg\\:inset-y-6.text-sm.bg-userWhite.z-20.outline.outline-1.outline-userBlack.opacity-100.overflow-y-auto.rounded-md > div > div.sticky.grid.grid-cols-2.bottom-0.right-0.left-0.m-2.mx-10.bg-userWhite.px-5.py-2 > button.capitalize.bg-user9.text-userWhite.rounded-md.shadow-xl.p-2.mr-3.hover\\:bg-user1.transition-all");
          await clickWithFunction(formPage, elementHandle: yaButton);

          done = true;
        }

      }

      progbarKey.currentState?.setValue(0.9);

      if(done){
        List<Document> allSessionDocList = await submitObj.getSessionDocList();
        for (var doc in allSessionDocList) {
          if(doc.map["timeStarted"] == submitObj.timeStarted && doc.map["timeRequested"] == submitObj.timeRequested){
            await Firestore.instance.collection("/PatientFolder/${submitObj.clinicName}/${submitObj.mdcNumber}/${submitObj.pendaftarNumber}_${submitObj.timeStarted.year}/Session").document(doc.id).update(
                {"completionCode" : 4}
            );
            break;
          }
        }
        await submitObj.getDocRef().delete();
      }

      progbarKey.currentState?.setValue(1);
      //await scrapDetail.saveToDB();

    }finally{
      isSubmitting = false;
    }

    */
  }
  */

  void stopScrapProgressStreamController(){
    _scrapProgressStreamController.close();
  }

  Stream<double> getScrapProgressStream(){
      return _scrapProgressStreamController.stream;
  }

  void stopScrapDetailStreamController(){
    _scrapProgressStreamController.close();
  }

  Stream<Pair<String,DayPrizesObj?>> getScrapDetailStream(){
    return _scrapDetailStreamController.stream;
  }

  @override
  void cancelProgress() {
    _isCancelling = true;
  }

  static clickElement(Page page, String selector) async {
    await page.waitForSelector(selector);
    await page.click(selector);
  }
  static clickWithFunction(Page page, {String? selector, ElementHandle? elementHandle}) async {
    if(selector != null && selector.isNotEmpty){
      await page.waitForSelector(selector);
      ElementHandle element = await page.$(selector);
      await element.evaluate("(b) => b.click()");
    }

    if(elementHandle != null){
      await elementHandle.evaluate("(b) => b.click()");
    }

  }
  static typeInElement(Page page, String selector, String text) async {
    await page.waitForSelector(selector);
    await page.$eval(selector, "(el) => el.value = ''");
    await page.type(selector, text);
  }
  static selectElement(Page page, String containerSelector, List<String> values) async {
    await page.waitForSelector(containerSelector);
    await page.select(containerSelector, values);
  }
  static selectElement_Custom(Page page, String containerSelector, List<String> values) async {
    ElementHandle yearSelectorContainer =  await page.$(containerSelector);
    List<ElementHandle> yearOptionElementList = await yearSelectorContainer.$x(".//option");

    List<String> optionValueList = [];

    for(ElementHandle element in yearOptionElementList){
      String textContent = await getElementTextContent(page, elementHandle: element);

      if(values.contains( textContent)){
        String optionValue = await getElementContent(page, "value", elementHandle: element);
        optionValueList.add(optionValue);
      }
    }
    await selectElement(page, containerSelector, optionValueList);
  }
  static Future<bool> checkIfElementExist(Page page, String selector, Duration? timeout) async {
    Duration? defaultTimeOut = page.defaultTimeout;

    try{

      //Wait Till TimeOut
      if(timeout != null){
        page.defaultTimeout = timeout;
        if( await page.waitForSelector(selector) != null){
          return true;
        }

      }
      //No Wait
      else{
        List<ElementHandle> elementFoundList = await page.$$(selector);

        if(elementFoundList.isNotEmpty){
          return true;
        }
      }

    }catch(e) {
      print(e);

    }finally{
      page.defaultTimeout = defaultTimeOut;
    }

    print("Check Exist return false");
    return false;
  }
  static Future<String> getElementTextContent(Page page ,{String? selector, ElementHandle? elementHandle}) async {

    if(selector != null && selector.isNotEmpty){
      await page.waitForSelector(selector);
      ElementHandle element = await page.$(selector);
      String textContent = await element.evaluate("(e) => e.textContent");

      return textContent;
    }

    if(elementHandle != null){
      String textContent = await elementHandle.evaluate("(e) => e.textContent");
      return textContent;
    }

    return "Please provide elementHandle";

  }
  static Future<String> getElementTitle(Page page ,{String? selector, ElementHandle? elementHandle}) async {

    if(selector != null && selector.isNotEmpty){
      await page.waitForSelector(selector);
      ElementHandle element = await page.$(selector);
      String textContent = await element.evaluate('(e) => e.getAttribute("title")');

      return textContent;
    }

    if(elementHandle != null){
      String textContent = await elementHandle.evaluate('(e) => e.getAttribute("title")');
      return textContent;
    }

    return "Please provide elementHandle";

  }
  static Future<String> getElementClass(Page page ,{String? selector, ElementHandle? elementHandle}) async {

    if(selector != null && selector.isNotEmpty){
      await page.waitForSelector(selector);
      ElementHandle element = await page.$(selector);
      String className = await element.evaluate('(e) => e.getAttribute("class")');

      return className;
    }

    if(elementHandle != null){
      String className = await elementHandle.evaluate('(e) => e.getAttribute("class")');
      return className;
    }

    return "Please provide elementHandle";

  }
  static Future<String> getElementContent(Page page, String contentTitle,{String? selector, ElementHandle? elementHandle, bool throwErrorIfInvalidTitle = true}) async {

    try{
      if(selector != null && selector.isNotEmpty){
        await page.waitForSelector(selector);
        ElementHandle element = await page.$(selector);
        String content = await element.evaluate('(e) => e.getAttribute("$contentTitle")');

        return content;
      }

      if(elementHandle != null){
        String content = await elementHandle.evaluate('(e) => e.getAttribute("$contentTitle")');
        return content;
      }
    }catch(e){
      if(throwErrorIfInvalidTitle){
        throw Exception("Invalid contentTitle provided, probably this element doesn't have this attribute");
      }
      
      return "";
    }


    throw Exception("Please provide a selectorString or an ElementHandle");

  }

  void broadCastDayPrizesObj(DateTime dateTime, String type, DayPrizesObj? dayPrizesObj){

    if(dayPrizesObj == null){
      _scrapDetailStreamController.add(Pair("Invalid $type ${DateFormat("dd/MM/yyyy").format(dateTime)}", null));
      return;
    }

    //region Check
    String status = "New";
    if(DataManager.getInstance().SortedByDateMap.containsKey(dateTime)){
      List<DayPrizesObj> dayPrizesObjList = DataManager.getInstance().SortedByDateMap[dayPrizesObj.dateTime]!;

      for(DayPrizesObj _dayPrizesObj in dayPrizesObjList){
        if(dayPrizesObj.type == _dayPrizesObj.type){
          status = "Dupe";

          if(dayPrizesObj.getPrizeString() != _dayPrizesObj.getPrizeString()){
            status = "Conflict";
          }

          break;
        }
      }
    }

    _scrapDetailStreamController.add(Pair(status, dayPrizesObj));

    return;
  }
}

class ScrapDetail{
  ScrapResult scrapResult;
  List<DayPrizesObj> dayPrizesObjList = [];
  int doneCount = 0;

  ScrapDetail(
    {
      required this.scrapResult,
      required this.dayPrizesObjList,
      required this.doneCount,
    }
  );
}

enum ScrapResult{
  Success, Error, Canceled
}