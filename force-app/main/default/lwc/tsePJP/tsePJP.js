import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccounts from '@salesforce/apex/AccountCalendarController.getBeats';
import getPjpItems from '@salesforce/apex/AccountCalendarController.getPjpItems';
import savePjpItems from '@salesforce/apex/AccountCalendarController.savePjpItems';

export default class tsepjp extends LightningElement {
    @api recordId; 
    @track accounts = [];
    @track filteredAccounts = [];
    @track calendarDays = [];
    @track draggedAccountId = null;
    
    currentDate = new Date();
    currentMonth = this.currentDate.toLocaleString('default', { month: 'long' });
    currentYear = this.currentDate.getFullYear();

    connectedCallback() {
        this.initializeCalendar();
        this.loadAccounts();
        this.loadPjpItems();
    }

    initializeCalendar() {
        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();
        
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        
        this.calendarDays = [];
        
        for (let i = 0; i < firstDay.getDay(); i++) {
            this.calendarDays.push({
                date: null,
                dayNumber: '',
                accounts: []
            });
        }
        
        for (let d = 1; d <= lastDay.getDate(); d++) {
            const date = new Date(year, month, d).toISOString().split('T')[0];
            this.calendarDays.push({
                date: date,
                dayNumber: d,
                accounts: []
            });
        }
    }

    loadAccounts() {
        getAccounts({ userId: this.recordId })
            .then(result => {
                this.accounts = result;
                this.filteredAccounts = [...this.accounts];
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadPjpItems() {
        getPjpItems({ 
            userId: this.recordId,
            month: this.currentDate.getMonth() + 1,
            year: this.currentDate.getFullYear()
        })
        .then(result => {
            this.populateCalendarWithPjpItems(result);
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    populateCalendarWithPjpItems(pjpItems) {
        this.calendarDays.forEach(day => {
            if (day.date) {
                day.accounts = pjpItems
                    .filter(item => item.date === day.date)
                    .map(item => ({
                        Id: item.accountId,
                        Name: item.accountName,
                        pjpItemId: item.id
                    }));
            }
        });
    }

    previousMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.updateCalendar();
    }

    nextMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.updateCalendar();
    }

    updateCalendar() {
        this.currentMonth = this.currentDate.toLocaleString('default', { month: 'long' });
        this.currentYear = this.currentDate.getFullYear();
        this.initializeCalendar();
        this.loadPjpItems();
    }

    handleDragStart(event) {
        this.draggedAccountId = event.target.dataset.id;
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const date = event.currentTarget.dataset.date;
        
        if (date && this.draggedAccountId) {
            const account = this.accounts.find(acc => acc.Id === this.draggedAccountId);
            
            if (account) {
                const dayIndex = this.calendarDays.findIndex(day => day.date === date);
                
                if (dayIndex !== -1) {
                    // Check if account already exists for this day
                    const exists = this.calendarDays[dayIndex].accounts.some(
                        acc => acc.Id === this.draggedAccountId
                    );
                    
                    if (!exists) {
                        this.calendarDays[dayIndex].accounts = [
                            ...this.calendarDays[dayIndex].accounts,
                            { Id: account.Id, Name: account.Name }
                        ];
                        
                        this.savePjpItems();
                    }
                }
            }
        }
    }

    removeAccount(event) {
        const date = event.target.dataset.date;
        const accountId = event.target.dataset.account;
        
        const dayIndex = this.calendarDays.findIndex(day => day.date === date);
        
        if (dayIndex !== -1) {
            this.calendarDays[dayIndex].accounts = this.calendarDays[dayIndex].accounts.filter(
                acc => acc.Id !== accountId
            );
            
            this.savePjpItems();
        }
    }

    handleAccountSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        
        if (searchTerm === '') {
            this.filteredAccounts = [...this.accounts];
        } else {
            this.filteredAccounts = this.accounts.filter(account => 
                account.Name.toLowerCase().includes(searchTerm))
        }
    }

    savePjpItems() {
        const pjpItems = [];
        
        this.calendarDays.forEach(day => {
            if (day.date) {
                day.accounts.forEach(account => {
                    pjpItems.push({
                        id: account.pjpItemId || null,
                        date: day.date,
                        accountId: account.Id
                    });
                });
            }
        });
        
        savePjpItems({
            userId: this.recordId,
            month: this.currentDate.getMonth() + 1,
            year: this.currentDate.getFullYear(),
            pjpItems: pjpItems
        })
        .then(() => {
            this.showToast('Success', 'PJP assignments saved', 'success');
            this.loadPjpItems(); 
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}