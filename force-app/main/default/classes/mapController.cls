public class mapController {
      @AuraEnabled(cacheable=true)
public static List<Visit__c> getVisits(Id ids, Date fromDate, Date toDate) {
    if (ids == null || fromDate == null || toDate == null) {
        return new List<Visit__c>();
    }
    System.debug('employeeId ===== ' + ids);
    System.debug('fromDate ===== ' + fromDate);
    System.debug('toDate ===== ' + toDate);

   
  Datetime fromDateTime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
Datetime toDateTime   = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 999));

List<Visit__c> visits = [
    SELECT Id, Name, Visit_for__c, ClockIn_Latitude__c, ClockIn_Longitude__c,
           OwnerId, Visit_Date__c, CreatedDate
    FROM Visit__c
    WHERE OwnerId = :ids
    AND CreatedDate >= :fromDateTime
    AND CreatedDate <= :toDateTime
    AND ClockIn_Latitude__c != null
    AND ClockIn_Longitude__c != null
];
    System.debug('Fetched Visits ===== ' + visits);
    System.debug('Fetched Visits Count ===== ' + visits.size());

    return visits;
}


}