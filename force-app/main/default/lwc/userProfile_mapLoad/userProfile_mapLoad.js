import { LightningElement, track, api } from "lwc";
import getMapLocationDta from "@salesforce/apex/userProfileLWC.getMapLocationDta";

export default class UserProfile_mapLoad extends LightningElement {
    @api selectedId;
    @track mapFilter = {
        fromDate: "",
        toDate: ""
    };
    backendOriginalData = [];
    totalValData = {

    };
    @track mapData = [];
    vfPageUrl = "/apex/googleMapLwc";
    vfWindow = null; // Store VF page reference

    connectedCallback() {
        this.filterDataLoad();
        window.addEventListener("message", this.receiveMessage.bind(this));
    }

    filterDataLoad() {
        const today = new Date();
        const formattedToday = today.toISOString().split('T')[0];
        // const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        // const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        // const formatDate = (date) => date.toISOString().split("T")[0]; // YYYY-MM-DD format

        // this.mapFilter.fromDate = formatDate(firstDate);
        // this.mapFilter.toDate = formatDate(lastDate);
        this.mapFilter.fromDate = formattedToday;
        this.mapFilter.toDate = formattedToday;
        this.getmapData();
    }

    getmapData() {
        const { fromDate, toDate } = this.mapFilter;
        getMapLocationDta({ ids: this.selectedId, fromDate, toDate })
            .then((result) => {
                this.totalValData.exTotalAmt = result.exTotalAmt;
                this.totalValData.workingHrs = result.workingHrs;
                this.totalValData.kmTravel = result.kmTravel;
                this.processMapData(result);
            })
            .catch((error) => {
                console.error("Error fetching map data:", error);
            });
    }

    processMapData(data) {
        if (!data) {
            console.error("No data provided for processing map data.");
            return;
        }
    
        let formattedData = [];
    
        // Process PJP Visits
        data.PjpVisit?.forEach((acc) => {
            formattedData.push({
                lat: acc.ClockIn_Latitude__c,
                lng: acc.Clockin_Longitude__c,
                type: "PJP Visit",
                markerText: acc.Name
            });
        });
    
        // Process Non-PJP Visits
        data.NonPjpVisit?.forEach((acc) => {
            formattedData.push({
                lat: acc.ClockIn_Latitude__c,
                lng: acc.Clockin_Longitude__c,
                type: "Non PJP Visit",
                markerText: acc.Name
            });
        });
    
        // Process Productive Visits
        data.Productive?.forEach((visit) => {
            formattedData.push({
                lat: visit.ClockIn_Latitude__c,
                lng: visit.Clockin_Longitude__c,
                type: "PJP Productive Visit",
                markerText: visit.Name
            });
        });
    
        // Process Non-Productive Visits
        data.nonProductive?.forEach((visit) => {
            formattedData.push({
                lat: visit.ClockIn_Latitude__c,
                lng: visit.Clockin_Longitude__c,
                type: "Non PJP Productive Visit",
                markerText: visit.Name
            });
        });
    
        // Process New Stores
        data.newStores?.forEach((acc) => {
            formattedData.push({
                lat: acc.GeoLocation__Latitude__s,
                lng: acc.GeoLocation__Longitude__s,
                type: "New Stores",
                markerText: acc.Name
            });
        });
    
        // Process Office Locations
        data.officeLocation?.forEach((log) => {
            formattedData.push({
                lat: log.Clock_In_Location__Latitude__s,
                lng: log.Clock_In_Location__Longitude__s,
                type: "Office Location",
                markerText: log.Name
            });
        });
    
        // Default marker if no data found
        if (formattedData.length === 0) {
            formattedData.push({
                lat: 12.9928382,
                lng: 77.6864698,
                type: "Office Location",
                markerText: "Office Location"
            });
        }
    
        this.mapData = formattedData;
        this.prepareVFUrl();
    }
    

    prepareVFUrl() { 
        let baseUrl = "/apex/googleMapLwc?";
        let encodedData = encodeURIComponent(JSON.stringify(this.mapData));
        this.vfPageUrl = `${baseUrl}data=${encodedData}`;
    }

    handleIframeLoad() {
        const iframe = this.template.querySelector("iframe");
        if (iframe) {
            this.vfWindow = iframe.contentWindow;
            this.sendDataToVF();
        }
    }

    sendDataToVF() {
        if (!this.vfWindow) {
            console.error("VF window not ready yet!");
            return;
        }

        this.vfWindow.postMessage({ mapData: this.mapData }, "*");
    }

    receiveMessage(event) {
        console.log("Message received from VF page:", event.data);
    }

    handleFilterChange(event) {
        this.mapFilter[event.target.name] = event.target.value;
        this.mapFilter.toDate = event.target.value;
        this.getmapData();
    }
}