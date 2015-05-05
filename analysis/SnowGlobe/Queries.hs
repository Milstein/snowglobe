module SnowGlobe.Queries(dayNumEvents, dayReport, weekReport) where

import Data.Function(on)
import Data.List(groupBy, intercalate, sortBy)
import Data.Time(Day, LocalTime(..), TimeZone,
                    getCurrentTime, getCurrentTimeZone, utcToLocalTime)
import Data.Time.Calendar(addDays, diffDays)
import Data.Geolocation.GeoIP(GeoDB, geoLocateByIPAddress)
import Network.Whois(whois)
import System.IO.Unsafe(unsafeDupablePerformIO)
import Text.Regex.Posix

import qualified Data.Geolocation.GeoIP as G
import qualified Data.ByteString.Char8 as B

import SnowGlobe.EnrichedEvent
import SnowGlobe.Time(parse)

isNDaysAgo:: TimeZone -> LocalTime -> Integer -> EnrichedEvent -> Bool
isNDaysAgo tz now n e =
    case eTimeM of
      Nothing -> False
      Just eTime -> (==) diff n
        where diff = diffDays (localDay now) eTime
    where eTimeM = localDay <$> parse tz (collectorTstamp e) :: Maybe Day

getTodaysEvents:: TimeZone -> LocalTime -> [EnrichedEvent] -> [EnrichedEvent]
getTodaysEvents tz now = filter $ isNDaysAgo tz now 0

getNDaysAgoDate:: LocalTime -> Integer -> String
getNDaysAgoDate now n = show $ addDays (-n) $ localDay now

getWeeksEvents:: TimeZone -> LocalTime -> [EnrichedEvent] ->
                 [(String,[EnrichedEvent])]
getWeeksEvents tz now events = zip days groupedEvents
    where
      days = map (getNDaysAgoDate now) r
      groupedEvents = map (\n -> filter (isNDaysAgo tz now n) events) r
      r = [0..6]

dayNumEvents:: TimeZone -> LocalTime -> [EnrichedEvent] -> Int
dayNumEvents tz now = length . getTodaysEvents tz now

getEventInfo:: (EnrichedEvent->String) -> [EnrichedEvent] -> String
getEventInfo field all@(e1:rest) =
    concat ["  [", show numHits, " ", hits, "]: ", url]
    where numHits = length all
          hits = if numHits == 1 then "Hit" else "Hits"
          url = field e1

sortedEventInfo:: (EnrichedEvent->String) -> [EnrichedEvent] -> String
sortedEventInfo field events =
    intercalate "\n" . map (getEventInfo field) $ fields
    where fields = sortBy (flip compare `on` length) groupedFields
          groupedFields = groupBy ((==) `on` field) .
                          sortBy (compare `on` field) .
                          filter (not . null . field) $
                          events

getGeo:: GeoDB -> EnrichedEvent -> String
getGeo geo event =
    case geoM of
      Nothing -> "Not found"
      Just geo ->
          case (B.unpack . G.geoCity $ geo,
                B.unpack . G.geoCountryName $ geo) of
            ("","") -> "Not found"
            ("",country) -> country
            (city, country) -> city ++ ", " ++ country
    where geoM = unsafeDupablePerformIO . geoLocateByIPAddress geo $ ip
          ip = B.pack . userIpaddress $ event

getWhois:: String -> String
getWhois ipAddr =
    case m of
      (Nothing,_) -> "Not found"
      (Just whoisStr,_) ->
          if null r then "Not found" else head r !! 1
          where r = whoisStr =~ "Organization: *(.*)" :: [[String]]
    where m = unsafeDupablePerformIO . whois $ ipAddr

getVisitorInfo:: GeoDB -> [EnrichedEvent] -> String
getVisitorInfo geo all@(e1:rest) =
    concat $ ["## ", userIpaddress e1, "\n",
            "+ Number of Visits: ", numVisits, "\n",
            "+ Geo: ", getGeo geo e1, "\n",
            "+ Organization: ", getWhois $ userIpaddress e1, "\n",
            "+ Timezone: ", osTimezone e1, "\n",
            "+ Pages:\n", sortedEventInfo pageUrl all, "\n"] ++
            referrerInfo
    where numVisits = show . length $ all
          referrers = sortedEventInfo pageReferrer all
          referrerInfo = if null referrers then []
                         else ["\n+ Referrers:\n", referrers]

dayReport:: TimeZone -> LocalTime -> GeoDB -> [EnrichedEvent] -> String
dayReport tz now geo events = intercalate "\n\n" report
    where report = ["# Statistics", stats,
                    "# Pages", dayPages,
                    "# Referrers", dayReferrers,
                    "# Visitors", intercalate "\n\n" visitorInfo]
          stats = intercalate "\n"
                  ["+ " ++ (show . length) visitors ++ " unique visitors.",
                   "+ " ++ (show . length) todaysEvents ++ " total events."]
          dayReferrers = sortedEventInfo pageReferrer todaysEvents
          dayPages = sortedEventInfo pageUrl todaysEvents
          visitorInfo = map (getVisitorInfo geo) sortedVisitors
          sortedVisitors = sortBy (flip compare `on` length) visitors
          visitors = groupBy ((==) `on` userIpaddress) .
                     sortBy (compare `on` userIpaddress) $
                     todaysEvents
          todaysEvents = getTodaysEvents tz now events

getStats:: [EnrichedEvent] -> String
getStats events = intercalate "\n"
                  ["+ " ++ (show . length) visitors ++ " unique visitors.",
                   "+ " ++ (show . length) events ++ " total events."]
    where visitors = groupBy ((==) `on` userIpaddress) .
                     sortBy (compare `on` userIpaddress) $
                     events

weekReport:: TimeZone -> LocalTime -> GeoDB -> [EnrichedEvent] -> String
weekReport tz now geo events = intercalate "\n\n" report
    where report = map (\r -> "# " ++ fst r ++ "\n" ++ snd r) $
                   ("Total", getStats eventsFlat) : zip dayTitles dayBreakdown
          dayTitles = map fst eventsGrouped
          dayBreakdown = map (getStats . snd) eventsGrouped
          eventsFlat = concatMap snd eventsGrouped
          eventsGrouped = getWeeksEvents tz now events