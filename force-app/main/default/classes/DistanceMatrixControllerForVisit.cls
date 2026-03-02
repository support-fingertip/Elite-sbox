public class DistanceMatrixControllerForVisit 
{
     //From Visit Trigger we calling this method
    @future(callout=true)
    public static void distanceCalculation(String visitId){
        system.debug('visit Id '+visitId);
        decimal distance =0;
        //Getting the Visit Record
        Visit__c vis = [SELECT Id,Name,Actual_Start_Time__c,Visit_for__c,Lead__c,Account1__c,ClockIn_Latitude__c,Clockin_Longitude__c,Distance__c,OwnerId,Daily_Log__c FROM Visit__c WHERE Id=:visitId];
        Daily_Log__c dl = new Daily_Log__c	();
        Datetime dt = vis.Actual_Start_Time__c;
        date d = dt.date();
        //Gettin the Daily log related to Visit
        if(vis.Actual_Start_Time__c!=null && vis.Daily_Log__c	!=null){
            dl = [SELECT Id,Name,Clock_In_Location__c,Clock_In_Location__Latitude__s,Clock_In_Location__Longitude__s,KMs_Travelled__c FROM Daily_Log__c WHERE Id=:vis.Daily_Log__c LIMIT 1];
        }
        
        if(vis!=null && vis.ClockIn_Latitude__c!=null && vis.Clockin_Longitude__c!=null && vis.Actual_Start_Time__c!=null)
        {
            List<Visit__c> vis2 = new  List<Visit__c>();
            //here it will try to get the before visit of the current visit (ex: current 10:30 visit -- previous visit 10: 29, 10:28)
            vis2 = [SELECT Id,Name,createdDate,Actual_Start_Time__c,Visit_for__c,Lead__c,Account1__c,ClockIn_Latitude__c,Clockin_Longitude__c FROM visit__c WHERE
                    DAY_ONLY(Actual_Start_Time__c)=:d AND Actual_Start_Time__c <=:vis.Actual_Start_Time__c AND Id!=:visitId AND 
                    OwnerId=:vis.OwnerId ORDER BY Actual_Start_Time__c DESC LIMIT 1];
            
            //If Vis2 not null means one previous visit existed. so it will send the current visit and previous visit locations
            if(vis2!=null && vis2.size()>0 )
            {
                if(vis2[0].ClockIn_Latitude__c!=null && vis2[0].Clockin_Longitude__c!=null)
                {
                    distance = distanceCalculationinKM( vis2[0].ClockIn_Latitude__c,vis2[0].Clockin_Longitude__c,vis.ClockIn_Latitude__c,vis.Clockin_Longitude__c);
                }
            }
            else
            {
                //here for this there is no previous visit.so we are sending the "day start location" and "visit location"
                if(dl!=null && dl.Clock_In_Location__c!=null){
                    distance = distanceCalculationinKM( dl.Clock_In_Location__Latitude__s,dl.Clock_In_Location__Longitude__s,vis.ClockIn_Latitude__c,vis.Clockin_Longitude__c);
                }
            }
        }
        system.debug(distance);
        if(distance!=0){
            vis.Distance__c = distance;
            update vis;
        }
    }
    
    //From Daily log Trigger we are callint this method
    @future(callout=true)
    public static void distanceCalculationForLastVisit(string dlId,decimal l1lat, decimal l1long,decimal  l2lat,decimal l2long){
        Daily_log__c dl = new Daily_log__c();
        dl.Id = dlId;
        //get Location from API
        if(label.ActivateGMapAPI == 'True')
        {
            Decimal distance = distanceCalculationinKM(l1lat,l1long,l2lat,l2long);
            dl.Last_visit_distance__c = distance;
        }
  		//Salesforce Standard Location 
        Decimal distanceSalesfroce = calculateHaversineDistance(l1lat,l1long,l2lat,l2long);
        dl.Last_Visit_Distance_Salesforce__c = distanceSalesfroce;
        Update dl;   
    }
    
    public static Decimal calculateHaversineDistance(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2){
        // Earth's radius varies from 6356.752 km at the poles to 6378.137 km at the equator
        Double radius = 6371.00;
        Double dLat = toRadians(lat2-lat1);
        Double dLon = toRadians(lon2-lon1);
        Double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
        Double c = 2 * Math.asin(Math.sqrt(a));
        
        double kmToMiles = 0.621371;
        return radius * c * kmToMiles;
    }
    
    private static Double toRadians(Decimal degree){
        return degree * 3.1415926 / 180;
    }
    
    //Calling Google matrix api to get distance
    public static decimal distanceCalculationinKM(decimal l1lat, decimal l1long,decimal  l2lat,decimal l2long){ 
        string ApiKey = label.GOOGLE_MAPS_API_KEY;
        string url = 'https://maps.googleapis.com/maps/api/distancematrix/json?';   
        url = url + 'origins='+ l1lat+','+ l1long;
        url = url + '&destinations='+ l2lat+','+ l2long;           
        url = url + '&key='+ApiKey;   
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');    
        Http http = new Http();
        
        if(!Test.isRunningTest()){
            
            
            HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            
            distancematrix dm =  (distancematrix)JSON.deserialize(res.getBody(),distancematrix.class);   
            if( ( dm.rows.size() > 0 )&& ( dm.rows[0].elements.size() > 0 )  ){
                system.debug(dm.rows[0].elements[0].distance.value/1000);
                return dm.rows[0].elements[0].distance.value/1000; 
                
            }else{ 
                return 0;
            } 
            
            
        }else{
            return 0; 
        } 
        
    }
    
    public class distancematrix{  
        public List<row> rows;   
    } 
    public class row{ 
        public List<element> elements;
    }
    public class element{ 
        public duration duration;
        public distance distance;
    }
    public class distance{ 
        public  string text;
        public  decimal value; 
    }
    public class duration{ 
        public  string text;
        public  decimal  value; 
    }
    
    // Calculate full day route using Google Routes API (start -> visits -> end)
    @future(callout=true)
    public static void distanceCalculationForDailyRouteOld(String dailyLogId){
        if(dailyLogId==null) return;
        Daily_Log__c dl = [SELECT Id, Clock_In_Location__Latitude__s, Clock_In_Location__Longitude__s, Clock_Out_Location__Latitude__s, Clock_Out_Location__Longitude__s, KMs_Travelled__c, Today_Day_Travelled_Distance_KM__c,
                            (SELECT Id,ClockIn_Latitude__c,Clockin_Longitude__c,Actual_Start_Time__c FROM Visits__r WHERE ClockIn_Latitude__c!=null AND Clockin_Longitude__c!=null ORDER BY Actual_Start_Time__c ASC)
                            FROM Daily_Log__c WHERE Id = :dailyLogId LIMIT 1];

        if(dl==null) return;

        Decimal startLat = dl.Clock_In_Location__Latitude__s;
        Decimal startLon = dl.Clock_In_Location__Longitude__s;
        Decimal endLat = dl.Clock_Out_Location__Latitude__s;
        Decimal endLon = dl.Clock_Out_Location__Longitude__s;

        // Start location (Clock In) is mandatory
        if(startLat==null || startLon==null) return;

        List<Visit__c> visits = dl.Visits__r;
        Boolean endIsLastVisit = false;

        // If end location (Clock Out) is not available, use the last visit location as destination
        if(endLat==null || endLon==null){
            if(visits!=null && visits.size()>0){
                Visit__c lastVisit = visits[visits.size()-1];
                endLat = lastVisit.ClockIn_Latitude__c;
                endLon = lastVisit.Clockin_Longitude__c;
                endIsLastVisit = true;
                System.debug('Clock Out location not available. Using last visit as destination: ' + lastVisit.Id);
            } else {
                System.debug('No Clock Out location and no visits found for Daily Log: ' + dailyLogId);
                return;
            }
        }

        if(endLat==null || endLon==null) return;

        // Build waypoints from intermediate visits
        // If the last visit is used as destination, exclude it from waypoints
        List<String> waypointParts = new List<String>();
        Integer visitCount = (visits!=null) ? visits.size() : 0;
        for(Integer i=0; i<visitCount; i++){
            if(endIsLastVisit && i == visitCount-1) continue;
            Visit__c v = visits[i];
            if(v.ClockIn_Latitude__c!=null && v.Clockin_Longitude__c!=null){
                waypointParts.add(v.ClockIn_Latitude__c+','+v.Clockin_Longitude__c);
            }
        }

        String ApiKey = label.GOOGLE_MAPS_API_KEY;
        String endpoint = 'https://routes.googleapis.com/directions/v2:computeRoutes?key=' + ApiKey;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        Http http = new Http();

        try{
            // Build request body for Routes API
            Map<String,Object> origin = new Map<String,Object>{'location' => new Map<String,Object>{'latLng' => new Map<String,Decimal>{'latitude'=>startLat,'longitude'=>startLon}}};
            Map<String,Object> destination = new Map<String,Object>{'location' => new Map<String,Object>{'latLng' => new Map<String,Decimal>{'latitude'=>endLat,'longitude'=>endLon}}};
            Map<String,Object> reqBodyMap = new Map<String,Object>{'origin' => origin, 'destination' => destination, 'travelMode' => 'DRIVE'};

            if(waypointParts.size()>0){
                List<Object> inter = new List<Object>();
                for(String wp : waypointParts){
                    List<String> parts = wp.split(',');
                    if(parts.size()==2){
                        Decimal wlat = Decimal.valueOf(parts[0]);
                        Decimal wlon = Decimal.valueOf(parts[1]);
                        inter.add(new Map<String,Object>{'location' => new Map<String,Object>{'latLng' => new Map<String,Decimal>{'latitude'=>wlat,'longitude'=>wlon}}});
                    }
                }
                reqBodyMap.put('intermediates', inter);
            }

            String bodyStr = JSON.serialize(reqBodyMap);
            req.setHeader('Content-Type','application/json');
            // Request route-level and leg-level distance from Routes API
            req.setHeader('X-Goog-FieldMask','routes.distanceMeters,routes.legs.distanceMeters');
            req.setBody(bodyStr);

            if(!Test.isRunningTest()){
                HTTPResponse res = http.send(req);
                if(res.getStatusCode() == 200){
                    routesResponse rr = (routesResponse) JSON.deserialize(res.getBody(), routesResponse.class);
                    if(rr != null && rr.routes != null && rr.routes.size()>0 && rr.routes[0] != null){
                        Decimal totalMeters = 0;
                        rroute route = rr.routes[0];
                        // Sum leg distances if available for more accuracy with intermediates
                        if(route.legs != null && route.legs.size()>0){
                            for(rleg l : route.legs){
                                if(l != null && l.distanceMeters!=null) totalMeters += l.distanceMeters;
                            }
                        } else if(route.distanceMeters != null){
                            // Fallback to route-level total distance
                            totalMeters = route.distanceMeters;
                        }

                        if(totalMeters > 0){
                            Decimal totalKm = totalMeters/1000;
                            Daily_Log__c upd = new Daily_Log__c(Id=dl.Id);
                            upd.KMs_Travelled__c = totalKm;
                            System.debug('Updating Daily Log with total route distance: ' + totalKm + ' km');
                            try{
                                update upd;
                            } catch(Exception e){
                                System.debug('Failed to update Daily_Log__c: ' + e.getMessage());
                            }
                            System.debug('Total route distance in km: ' + totalKm);
                        } else {
                            System.debug('Routes API returned route but no distance data. Response body: ' + res.getBody());
                        }
                    } else {
                        System.debug('Routes API returned no routes. Response body: ' + res.getBody());
                    }
                } else {
                    System.debug('Routes API response code: ' + res.getStatusCode() + ' body: ' + res.getBody());
                }
                System.enqueueJob(new EODReportQueueableMail(dl.Id));
            }
        }catch(Exception e){
            System.debug('Routes API call failed: '+e.getMessage());
        }
    }

    
    @future(callout=true)
    public static void distanceCalculationForDailyRoute(String dailyLogId){
        if(dailyLogId == null) return;
        
        Daily_Log__c dl = [
            SELECT Id,
            Clock_In_Location__Latitude__s, Clock_In_Location__Longitude__s,
            Clock_Out_Location__Latitude__s, Clock_Out_Location__Longitude__s,
            KMs_Travelled__c, Today_Day_Travelled_Distance_KM__c,
            (SELECT Id, ClockIn_Latitude__c, Clockin_Longitude__c, CreatedDate
             FROM Visits__r
             WHERE ClockIn_Latitude__c != null AND Clockin_Longitude__c != null
             ORDER BY CreatedDate ASC),
            (SELECT Id, Geo_Location__Latitude__s, Geo_Location__Longitude__s, CreatedDate
             FROM Visit_Forms__r
             WHERE Geo_Location__Latitude__s != null AND Geo_Location__Longitude__s != null
             ORDER BY CreatedDate ASC)
            FROM Daily_Log__c
            WHERE Id = :dailyLogId
            LIMIT 1
        ];
        
        if(dl == null) return;
        
        Decimal startLat = dl.Clock_In_Location__Latitude__s;
        Decimal startLon = dl.Clock_In_Location__Longitude__s;
        Decimal endLat   = dl.Clock_Out_Location__Latitude__s;
        Decimal endLon   = dl.Clock_Out_Location__Longitude__s;
        
        if(startLat == null || startLon == null) return;
        
        // -------------------------------------------------------
        // Build unified, time-ordered waypoint list
        // -------------------------------------------------------
        List<WaypointWrapper> allWaypoints = new List<WaypointWrapper>();
        
        if(dl.Visits__r != null){
            for(Visit__c v : dl.Visits__r){
                allWaypoints.add(new WaypointWrapper(v.ClockIn_Latitude__c, v.Clockin_Longitude__c, v.CreatedDate));
            }
        }
        
        if(dl.Visit_Forms__r != null){
            for(Visit_Form__c vf : dl.Visit_Forms__r){
                allWaypoints.add(new WaypointWrapper(vf.Geo_Location__Latitude__s, vf.Geo_Location__Longitude__s, vf.CreatedDate));
            }
        }
        
        allWaypoints.sort();
        
        // -------------------------------------------------------
        // Determine final destination (Clock Out or last waypoint)
        // -------------------------------------------------------
        Boolean endIsLastWaypoint = false;
        
        if(endLat == null || endLon == null){
            if(!allWaypoints.isEmpty()){
                WaypointWrapper last = allWaypoints[allWaypoints.size() - 1];
                endLat = last.lat;
                endLon = last.lon;
                endIsLastWaypoint = true;
            } else {
                System.debug('No Clock Out location and no waypoints found for Daily Log: ' + dailyLogId);
                return;
            }
        }
        
        if(endLat == null || endLon == null) return;
        
        // -------------------------------------------------------
        // Build the full ordered list of ALL points including
        // start and end so we can chunk correctly:
        // [start, w1, w2, ..., wN, end]
        // Each chunk will be: [chunkStart, ...25 intermediates..., chunkEnd]
        // chunkEnd of one chunk becomes chunkStart of the next
        // -------------------------------------------------------
        List<WaypointWrapper> fullRoute = new List<WaypointWrapper>();
        fullRoute.add(new WaypointWrapper(startLat, startLon, null)); // index 0 = clock in
        
        Integer intermediateLimit = endIsLastWaypoint ? allWaypoints.size() - 1 : allWaypoints.size();
        for(Integer i = 0; i < intermediateLimit; i++){
            fullRoute.add(allWaypoints[i]);
        }
        
        fullRoute.add(new WaypointWrapper(endLat, endLon, null)); // last = clock out / last waypoint
        
        // -------------------------------------------------------
        // Chunk strategy:
        // Each API call handles: 1 origin + up to 25 intermediates + 1 destination
        // That means each chunk covers 27 points, advancing 26 points at a time
        // The destination of chunk N becomes the origin of chunk N+1
        // -------------------------------------------------------
        final Integer MAX_INTERMEDIATES = 25;
        final Integer CHUNK_STEP        = MAX_INTERMEDIATES + 1; // 26 points advanced per chunk
        
        Decimal grandTotalMeters = 0;
        String  apiKey           = Label.GOOGLE_MAPS_API_KEY;
        String  endpoint         = 'https://routes.googleapis.com/directions/v2:computeRoutes?key=' + apiKey;
        Http    http             = new Http();
        Integer totalPoints      = fullRoute.size();
        
        Integer chunkStart = 0;
        
        while(chunkStart < totalPoints - 1){
            Integer chunkEnd = Math.min(chunkStart + CHUNK_STEP, totalPoints - 1);
            
            WaypointWrapper origin      = fullRoute[chunkStart];
            WaypointWrapper destination = fullRoute[chunkEnd];
            
            // Collect intermediates between origin and destination for this chunk
            List<Object> intermediates = new List<Object>();
            for(Integer i = chunkStart + 1; i < chunkEnd; i++){
                WaypointWrapper wp = fullRoute[i];
                intermediates.add(
                    new Map<String, Object>{
                        'location' => new Map<String, Object>{
                            'latLng' => new Map<String, Decimal>{
                                'latitude'  => wp.lat,
                                    'longitude' => wp.lon
                                    }
                        }
                    }
                );
            }
            
            Map<String, Object> reqBodyMap = new Map<String, Object>{
                'origin' => new Map<String, Object>{
                    'location' => new Map<String, Object>{
                        'latLng' => new Map<String, Decimal>{
                            'latitude'  => origin.lat,
                                'longitude' => origin.lon
                                }
                    }
                },
                    'destination' => new Map<String, Object>{
                        'location' => new Map<String, Object>{
                            'latLng' => new Map<String, Decimal>{
                                'latitude'  => destination.lat,
                                    'longitude' => destination.lon
                                    }
                        }
                    },
                        'travelMode' => 'DRIVE'
                        };
                            
                            if(!intermediates.isEmpty()){
                                reqBodyMap.put('intermediates', intermediates);
                            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Goog-FieldMask', 'routes.distanceMeters,routes.legs.distanceMeters');
            req.setBody(JSON.serialize(reqBodyMap));
            
            try{
                if(!Test.isRunningTest()){
                    HTTPResponse res = http.send(req);
                    
                    if(res.getStatusCode() == 200){
                        routesResponse rr = (routesResponse) JSON.deserialize(res.getBody(), routesResponse.class);
                        
                        if(rr != null && rr.routes != null && !rr.routes.isEmpty() && rr.routes[0] != null){
                            rroute route = rr.routes[0];
                            
                            if(route.legs != null && !route.legs.isEmpty()){
                                for(rleg l : route.legs){
                                    if(l != null && l.distanceMeters != null){
                                        grandTotalMeters += l.distanceMeters;
                                    }
                                }
                            } else if(route.distanceMeters != null){
                                grandTotalMeters += route.distanceMeters;
                            }
                            
                            System.debug('Chunk [' + chunkStart + ' -> ' + chunkEnd + '] distance accumulated. Running total: ' + grandTotalMeters + ' m');
                        } else {
                            System.debug('Chunk [' + chunkStart + ' -> ' + chunkEnd + '] returned no routes. Body: ' + res.getBody());
                        }
                    } else {
                        System.debug('Chunk [' + chunkStart + ' -> ' + chunkEnd + '] API error - Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
                    }
                }
            } catch(Exception e){
                System.debug('Chunk [' + chunkStart + ' -> ' + chunkEnd + '] API call failed: ' + e.getMessage());
            }
            
            // Move to next chunk — destination of this chunk becomes origin of next
            chunkStart = chunkEnd;
        }
        
        // -------------------------------------------------------
        // Save total distance and trigger EOD report
        // -------------------------------------------------------
        if(grandTotalMeters > 0){
            Decimal totalKm = grandTotalMeters / 1000;
            Daily_Log__c upd = new Daily_Log__c(Id = dl.Id);
            upd.KMs_Travelled__c = totalKm;
            try{
                update upd;
                System.debug('Updated Daily Log with grand total route distance: ' + totalKm + ' km');
                System.enqueueJob(new EODReportQueueableMail(dl.Id));
            } catch(Exception e){
                System.debug('Failed to update Daily_Log__c: ' + e.getMessage());
            }
        } else {
            System.debug('Grand total distance is 0 or no successful API responses. Skipping update.');
        }
    }

    
    // -------------------------------------------------------
    // Inner wrapper to unify Visit__c & Visit_Form__c records
    // -------------------------------------------------------
    public class WaypointWrapper implements Comparable {
        public Decimal  lat;
        public Decimal  lon;
        public Datetime createdDate;
        
        public WaypointWrapper(Decimal lat, Decimal lon, Datetime createdDate){
            this.lat         = lat;
            this.lon         = lon;
            this.createdDate = createdDate;
        }
        
        public Integer compareTo(Object other){
            WaypointWrapper o = (WaypointWrapper) other;
            if(this.createdDate == o.createdDate) return 0;
            return (this.createdDate < o.createdDate) ? -1 : 1;
        }
    }
    
    // Classes for Routes API response (computeRoutes)
    public class routesResponse{
        public List<rroute> routes;
    }
    public class rroute{
        public List<rleg> legs;
        public Long distanceMeters;
        public Long durationSeconds;
    }
    public class rleg{
        public Long distanceMeters;
        public Long durationSeconds;
    }
    
}