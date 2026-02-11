import { LightningElement, api } from 'lwc';

export default class UserSearchCombobox extends LightningElement {
    @api label;
    @api fieldName;
    @api userList = [];
    @api selectedUserId = '';
    @api selectedUserName = '';
    @api required = false;
    @api heirachyNumner = false;
    @api profileName = '';

    filteredUsers = [];
    showDropdown = false;

    get isReadOnly() {
        return !!this.selectedUserId;
    }

    handleSearch(event) {

        const searchValueName = event.target.value;

        if (searchValueName) {
            const searchedData = this.userList.filter(obj => {
            const nameMatch = obj.Name?.toLowerCase().includes(searchValueName.toLowerCase());
            const codeMatch = obj.Employee_Code__c?.toLowerCase().includes(searchValueName.toLowerCase()) || false;

            if (this.profileName) {
                const profileMatch = obj.Profile_Name__c?.toLowerCase() === this.profileName.toLowerCase();
                return (nameMatch || codeMatch) && profileMatch;
            } else {
                const empCodeNumber = Number(obj.Heirarchial_Number__c);
                const selectedHierarchy = Number(this.heirachyNumner);
                return (nameMatch || codeMatch) && !isNaN(empCodeNumber) && empCodeNumber > selectedHierarchy;
            }
            });

            this.filteredUsers = searchedData;
            this.showDropdown = searchedData.length > 0;
        } else {
            this.selectedUserId = '';
            this.selectedUserName = '';
            this.filteredUsers = [];
            this.showDropdown = false;

            this.dispatchUserSelected('', '');
        }
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedName = event.currentTarget.dataset.name;

        this.selectedUserId = selectedId;
        this.selectedUserName = selectedName;
        this.showDropdown = false;

        this.dispatchUserSelected(selectedId, selectedName);
    }

    dispatchUserSelected(id, name) {
        this.dispatchEvent(new CustomEvent('userselected', {
            detail: {
                id: id,
                name: name,
                fieldName: this.fieldName
            }
        }));
    }
}