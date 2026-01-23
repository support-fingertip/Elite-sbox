import { LightningElement,track } from 'lwc';
import getData from '@salesforce/apex/ForeCastController.getAllData';
import getForeData from '@salesforce/apex/ForeCastController.getForeCasts';
import saveForecastData from '@salesforce/apex/ForeCastController.saveForecastData';
import Fore_CAST_ICON from '@salesforce/resourceUrl/foreCastIcon';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ForeCastLwc extends LightningElement {
    isLoading = false;
    foreCasticon = Fore_CAST_ICON;
    @track periods = [];
    @track periodOptions = [];
    @track productCategories = [];
    @track productCategoryOptions = [];
    selectedCategory ='';
    selectedPeriod = '';
    @track foreCastList = [];
    @track curForeCast = [];
    @track productList = [];

    @track lastWeekMap = new Map();
    @track threeWeekMap = new Map();
    @track currentForecastMap = new Map();
    @track updatedForecastMap = new Map();

    currentforeCast = false;
    isDesktop = false;
    isPhone = false;

    //On loading this method will be called
    connectedCallback(){
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        //Getting All the Data
        this.fetchAllData();
        this.disablePullToRefresh();
    }
    //fetching All Data while loading
    fetchAllData() {
        this.isLoading = true;
        getData({})
            .then((result) => {
                console.log("Fetched Data:", JSON.stringify(result));
    
                // Populate Category Options
                this.productCategoryOptions = result?.productCategory?.map(proCat => ({ 
                    label: proCat.Name, 
                    value: proCat.Id 
                })) || [];
                this.productCategories = result?.productCategory || [];

                // Populate Period Options
                this.periodOptions = result?.periodsList?.map(period => ({ 
                    label: period.Name, 
                    value: period.Id 
                })) || [];
                this.selectedPeriod = result?.period || '';
                this.productList = result?.productList || [];

                this.processForecastData(result);
                this.selectedCategory = this.productCategories[0].Id;
                this.updateCurrentForecast();

            })
            .catch((error) => {
                this.isLoading = false;
                console.error("Error fetching data:", error);
                
                this.showToast('Error', `Error fetching data: ${error.body?.message || JSON.stringify(error)}`, 'error');
            });
    }
    //Proceesing and Forecast data and creating maps
    processForecastData(result)
    {
        console.log("Fetched Data:", JSON.stringify(result));

        // Populate Maps for Quick Lookup
        this.currentForecastMap = new Map();
        this.lastWeekMap = new Map();
        this.threeWeekMap = new Map();

      
        // Store current forecasts in Map (store both Forecast__c and Id)
        result?.currentForecasts?.forEach(forecast => {
            this.currentForecastMap.set(forecast.Product__c, {
                Id: forecast.Id,
                value: forecast.Forecast__c
            });
        });

        // Store last week forecasts in Map
        result?.lastWeekForecasts?.forEach(forecast => {
            this.lastWeekMap.set(forecast.Product__c, forecast.Forecast__c);
        });

        // Store last three weeks forecasts in Map (calculate average)
        let threeWeekTotals = new Map();
        let threeWeekCounts = new Map();

        result?.lastThreeWeekForecasts?.forEach(forecast => {
            let productId = forecast.Product__c;
            let total = threeWeekTotals.get(productId) || 0;
            let count = threeWeekCounts.get(productId) || 0;

            threeWeekTotals.set(productId, total + forecast.Forecast__c);
            threeWeekCounts.set(productId, count + 1);
        });

        threeWeekTotals.forEach((total, productId) => {
            this.threeWeekMap.set(productId, parseFloat((total / threeWeekCounts.get(productId)).toFixed(2)));
        });
        
        this.updatedForecastMap.clear(); 
        this.updateCurrentForecast();
        this.isLoading = false;
    }
    //WHen product category changed
    productCategoryChangeHandler(event) {
        let selectedValue = event.target.value;
        this.selectedCategory = selectedValue;
        this.updateCurrentForecast();
    }
    //Updating current forecasts
    updateCurrentForecast()
    {
        if (!this.productList || this.productList.length === 0 || !this.selectedCategory || this.selectedCategory =='') {
            console.error('Error: productList is empty or category Empty');
            this.isLoading = false;
            return;
        }
       
       
        const filteredProducts = this.productList.filter(
            product => product.Product_Category1__c === this.selectedCategory 
        );
    
        this.curForeCast = filteredProducts.map(product => {
            let forecastData = this.currentForecastMap.get(product.Id) || {};
            let updatedforecastData = this.updatedForecastMap.get(product.Id) || {};
            return {
                Id: product.Id,
                Name:product.Name,
                foreCastId: forecastData.Id || null,  
                productName: product.Name,
                productCode: product.Product_Code__c || '',
                // Restore forecast if already entered, otherwise use existing data
                foreCast: updatedforecastData.forecast || forecastData.value || '',
                lastWeekAvg: this.lastWeekMap.get(product.Id) || 0,
                threeWeekAvg: this.threeWeekMap.get(product.Id) || 0
            };
        });
    
        this.currentforeCast = this.curForeCast.length > 0;
    }
    //When the forecast value changed
    handleInputChange(event) {
        let productId = event.target.dataset.id; // Use product Id instead of index
        let newValue = event.target.value;
        let forecastid = event.target.dataset.forecastid;
        let productName = event.target.dataset.name;
        console.log('forecastid'+forecastid);
        
        // Store the updated value in the map
       // this.updatedForecastMap.set(productId, newValue);
        this.updatedForecastMap.set(productId, {
            forecast: newValue,
            Id: forecastid,
            Name:productName
        });

        // Update the UI list
        this.curForeCast = this.curForeCast.map(fr => ({
            ...fr,
            foreCast: fr.Id === productId ? newValue : fr.foreCast
        }));
    }
    //fetching All Data while loading
    periodChangeHandler(event) {
        
        this.selectedPeriod = event.target.value;
        this.isLoading = true;
        getForeData({selectedPeriod :this.selectedPeriod})
        .then((result) => {
            this.processForecastData(result);
        })
        .catch((error) => {
            this.isLoading = false;
            console.error("Error fetching data:", error);
            
            this.showToast('Error', `Error fetching data: ${error.body?.message || JSON.stringify(error)}`, 'error');
        });
    }
    // Save button Click
    handleSave() {
        this.isLoading = true;

        // Collect all entered forecasts
        let finalForecastData = [];
        this.updatedForecastMap.forEach((value, productId) => {
            finalForecastData.push({
                sobjectType: 'Product_Forecast__c',
                Product__c: productId,
                Forecast_Period__c: this.selectedPeriod,
                Forecast__c: value.forecast, // Extract only the forecast value
                Id: value.Id || null, // Include Id if available, otherwise null
                Name:value.Name
            });
        });

        console.log('Saving Forecast Data:', JSON.stringify(finalForecastData));

        saveForecastData({ foreCastData: finalForecastData, selectedPeriod: this.selectedPeriod })
        .then((result) => {
            this.showToast('Success', 'Forecast saved successfully!', 'success');
            this.updatedForecastMap.clear();

            // Store current forecasts in Map (store both Forecast__c and Id)
            this.currentForecastMap.clear(); // Ensure old values are removed
            result?.forEach(forecast => {
                this.currentForecastMap.set(forecast.Product__c, {
                    Id: forecast.Id, // Correct property name
                    value: forecast.Forecast__c
                });
            });

            this.updateCurrentForecast();
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error saving forecast:', error);
            this.showToast('Error', `Error saving data: ${error.body?.message || JSON.stringify(error)}`, 'error');
        });
    }

    //Show Toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    } 
    //disabling pul to refresh
    disablePullToRefresh() {
        const disableRefresh = new CustomEvent("updateScrollSettings", {
          detail: {
            isPullToRefreshEnabled: false
          },
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(disableRefresh);
    }
}