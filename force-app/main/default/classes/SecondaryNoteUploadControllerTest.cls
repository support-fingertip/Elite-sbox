@isTest
private class SecondaryNoteUploadControllerTest {

    @TestSetup
    static void setupData() {
        Account distributor = new Account(
            Name = 'Test Distributor',
            Customer_Type__c = 'Secondary Customer',
            State__c = 'Bihar',
            District__c = 'Patna'
        );
        insert distributor;

        List<Account> customers = new List<Account>{
            new Account(
                Name = 'Customer One',
                Customer_Code__c = 'CUST001',
                Customer_Type__c = 'Secondary Customer',
                State__c = 'Bihar',
                District__c = 'Patna'
            ),
            new Account(
                Name = 'Customer Two',
                Customer_Code__c = 'CUST002',
                Customer_Type__c = 'Secondary Customer',
                State__c = 'Bihar',
                District__c = 'Patna'
            )
        };
        insert customers;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Partner',
            AccountId = distributor.Id
        );
        insert con;

        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Partner Community User' LIMIT 1];
            String uniqueStr = String.valueOf(DateTime.now().getTime());
            User u = new User(
                FirstName = 'Upload', LastName = 'Partner',
                Email = 'snupload' + uniqueStr + '@test.com',
                Username = 'snupload' + uniqueStr + '@test.com.upload',
                Alias = 'snup', TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_IN', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = p.Id, ContactId = con.Id,
                Employee_Code__c = 'EMPUP' + uniqueStr
            );
            insert u;
        }
    }

    private static User getPartnerUser() {
        return [SELECT Id FROM User WHERE Username LIKE 'snupload%' AND IsActive = true LIMIT 1];
    }

    // ---------- uploadCreditNotes ----------

    @isTest
    static void testUploadCreditNotes_BlankInput() {
        Test.startTest();
        SecondaryNoteUploadController.UploadResult r1 = SecondaryNoteUploadController.uploadCreditNotes(null);
        SecondaryNoteUploadController.UploadResult r2 = SecondaryNoteUploadController.uploadCreditNotes('');
        Test.stopTest();

        System.assertEquals(0, r1.totalRecords);
        System.assertEquals(0, r1.successCount);
        System.assertEquals(0, r1.failedCount);
        System.assertEquals(0, r2.totalRecords);
    }

    @isTest
    static void testUploadCreditNotes_AllSuccess() {
        User u = getPartnerUser();
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-01-15',
                'amount'       => '250.50',
                'reason'       => 'Price Difference',
                'description'  => 'Bulk credit note'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST002',
                'creditDate'   => '15-01-2025',
                'amount'       => '99',
                'reason'       => 'Invoice Errors',
                'description'  => ''
            }
        };

        SecondaryNoteUploadController.UploadResult res;
        Test.startTest();
        System.runAs(u) {
            res = SecondaryNoteUploadController.uploadCreditNotes(JSON.serialize(rows));
        }
        Test.stopTest();

        System.assertEquals(2, res.totalRecords);
        System.assertEquals(2, res.successCount);
        System.assertEquals(0, res.failedCount);
        System.assertEquals(2, res.successes.size());
        System.assert(res.errors.isEmpty());
        // Verify success entries carry the new record id + auto-number name
        for (SecondaryNoteUploadController.RowSuccess s : res.successes) {
            System.assertNotEquals(null, s.recordId, 'recordId should be populated');
            System.assertNotEquals(null, s.recordName, 'recordName should be populated');
            System.assert(s.customerCode == 'CUST001' || s.customerCode == 'CUST002');
        }
        System.assertEquals(2, [SELECT COUNT() FROM Secondary_Credit_Note__c]);
    }

    @isTest
    static void testUploadCreditNotes_ValidationErrors() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            // missing customer code
            new Map<String, Object>{
                'customerCode' => '',
                'creditDate'   => '2025-01-15',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'no code'
            },
            // blank date
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'no date'
            },
            // invalid date format
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '13|01|2025',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'bad date'
            },
            // unparseable date with separator
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => 'aa-bb-cccc',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'unparseable'
            },
            // blank amount
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-01-15',
                'amount'       => '',
                'reason'       => 'Price Difference',
                'description'  => 'no amount'
            },
            // invalid amount
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-01-15',
                'amount'       => 'abc',
                'reason'       => 'Price Difference',
                'description'  => 'bad amount'
            },
            // zero amount
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-01-15',
                'amount'       => '0',
                'reason'       => 'Price Difference',
                'description'  => 'zero'
            },
            // unknown customer code
            new Map<String, Object>{
                'customerCode' => 'NOSUCH',
                'creditDate'   => '2025-01-15',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'unknown'
            },
            // wrong-length date parts
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-01',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'short date'
            },
            // year not 4 digits and last not 4 digits
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '25-01-25',
                'amount'       => '100',
                'reason'       => 'Price Difference',
                'description'  => 'ambiguous date'
            }
        };

        Test.startTest();
        SecondaryNoteUploadController.UploadResult res =
            SecondaryNoteUploadController.uploadCreditNotes(JSON.serialize(rows));
        Test.stopTest();

        System.assertEquals(rows.size(), res.totalRecords);
        System.assertEquals(0, res.successCount);
        System.assertEquals(rows.size(), res.failedCount);
        System.assertEquals(rows.size(), res.errors.size());

        // Each error should carry back the uploaded input so the user can see what failed.
        for (SecondaryNoteUploadController.RowError err : res.errors) {
            System.assertNotEquals(null, err.message);
            System.assertNotEquals(null, err.rowNumber);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Secondary_Credit_Note__c]);
    }

    @isTest
    static void testUploadCreditNotes_MixedAndDateFormats() {
        // Cover DD/MM/YYYY path and a mix of valid + invalid.
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '15/01/2025',
                'amount'       => '150',
                'reason'       => 'Price Difference',
                'description'  => 'slash format'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST002',
                'creditDate'   => '2025-02-20',
                'amount'       => '-5',  // not greater than zero
                'reason'       => 'Invoice Errors',
                'description'  => 'negative'
            }
        };

        Test.startTest();
        SecondaryNoteUploadController.UploadResult res =
            SecondaryNoteUploadController.uploadCreditNotes(JSON.serialize(rows));
        Test.stopTest();

        System.assertEquals(2, res.totalRecords);
        System.assertEquals(1, res.successCount);
        System.assertEquals(1, res.failedCount);
        System.assertEquals(1, res.successes.size());
        System.assertEquals(1, res.errors.size());
        System.assertEquals('CUST002', res.errors[0].customerCode);
    }

    @isTest
    static void testUploadCreditNotes_AsPartnerUserPopulatesDistributor() {
        User u = getPartnerUser();
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'creditDate'   => '2025-03-01',
                'amount'       => '500',
                'reason'       => 'Discounts or Rebates',
                'description'  => 'partner upload'
            }
        };

        SecondaryNoteUploadController.UploadResult res;
        Test.startTest();
        System.runAs(u) {
            res = SecondaryNoteUploadController.uploadCreditNotes(JSON.serialize(rows));
        }
        Test.stopTest();

        System.assertEquals(1, res.successCount);
        Secondary_Credit_Note__c inserted = [
            SELECT Id, Distributor__c, Customer__c
            FROM Secondary_Credit_Note__c
            LIMIT 1
        ];
        System.assertNotEquals(null, inserted.Distributor__c, 'Distributor should resolve from running user');
    }

    // ---------- uploadDebitNotes ----------

    @isTest
    static void testUploadDebitNotes_BlankInput() {
        Test.startTest();
        SecondaryNoteUploadController.UploadResult r = SecondaryNoteUploadController.uploadDebitNotes(null);
        Test.stopTest();

        System.assertEquals(0, r.totalRecords);
        System.assertEquals(0, r.successCount);
        System.assertEquals(0, r.failedCount);
    }

    @isTest
    static void testUploadDebitNotes_AllSuccess() {
        User u = getPartnerUser();
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'noteDate'     => '2025-01-10',
                'amount'       => '300',
                'reason'       => 'Short Payment',
                'description'  => 'd1'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST002',
                'noteDate'     => '10/01/2025',
                'amount'       => '450.75',
                'reason'       => 'Penalty',
                'description'  => ''
            }
        };

        SecondaryNoteUploadController.UploadResult res;
        Test.startTest();
        System.runAs(u) {
            res = SecondaryNoteUploadController.uploadDebitNotes(JSON.serialize(rows));
        }
        Test.stopTest();

        System.assertEquals(2, res.totalRecords);
        System.assertEquals(2, res.successCount);
        System.assertEquals(0, res.failedCount);
        System.assertEquals(2, res.successes.size());
        for (SecondaryNoteUploadController.RowSuccess s : res.successes) {
            System.assertNotEquals(null, s.recordId);
            System.assertNotEquals(null, s.recordName);
        }
        System.assertEquals(2, [SELECT COUNT() FROM Secondary_Debit_Note__c]);
    }

    @isTest
    static void testUploadDebitNotes_ValidationErrors() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerCode' => '',
                'noteDate'     => '2025-01-15',
                'amount'       => '100',
                'reason'       => 'Penalty',
                'description'  => 'no code'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'noteDate'     => '',
                'amount'       => '100',
                'reason'       => 'Penalty',
                'description'  => 'no date'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'noteDate'     => '13|01|2025',
                'amount'       => '100',
                'reason'       => 'Penalty',
                'description'  => 'bad date'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'noteDate'     => '2025-01-15',
                'amount'       => 'abc',
                'reason'       => 'Penalty',
                'description'  => 'bad amount'
            },
            new Map<String, Object>{
                'customerCode' => 'CUST001',
                'noteDate'     => '2025-01-15',
                'amount'       => '0',
                'reason'       => 'Penalty',
                'description'  => 'zero amount'
            },
            new Map<String, Object>{
                'customerCode' => 'UNKNOWN',
                'noteDate'     => '2025-01-15',
                'amount'       => '100',
                'reason'       => 'Penalty',
                'description'  => 'unknown'
            }
        };

        Test.startTest();
        SecondaryNoteUploadController.UploadResult res =
            SecondaryNoteUploadController.uploadDebitNotes(JSON.serialize(rows));
        Test.stopTest();

        System.assertEquals(rows.size(), res.totalRecords);
        System.assertEquals(0, res.successCount);
        System.assertEquals(rows.size(), res.failedCount);
        System.assertEquals(rows.size(), res.errors.size());
        System.assertEquals(0, [SELECT COUNT() FROM Secondary_Debit_Note__c]);
    }
}
