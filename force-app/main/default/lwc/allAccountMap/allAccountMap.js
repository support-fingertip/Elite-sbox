import { LightningElement, wire,api } from 'lwc';
import getAllAccounts from '@salesforce/apex/AccountController.getAccounts';

export default class AllAccountMap extends LightningElement {
    @api recordId;
    mapMarkers = [];
    mapPolylines = [];
    mapShapes = [];
 

    @wire(getAllAccounts, { recordId: '$recordId' })
    wiredAccounts({ error, data }) {
        if (data) {
            // Filter accounts with coordinates and sort by Name (or another field)
            const markerAccounts = data
                .filter(account => account.GeoLocation__Latitude__s && account.GeoLocation__Longitude__s);

            // Build mapMarkers
            console.log('Marker Accounts:', markerAccounts);
            this.mapMarkers = markerAccounts.map(account => ({
                location: {
                    Latitude: account.GeoLocation__Latitude__s,
                    Longitude: account.GeoLocation__Longitude__s
                },
                title: account.Name,
                description: `Industry: ${account.Industry || 'N/A'}, Phone: ${account.Phone || 'N/A'}`,
                icon: 'standard:account',
                mapIcon: (account.Name === 'Account 1' || account.Name === 'Account 50')
                    ? {
                        path: 'M 125,5 155,90 245,90 175,145 200,230 125,180 50,230 75,145 5,90 95,90 z',
                        fillColor: 'red',
                        fillOpacity: 0.8,
                        strokeWeight: 0,
                        scale: 0.10,
                        anchor: { x: 122.5, y: 115 }
                      }
                    : null
            }));
            console.log('Map Markers:', JSON.stringify(this.mapMarkers, null, 2));

            // Build polyline connecting all accounts, in order
            if (this.mapMarkers.length > 1) {
                const latLngs = this.mapMarkers.map(m => ({
                    latitude: m.location.Latitude,
                    longitude: m.location.Longitude
                }));

                this.mapPolylines = [
                    {
                        latLngs,
                        strokeColor: '#FF0000',
                        strokeWeight: 3,
                        strokeOpacity: 0.7
                    }
                ];
            } else {
                this.mapPolylines = [];
            }
        } else if (error) {
            console.error('Error fetching accounts:', error);
        }
    }

     center = {
        location: { Latitude: '28.6139', Longitude: '77.2090' },
    };
}