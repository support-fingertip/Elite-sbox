/****************************************************************
* Class Name : VisitMapController
* Company : Fingertipplus
* Created Date : 28-10-2025
* @description : controller class for customMapView LWC : to show map in employee Object and user activity
* @author : Roopesh
* Used By : - customMapView LWC: connected with customMapViewVFP
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author | Date | Description
* -----------------------------------------------------------------------------
* 1.0 | Roopesh |  28-10-2025 | Initial version
* -----------------------------------------------------------------------------
******************************************************************/

public with sharing class VisitMapController {
    
    public class VisitDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Double lat;
        @AuraEnabled public Double lng;
        @AuraEnabled public String outcome;
        @AuraEnabled public Date visitDate;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public Boolean startingPoint = false;
        @AuraEnabled public Boolean endingPoint = false;
        @AuraEnabled public String markerText;
        @AuraEnabled public Datetime visitTime;
        @AuraEnabled public String recordUrl;
    }

    public class VisitResponse {
        @AuraEnabled public List<VisitDTO> visits;
        @AuraEnabled public Double startLat; 
        @AuraEnabled public Double startLng;
        @AuraEnabled public Double endLat; 
        @AuraEnabled public Double endLng;
        @AuraEnabled public Double distance;
        @AuraEnabled public Double totalCall;
        @AuraEnabled public String userName;
        @AuraEnabled public Double totpjpProd;
        @AuraEnabled public Double nonpjpProd;
        @AuraEnabled public Double newOut;
        @AuraEnabled public Double nonPJPPro;
        @AuraEnabled public Double totalGeo;
        @AuraEnabled public String baseUrl;
         @AuraEnabled public String tokenapi;
    }

    // Comparator to sort visits by visitTime
    public class VisitTimeComparator implements Comparator<VisitDTO> {
        public Integer compare(VisitDTO a, VisitDTO b) {
            // Handle nulls safely (nulls go last)
            if (a.visitTime == null && b.visitTime == null) return 0;
            if (a.visitTime == null) return 1;
            if (b.visitTime == null) return -1;

            // Ascending order (earlier first)
            if (a.visitTime < b.visitTime) return -1;
            if (a.visitTime > b.visitTime) return 1;
            return 0;
        }
    }
//(cacheable=true)
    @AuraEnabled 
    public static VisitResponse getVisits(Id userId, Date selectedDate, Id recId) {
        VisitResponse resp = new VisitResponse();
        resp.visits = new List<VisitDTO>();
 		resp.baseUrl = System.Url.getOrgDomainUrl().toExternalForm()+'/';
		resp.tokenapi=label.GOOGLE_MAPS_API_KEY;
   system.debug('resp.tokenapi>>'+resp.tokenapi);     
        if (userId == null) userId = UserInfo.getUserId();
        if (selectedDate == null) selectedDate = Date.today().addDays(-10);

        if (recId != null) {
            employee__c em = [SELECT Id, User__c, User_Formula__c FROM employee__c WHERE Id = :recId];
            resp.userName = em.User_Formula__c;
            userId = em.User__c;
        } else {
            User us = [SELECT Id, Name FROM User WHERE Id = :userId];
            resp.userName = us.Name;
        }
system.debug('userId>>'+userId);
        // Fetch Visits for that user/date
        List<Visit__c> rows = [
            SELECT Id, Account1__r.Name, ClockIn_Latitude__c, Clockin_Longitude__c,
                   Visit_Output__c, Visit_Date__c, CreatedDate, Actual_Start_Time__c, Actual_End_Time__c
            FROM Visit__c
            WHERE OwnerId = :userId
            AND Visit_Date__c = :selectedDate
            AND ClockIn_Latitude__c != null 
            AND Clockin_Longitude__c != null
            ORDER BY Actual_Start_Time__c
            LIMIT 2000
        ];
system.debug(selectedDate);
        List<Order__c> ord = [
            SELECT Id, Name, Clock_In_Location__latitude__s, Clock_In_Location__longitude__s, 
                   CreatedDate, Customer_Name__c,Order_Date__c
            FROM Order__c 
            WHERE Order_Date__c = :selectedDate 
            AND CreatedById = :userId 
            AND Visit__c = null AND Clock_In_Location__latitude__s!=null
        ]; 
        
        
        list<Account>acc=[select id,name,GeoLocation__latitude__s,GeoLocation__longitude__s,Customer_Created_Date__c,CreatedDate from Account
                          WHERE Customer_Created_Date__c = :selectedDate 
                          AND CreatedById = :userId 
                          AND GeoLocation__longitude__s!= null ];
            
            
system.debug(ord.size());
        // Fetch Daily Log
        Daily_Log__c dl;
        try {
            dl = [
                SELECT Id, Name,
                       Clock_In_Location__Latitude__s, Clock_In_Location__Longitude__s, 
                       Day_ended_time__c, Day_started_time__c,
                       Clock_Out_Location__Latitude__s, Clock_Out_Location__Longitude__s,
                       Total_Working_Hours__c, Distance_Travelled_Map__c, Distance_Travelled__c,
                       Total_Productive_Calls__c, Total_Non_Productive_Calls__c, New_Calls__c,
                       Non_PJP_Productive_Calls__c, Total_Calls__c, Total_Normal_Call__c
                FROM Daily_Log__c
                WHERE OwnerId = :userId
                AND Day_Started_Date__c = :selectedDate
                LIMIT 1
            ];

          //  resp.distance = dl.Distance_Travelled__c;
            resp.distance = dl.Distance_Travelled__c;
            resp.totalCall = dl.Total_Calls__c;
            resp.totpjpProd = dl.Total_Productive_Calls__c;
            resp.nonpjpProd = dl.Total_Non_Productive_Calls__c;
            resp.newOut = dl.New_Calls__c;
            resp.nonPJPPro = dl.Non_PJP_Productive_Calls__c;
            resp.totalGeo = dl.Total_Normal_Call__c;
        } catch (Exception e) {
            System.debug('️ No Daily_Log__c found: ' + e.getMessage());
        }

        Integer seq = 0;
        
        
        // Add Starting Point
        if (dl != null && dl.Clock_In_Location__Latitude__s != null && dl.Clock_In_Location__Longitude__s != null) {
            VisitDTO startDTO = new VisitDTO();
            startDTO.id = dl.Id;
            startDTO.name = 'Starting Point';
            startDTO.lat = (Double)dl.Clock_In_Location__Latitude__s;
            startDTO.lng = (Double)dl.Clock_In_Location__Longitude__s;
            startDTO.startingPoint = true;
            startDTO.sequence = seq;
            startDTO.markerText ='🏁' + 
                '\n Start: ' + dl.Day_started_time__c.format('dd/MM/yyyy, h:mm a');
            startDTO.visitTime = dl.Day_started_time__c;
            
            resp.visits.add(startDTO);
        }

        // Add Visit__c records
        for (Visit__c v : rows) {
            VisitDTO d = new VisitDTO();
            d.id = v.Id;
            d.name = (v.Account1__r == null ? 'Unknown' : v.Account1__r.Name);
            d.lat = (Double)v.ClockIn_Latitude__c;
            d.lng = (Double)v.Clockin_Longitude__c;
            d.outcome = v.Visit_Output__c;
            d.visitDate = v.Visit_Date__c;
            d.startingPoint = false;
            d.markerText = 
             //   d.name + 
                '\n Start: ' + (v.Actual_Start_Time__c != null ? v.Actual_Start_Time__c.format('dd/MM/yyyy, h:mm a') : 'N/A') +
                '<br/> End: ' + (v.Actual_End_Time__c != null ? v.Actual_End_Time__c.format('dd/MM/yyyy, h:mm a') : 'In Progress');
            d.visitTime = v.Actual_Start_Time__c;
            resp.visits.add(d);
        }

        // Add Order__c records
        for (Order__c v : ord) {
            VisitDTO d = new VisitDTO();
            d.id = v.Id;
            d.name = (v.Customer_Name__c == null ? 'Unknown' : v.Customer_Name__c);
            d.lat = (Double)v.Clock_In_Location__latitude__s;
            d.lng = (Double)v.Clock_In_Location__longitude__s;
            d.outcome = 'Non PJP Productive';
            d.markerText = 
              //  d.name + 
                '\n Order Id: ' + v.Name + 
                '<br/> Order Time: ' + v.CreatedDate.format('dd/MM/yyyy, h:mm a');
            d.visitTime = v.CreatedDate;
            resp.visits.add(d);
        }
        
          // Add account records
        for (account v : acc) {
            VisitDTO d = new VisitDTO();
            d.id = v.Id;
            d.name = (v.Name == null ? 'Unknown' : v.Name);
            d.lat = (Double)v.GeoLocation__latitude__s;
            d.lng = (Double)v.GeoLocation__longitude__s;
            d.outcome = 'New Outlet';
            d.markerText = 
             //   d.name + 
              //  '\n Account Name: ' + v.Name + 
                ' Created Time: ' + v.CreatedDate.format('dd/MM/yyyy, h:mm a');
            d.visitTime = v.CreatedDate;
            resp.visits.add(d);
        }

        // Add Ending Point
        if (dl != null && dl.Clock_Out_Location__Latitude__s != null && dl.Clock_Out_Location__Longitude__s != null) {
            VisitDTO endDTO = new VisitDTO();
            endDTO.id = dl.Id;
            endDTO.name = 'Ending Point';
            endDTO.lat = (Double)dl.Clock_Out_Location__Latitude__s;
            endDTO.lng = (Double)dl.Clock_Out_Location__Longitude__s;
            endDTO.endingPoint = true;
            endDTO.sequence = ++seq;
            endDTO.markerText = '🏁 ' + 
                '\n End: ' + dl.Day_ended_time__c.format('dd/MM/yyyy, h:mm a');
            endDTO.visitTime = dl.Day_ended_time__c;
            resp.visits.add(endDTO);
        }

        // Sort visits by visitTime
        resp.visits.sort(new VisitTimeComparator());

        // Set map center points
        if (!resp.visits.isEmpty()) {
            resp.startLat = resp.visits[0].lat;
            resp.startLng = resp.visits[0].lng;
            resp.endLat = resp.visits[resp.visits.size() - 1].lat;
            resp.endLng = resp.visits[resp.visits.size() - 1].lng;
        }
        for(VisitDTO st:resp.visits){
             System.debug('Final : '+st.markerText+' --'+st.visitTime);
        }
        return resp;
    }
}