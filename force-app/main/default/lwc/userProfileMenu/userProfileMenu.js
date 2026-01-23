// import { LightningElement, wire } from 'lwc';
// import { getRecord } from 'lightning/uiRecordApi';
// import USER_ID from '@salesforce/user/Id';
// import NAME_FIELD from '@salesforce/schema/User.Name';

// export default class UserProfileMenu extends LightningElement {
//     userName = '';
//     isMenuOpen = false;

//     @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
//     wiredUser({ error, data }) {
//         if (data) {
//             this.userName = data.fields.Name.value;
//         } else if (error) {
//             console.error('Error fetching user data:', error);
//         }
//     }

//     toggleMenu() {
//         this.isMenuOpen = !this.isMenuOpen;
//     }

//     handleLogout(event) {
//         event.preventDefault();
        
//         // Get the base community domain and path
//         const baseUrl = window.location.origin; // e.g., https://yourdomain.force.com
//         const communityPath = window.location.pathname.split('/s')[0]; // e.g., /partner or /customer

//         // Redirect to logout with return to login/home page
//         const logoutUrl = `${baseUrl}/secur/logout.jsp?retUrl=${baseUrl + communityPath}/s/login`;

//         window.location.href = logoutUrl;
//     }

// }





// import { LightningElement, wire } from 'lwc';
// import { getRecord } from 'lightning/uiRecordApi';
// import USER_ID from '@salesforce/user/Id';
// import NAME_FIELD from '@salesforce/schema/User.Name';

// export default class UserProfileMenu extends LightningElement {
//     userName = '';
//     isMenuOpen = false;

//     @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
//     wiredUser({ error, data }) {
//         if (data) {
//             this.userName = data.fields.Name.value;
//         } else if (error) {
//             console.error('Error fetching user data:', error);
//         }
//     }

//     // Toggle the menu visibility
//     toggleMenu(event) {
//         this.isMenuOpen = !this.isMenuOpen;

//         // Stop the event from propagating, so it doesn't trigger closing when clicking on the avatar itself
//         event.stopPropagation();
//     }

//     // Handle logout
//     handleLogout(event) {
//         event.preventDefault();
        
//         // Get the base community domain and path
//         const baseUrl = window.location.origin;
//         const communityPath = window.location.pathname.split('/s')[0]; // e.g., /partner or /customer

//         // Redirect to logout with return to login/home page
//         const logoutUrl = `${baseUrl}/secur/logout.jsp?retUrl=${baseUrl + communityPath}/s/login`;

//         window.location.href = logoutUrl;
//     }

//     // Handle click outside the dropdown to close the menu
//     handleClickOutside(event) {
//         const menu = this.template.querySelector('.dropdown');
//         const avatar = this.template.querySelector('.avatar');

//         if (menu && !menu.contains(event.target) && !avatar.contains(event.target)) {
//             this.isMenuOpen = false;
//         }
//     }

//     // Add event listener for clicks on the document when component is inserted
//     connectedCallback() {
//         document.addEventListener('click', this.handleClickOutside.bind(this));
//     }

//     // Clean up event listener when component is removed
//     disconnectedCallback() {
//         document.removeEventListener('click', this.handleClickOutside.bind(this));
//     }
// }



import { LightningElement,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class UserProfileMenu extends LightningElement {
    userName = '';
    isSidebarOpen = false;

    // Wire the user's name
    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    // Toggle sidebar visibility
    toggleSidebar(event) {
        this.isSidebarOpen = !this.isSidebarOpen;
        event.stopPropagation(); // Stop event from propagating to close the sidebar
    }

    // Handle logout functionality
    handleLogout(event) {
        event.preventDefault();
        const baseUrl = window.location.origin;
        const communityPath = window.location.pathname.split('/s')[0];
        const logoutUrl = `${baseUrl}/secur/logout.jsp?retUrl=${baseUrl + communityPath}/s/login`;
        window.location.href = logoutUrl;
    }

    // Close the sidebar when clicking outside
    closeSidebar(event) {
        const sidebarContent = this.template.querySelector('.sidebar-content');
        if (sidebarContent && !sidebarContent.contains(event.target)) {
            this.isSidebarOpen = false;
        }
    }

    // Handle click outside to close the sidebar
    connectedCallback() {
        document.addEventListener('click', this.closeSidebar.bind(this));
    }

    // Clean up event listener when component is removed
    disconnectedCallback() {
        document.removeEventListener('click', this.closeSidebar.bind(this));
    }
}