public class SMSAPIService {
    public static Boolean sendSMS(String mobileNo, String OTP) {
        try {
            // Fetch metadata record
            External_API_Configuration__mdt config = [
                SELECT Sender_ID__c, Endpoint_URL__c, API_Key__c, Method__c 
                FROM External_API_Configuration__mdt 
                WHERE DeveloperName = 'SMS_API' 
                LIMIT 1
            ];

            // Create HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(config.Endpoint_URL__c);
            request.setMethod(config.Method__c);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
			system.debug('OTP------------------'+OTP);
            // Prepare SMS message
            String message = 'We welcome you to Elite Foods and Innovation Group.\n'
                + 'Kindly pass on the Customer confirmation Number to our representative.\n'
                + 'Your onboarding CCN is ' + OTP;

            // Encode body
            String body = 'apikey=' + config.API_Key__c
                        + '&sender=' + config.Sender_ID__c
                        + '&mobileno=' + EncodingUtil.urlEncode(mobileNo, 'UTF-8')
                        + '&text=' + EncodingUtil.urlEncode(message, 'UTF-8');

            request.setBody(body);
               System.debug('SMS request Body: ' + request.getBody());

            // Send request
            HttpResponse response = http.send(request);
            System.debug('SMS Response Body: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                system.debug('response.getStatusCode()'+response.getStatusCode());
                // Parse response to get "status"
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String status = (String) result.get('status');
                system.debug('status'+status);
                return status != null && status.toLowerCase() == 'success';
            } else {
                return false;
            }
        } catch (Exception ex) {
            System.debug('SMS API Exception: ' + ex.getMessage());
            return false;
        }
    }
}