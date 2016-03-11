module DateUtils (..) where

import List exposing (head, isEmpty, reverse, drop, take)
import Date exposing (..)
import Date.Core exposing (..)
import Date.Utils exposing (..)
import Date.Period as Period exposing (add, diff)
import Date.Compare as Compare exposing (is, Compare2)
import Date.Duration as Duration
import Date.Format exposing (format)
import Date.Config.Configs as DateConfigs
import Date.Floor as Df exposing (floor)
import Model exposing (..)


enteredHoursVsTotal : Model -> Float
enteredHoursVsTotal model =
  let
    enteredHours =
      List.foldl
        (\dateEntries -> totalHoursForDate dateEntries)
        0
        model.entries
  in
    enteredHours - totalHoursForYear model


totalHoursForDate : DateEntries -> Float -> Float
totalHoursForDate dateEntries hours =
  let
    hourList =
      List.map
        (\entry -> entry.hours)
        dateEntries.entries
  in
    hours + List.sum hourList


totalHoursForYear : Model -> Float
totalHoursForYear model =
  toFloat (List.length (totalDaysForYear model)) * 7.5


totalDaysForYear : Model -> List Date
totalDaysForYear model =
  workDays (Df.floor Df.Year model.currentDate) model []


workDays : Date -> Model -> List Date -> List Date
workDays date model days =
  if isSameDate date model.currentDate then
    days
  else
    let
      nextDay =
        add Period.Day 1 date

      dayList =
        if isWorkDay nextDay && isNotHoliday nextDay model then
          nextDay :: days
        else
          days
    in
      workDays nextDay model dayList


isNotHoliday : Date -> Model -> Bool
isNotHoliday date model =
  List.length
    (List.filter
      (\holiday -> isSameDate holiday.date date)
      model.holidays
    )
    == 0


isSameDate : Date -> Date -> Bool
isSameDate date1 date2 =
  is
    Compare.Same
    (floorDay date1)
    (floorDay date2)


isWorkDay : Date -> Bool
isWorkDay date =
  let
    dow =
      dayOfWeek date
  in
    not (dow == Sat || dow == Sun)


floorDay : Date -> Date
floorDay date =
  Df.floor Df.Day date


monthView : Model -> List (List DateHours)
monthView model =
  weekRows (monthDays model) []


weekRows : List DateHours -> List (List DateHours) -> List (List DateHours)
weekRows entryList result =
  if (isEmpty entryList) then
    reverse result
  else
    weekRows (drop 7 entryList) ((take 7 entryList) :: result)


monthDays : Model -> List DateHours
monthDays model =
  dateRange
    model
    (Duration.add Duration.Day -(firstOfMonthDayOfWeek model) (toFirstOfMonth model.currentDate))
    (lastOfMonthDate model.currentDate)
    []


type alias DateHours =
  { date : Date
  , hours : Float
  }


{-| Build a list of days with entered hours.
-}
dateRange : Model -> Date -> Date -> List DateHours -> List DateHours
dateRange model startDate endDate dateList =
  if Compare.is Compare.After startDate endDate then
    reverse dateList
  else
    dateRange
      model
      (add Period.Day 1 startDate)
      endDate
      ({ date = startDate, hours = (sumDateHours model startDate) } :: dateList)


{-| Total entered hours for a date.
-}
sumDateHours : Model -> Date -> Float
sumDateHours model date =
  let
    dateEntries =
      List.filter
        (\dateEntries -> isSameDate date dateEntries.date)
        model.entries
  in
    List.foldl
      (\dateEntries -> totalHoursForDate dateEntries)
      0
      dateEntries


{-| Entries for the current month (and end of the previous month).
-}



-- monthEntries : Model -> List DateEntries
-- monthEntries model =
--   entryRange
--     model
--     (Duration.add Duration.Day -(firstOfMonthDayOfWeek model) (toFirstOfMonth model.currentDate))
--     (lastOfMonthDate model.currentDate)
--
--
-- entryRange : Model -> Date -> Date -> List DateEntries
-- entryRange model startDate endDate =
--   List.filter
--     (\e ->
--       Compare.is3
--         Compare.BetweenOpen
--         (floorDay e.date)
--         (floorDay startDate)
--         (floorDay endDate)
--     )
--     model.entries
--


{-| Day of week of the first day of the month as Int, from 0 (Mon) to 6 (Sun).
-}
firstOfMonthDayOfWeek : Model -> Int
firstOfMonthDayOfWeek model =
  isoDayOfWeek (dayOfWeek (toFirstOfMonth model.currentDate)) - 1


dateFormat : Date -> String
dateFormat date =
  format (DateConfigs.getConfig "en_us") "%d.%m." date
