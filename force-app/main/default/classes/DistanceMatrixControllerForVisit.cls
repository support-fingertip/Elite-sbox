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
        
        if(!test.isrunningtest()){
            
            
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
    
}