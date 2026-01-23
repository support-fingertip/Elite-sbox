public with sharing class GoogleMapsConfigController {
    @AuraEnabled(cacheable=true)
    public static String getMapsApiKey() {
        // Keep it simple for demo: read from a Custom Label
        // For ISVs, consider Protected Custom Metadata in a namespace.
        return System.Label.GOOGLE_MAPS_API_KEY;
    }
}