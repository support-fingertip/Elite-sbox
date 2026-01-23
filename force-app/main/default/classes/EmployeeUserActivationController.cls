public class EmployeeUserActivationController {
    public List<Employee__c> selectedEmployees { get; set; }
    public List<String> results { get; set; }
    public List<Id> selectedRecordIds { get; set; }
    public Boolean hasResults { get; set; }

    public EmployeeUserActivationController(ApexPages.StandardSetController controller) {
        selectedRecordIds = new List<Id>();
        selectedEmployees = new List<Employee__c>();
        results = new List<String>();
        hasResults = false; // Ensure results section is hidden initially

        for (Employee__c emp : (List<Employee__c>)controller.getSelected()) {
            selectedRecordIds.add(emp.Id);
        }
        if (!selectedRecordIds.isEmpty()) {
            selectedEmployees = [
                SELECT Id, Name, Primary_Phone_Number__c,Mail_Id__c,User_Name__c
                FROM Employee__c
                WHERE Id IN :selectedRecordIds
            ];
        }
    }

    public PageReference activateUsers() {
        results = new List<String>(); // Clear previous results
        hasResults = false; // Reset hasResults at the start

        if (selectedRecordIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No records selected. Please select at least one record.'));
            results.add('Error: No records selected.');
            hasResults = true; // Show results section for error
            System.debug('Results size: ' + results.size());
            return null;
        }

        try {
            List<Employee__c> employees = [
                SELECT
                Id, Name, Role__c, Role_Id__c, Payroll__c,
                Profile__c, Mail_Id__c, User_Name__c, Aadhar_Number__c, Primary_Phone_Number__c,
                Secondary_Phone_Number__c, PAN__c, DOB__c, DOJ__c, User_Type__c,
                Reporting_Manager__c, Reporting_Manager__r.Name, Reporting_Manager_Name__c, Replaced_For__c, Replaced_For__r.Name,
                Replaced_For_Name__c, Payroll_Type__c, Employee_Code__c, Vendor_Code__c, Band__c,
                Shift_Time__c, Headquarter__c, Relieving_date__c, Designation__c, District_In_charge__c,
                Sales_Channel__c, Region__c, Working_District__c, Territory__c,
                Territory__r.Name, Territory_Name__c, Area__c, ASM_TSM__c, RSM__c,
                Heirarchial_Number__c, Sr_TSE_TSE__c, State__c, District__c, Pincode__c,
                Street__c, Category__c, Employee_Approver_3_HR__c, Primary_Customer_Approver_1__c, Primary_Customer_Approver_2__c,
                Primary_Customer_Approver_3_CD__c, Secondary_Customer_Approver_1__c, Secondary_Customer_Approver_2__c,
                PJP_Approver_1__c, PJP_Approver_2__c, Expense_Approver_1__c, Expense_Approver_2_Finance_Department__c,
                Basic_Pay__c, Gross_Salary__c, Minimum_Order_value__c,User__c,Contract_Type__c
                FROM Employee__c
                WHERE Id IN :selectedRecordIds
            ];

            Set<String> profileNames = new Set<String>();
            Set<String> employeeCodes = new Set<String>();
            for (Employee__c emp : employees) {
                if (emp.Profile__c != null) {
                    profileNames.add(emp.Profile__c);
                    employeeCodes.add(emp.Employee_Code__c);
                }
            }
       
            
            // Query existing users by Employee_Code__c
            Map<String, User> employeeCodeToUserMap = new Map<String, User>();
            if (!employeeCodes.isEmpty()) {
                for (User u : [SELECT Id, Employee_Code__c, IsActive FROM User WHERE Employee_Code__c IN :employeeCodes]) {
                    employeeCodeToUserMap.put(u.Employee_Code__c, u);
                }
            }
            
            
            Map<String, Id> profileNameToId = new Map<String, Id>();
            for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
                profileNameToId.put(p.Name, p.Id);
            }

            List<User> usersToUpdate = new List<User>();
            List<User> usersToInsert = new List<User>();
            Map<Id, Id> employeeToUserIdMap = new Map<Id, Id>();

            for (Employee__c emp : employees) {
                try {
                    Id profileId = profileNameToId.get(emp.Profile__c);
                    if (profileId == null) {
                        results.add('Error for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): Profile "' + (emp.Profile__c ?? 'N/A') + '" not found.');
                        continue;
                    }

                    if (String.isBlank(emp.Mail_Id__c) || String.isBlank(emp.User_Name__c)) {
                        results.add('Error for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): Email or Username is missing.');
                        continue;
                    }

                    if (emp.User__c != null) {
                        usersToUpdate.add(new User(
                            Id = emp.User__c,
                            IsActive = true
                        ));
                        results.add('Success for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): User activated.');
                        employeeToUserIdMap.put(emp.Id, emp.User__c);
                    } 
                    else {
                        // Check for existing user by Employee_Code__c
                        User existingUser = employeeCodeToUserMap.get(emp.Employee_Code__c);
                        if (existingUser != null) {
                            // Existing user found with matching Employee_Code__c
                            usersToUpdate.add(new User(
                                Id = existingUser.Id,
                                IsActive = true
                            ));
                            results.add('Success for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): Existing user activated.');
                            employeeToUserIdMap.put(emp.Id, existingUser.Id);
                        } else {
                            // No existing user; create new user
                            User newUser = populateUserFields(new User(), emp, profileId);
                            usersToInsert.add(newUser);
                            employeeToUserIdMap.put(emp.Id, null);
                            results.add('Success for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): User creation queued.');
                        }
                    }
                } catch (Exception ex) {
                    results.add('Error for ' + (emp.Name ?? 'Unknown') + ' (Username: ' + (emp.User_Name__c ?? 'N/A') + '): ' + ex.getMessage());
                }
            }

            if (!usersToUpdate.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(usersToUpdate, false);
                for (Integer i = 0; i < updateResults.size(); i++) {
                    Database.SaveResult sr = updateResults[i];
                    Employee__c emp = findEmployeeByUserId(employees, usersToUpdate[i].Id);
                    if (!sr.isSuccess()) {
                        String empName = emp != null ? emp.Name : 'Unknown';
                        String userName = emp != null ? (emp.User_Name__c ?? 'N/A') : 'N/A';
                        String errorMsg = 'Error for ' + empName + ' (Username: ' + userName + '): Failed to update user: ';
                        for (Database.Error err : sr.getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        results.add(errorMsg);
                    }
                }
            }

            if (!usersToInsert.isEmpty()) {
                List<Database.SaveResult> insertResults = Database.insert(usersToInsert, false);
                for (Integer i = 0; i < insertResults.size(); i++) {
                    Database.SaveResult sr = insertResults[i];
                    User insertedUser = usersToInsert[i];
                    Employee__c emp = findEmployeeByUser(employees, insertedUser);
                    String empName = emp != null ? emp.Name : 'Unknown';
                    String userName = emp != null ? (emp.User_Name__c ?? 'N/A') : 'N/A';
                    if (sr.isSuccess()) {
                        employeeToUserIdMap.put(emp != null ? emp.Id : null, sr.getId());
                        try {
                            //System.resetPassword(sr.getId(), true);
                            results.add('Success for ' + empName + ' (Username: ' + userName + '): User created and password reset email sent.');
                        } catch (Exception ex) {
                            results.add('Warning for ' + empName + ' (Username: ' + userName + '): User created but password reset email failed: ' + ex.getMessage());
                        }
                    } else {
                        String errorMsg = 'Error for ' + empName + ' (Username: ' + userName + '): Failed to create user: ';
                        for (Database.Error err : sr.getErrors()) {
                            String rawMsg = err.getMessage();
                            
                            // If it's a duplicate username error, extract the readable part
                            if (rawMsg.contains('The username already exists in this or another Salesforce organization')) {
                                errorMsg += 'Duplicate Username.The username already exists in this or another Salesforce organization. ';
                            } else {
                                errorMsg += rawMsg + '; ';
                            }
                        }

                        results.add(errorMsg);
                    }
                }
            }

            if (!employeeToUserIdMap.isEmpty()) {
                results.add('Employee records queued for asynchronous update.');
                updateEmployeeRecords(employeeToUserIdMap);
            }

            hasResults = !results.isEmpty(); // Only show results section if there are results
            System.debug('Results size after processing: ' + results.size());
            System.debug('Results content: ' + results);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bulk operation failed: ' + ex.getMessage()));
            results.add('Error: Bulk operation failed: ' + ex.getMessage());
            hasResults = true; // Show results section for error
            System.debug('Results size after error: ' + results.size());
        }

        return null;
    }


    public static User populateUserFields(User user, Employee__c emp, Id profileId) {
        // Assume emp.Name contains the full name string
        String fullName = emp.Name;
        // Step 1: Normalize spacing
        fullName = fullName.trim().replaceAll('\\s+', ' ');
        
        // Step 2: Split the full name into parts
        List<String> nameParts = fullName.split(' ');
        
        // Step 3: Assign FirstName and LastName based on the number of parts
        String firstName;
        String lastName;
        
        if (nameParts.size() == 1) {
            // Single word name
            firstName = '';
            lastName = nameParts[0];
        }
        else if (nameParts.size() > 1) {
            // Multiple word name
            firstName = nameParts[0];
            
            // Manually join remaining parts for last name
            lastName = '';
            for (Integer i = 1; i < nameParts.size(); i++) {
                if (i > 1) {
                    lastName += ' '; // Add space between words
                }
                lastName += nameParts[i];
            }
        }
        
        user.FirstName = firstName;
        user.LastName = lastName;
        user.Email = emp.Mail_Id__c;
        user.Username = emp.User_Name__c;
        user.Phone = emp.Primary_Phone_Number__c;
        user.ProfileId = profileId;
        user.UserRoleId = emp.Role_Id__c;
        user.ManagerId = emp.Reporting_Manager__c;
        user.Aadhar_Number__c = emp.Aadhar_Number__c;
        
        user.Employee_Type__c = emp.User_Type__c;
        user.Employee_Code__c = emp.Employee_Code__c;
        user.Vendor_Code__c = emp.Vendor_Code__c;
        user.Payroll__c = emp.Payroll__c;
        user.Payroll_Type__c = emp.Payroll_Type__c;
        user.Contract_Type__c = emp.Contract_Type__c;
        user.Band__c = emp.Band__c;
        user.Headquarter__c = emp.Headquarter__c;
        
        user.Sales_Channel__c =emp.Sales_Channel__c;   
        user.Category__c = emp.Category__c;
        user.Territory__c = emp.Territory__c;
        user.Territory_Name__c = emp.Territory_Name__c;
        user.Area__c = emp.Area__c;
        user.Working_District__c = emp.Working_District__c;
        user.Region__c= emp.Region__c;
        user.Title = emp.Designation__c;
        
        
        user.RSM__c = emp.RSM__c;
        user.ASM_TSM__c = emp.ASM_TSM__c;
        user.Employee_Approver_3_HR__c = emp.Employee_Approver_3_HR__c;
        
        user.Secondary_Customer_Approver_1__c = emp.Secondary_Customer_Approver_1__c;
        user.Secondary_Customer_Approver_2__c = emp.Secondary_Customer_Approver_2__c;
        
        user.Primary_Customer_Approver_1__c = emp.Primary_Customer_Approver_1__c;
        user.Primary_Customer_Approver_2__c = emp.Primary_Customer_Approver_2__c;
        user.Primary_Customer_Approver_3_Credit_Dept__c = emp.Primary_Customer_Approver_3_CD__c;
        
        user.PJP_Approver_1__c = emp.PJP_Approver_1__c;
        user.PJP_Approver_2__c = emp.PJP_Approver_2__c;
        
        user.Expense_Approver_1__c = emp.Expense_Approver_1__c;
        user.Expense_Approver_2_Finance_Dept__c = emp.Expense_Approver_2_Finance_Department__c;
        user.District_In_charge__c = emp.District_In_charge__c;
        
        user.State__c = emp.State__c;
        user.District__c = emp.District__c; 
        user.Minimum_Order_value__c = emp.Minimum_Order_value__c;
        user.IsActive = true;
        
        user.CompanyName = 'Elite'; 
        user.Title = emp.Designation__c;
        user.TimeZoneSidKey = 'Asia/Kolkata'; 
        user.LocaleSidKey = 'en_IN'; 
        user.Alias = emp.Name.length() >= 5 ? emp.Name.substring(0, 5) : emp.Name;
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        
        
        return user;
    }

    public static Employee__c findEmployeeByUserId(List<Employee__c> employees, Id userId) {
        for (Employee__c emp : employees) {
            if (emp.User__c == userId) {
                return emp;
            }
        }
        return null;
    }

    public static Employee__c findEmployeeByUser(List<Employee__c> employees, User user) {
        for (Employee__c emp : employees) {
            if (emp.Mail_Id__c == user.Email && emp.User_Name__c == user.Username) {
                return emp;
            }
        }
        return null;
    }

    @future
    public static void updateEmployeeRecords(Map<Id, Id> employeeToUserIdMap) {
        try {
            List<Employee__c> employeesToUpdate = new List<Employee__c>();
            for (Id empId : employeeToUserIdMap.keySet()) {
                Id userId = employeeToUserIdMap.get(empId);
                Employee__c emp = new Employee__c(
                    Id = empId,
                    Is_Active__c = true
                );
                if (userId != null) {
                    emp.User__c = userId;
                }
                employeesToUpdate.add(emp);
            }
            if (!employeesToUpdate.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(employeesToUpdate, false);
                for (Database.SaveResult sr : updateResults) {
                    if (!sr.isSuccess()) {
                        String errorMsg = 'Error updating Employee record (ID: ' + sr.getId() + '): ';
                        for (Database.Error err : sr.getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        System.debug(errorMsg);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error updating Employee records: ' + e.getMessage());
        }
    }

    public PageReference cancel() {
        results = new List<String>(); // Clear results
        hasResults = false; // Hide results section
        return new PageReference('/' + Employee__c.SObjectType.getDescribe().getKeyPrefix());
    }
}