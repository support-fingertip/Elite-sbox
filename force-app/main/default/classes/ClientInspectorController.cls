public with sharing class ClientInspectorController {
    private static final Integer MAX_BATCH_SIZE = 200; // batch size per call

    // -------------------
    // Fetch Templates
    // -------------------
    @AuraEnabled(cacheable=true)
    public static List<Data_Query_Object__c> getQueryTemplates() {
        return [SELECT Id, Name, SOQL_Query__c FROM Data_Query_Object__c ORDER BY Name];
    }

    // -------------------
    // Get record count for a SOQL
    // -------------------
    @AuraEnabled
    public static Integer getCountForSoql(Id templateId) {
        Data_Query_Object__c cfg = [
            SELECT Id, SOQL_Query__c
            FROM Data_Query_Object__c
            WHERE Id = :templateId
            LIMIT 1
        ];
        String baseFrom = extractFromClause(cfg.SOQL_Query__c);
        if (String.isBlank(baseFrom)) {
            throw new AuraHandledException('Unable to parse FROM clause from SOQL.');
        }
        String countSoql = 'SELECT COUNT() ' + baseFrom;
        try {
            Integer totalCount = Database.countQuery(countSoql);
            return totalCount;
        } catch (Exception ex) {
            throw new AuraHandledException('Count query failed: ' + ex.getMessage());
        }
    }

    // -------------------
    // Fetch batch of records
    // -------------------
    @AuraEnabled
    public static Map<String, Object> fetchBatch(Id templateId, Integer limitSize, Integer offset) {
        Data_Query_Object__c cfg = [
            SELECT Id, SOQL_Query__c
            FROM Data_Query_Object__c
            WHERE Id = :templateId
            LIMIT 1
        ];

        String rawSoql = cfg.SOQL_Query__c;
        if (String.isBlank(rawSoql)) {
            throw new AuraHandledException('SOQL template is empty.');
        }

        // Remove existing LIMIT/OFFSET/ORDER BY
        String paginatedSoql = stripLimitOffsetOrderBy(rawSoql);
        paginatedSoql += ' LIMIT ' + limitSize + ' OFFSET ' + offset;

        try {
            List<SObject> rows = Database.query(paginatedSoql);
            List<String> fieldNames = extractSelectFields(rawSoql);
            List<Map<String, Object>> records = new List<Map<String, Object>>();

            for (SObject s : rows) {
                Map<String, Object> rowMap = new Map<String, Object>();
                Map<String, Object> populated = s.getPopulatedFieldsAsMap();

                for (String f : fieldNames) {
                    Object val = getFieldValue(s, f);
                    rowMap.put(normalizeFieldKey(f), val);
                }

                if (!rowMap.containsKey('Id')) {
                    rowMap.put('Id', s.get('Id'));
                }
                records.add(rowMap);
            }

            Map<String, Object> result = new Map<String, Object>();
            result.put('records', records);
            result.put('fields', fieldNames);
            result.put('offset', offset);
            result.put('count', records.size());
            return result;

        } catch (Exception ex) {
            throw new AuraHandledException('Query failed: ' + ex.getMessage());
        }
    }

    // -------------------
    // Helper: Get nested field value dynamically
    // -------------------
    private static Object getFieldValue(SObject sObj, String fieldPath) {
        if (sObj == null || String.isBlank(fieldPath)) return null;

        String[] parts = fieldPath.split('\\.');
        SObject cur = sObj;
        Object val = null;

        try {
            for (Integer i = 0; i < parts.size(); i++) {
                String p = parts[i].trim();
                if (i == parts.size() - 1) {
                    // Last part = actual field
                    val = cur.get(p);
                } else {
                    Object nextObj = cur.get(p);
                    if (nextObj instanceof SObject) {
                        cur = (SObject) nextObj;
                    } else {
                        cur = null;
                        break;
                    }
                }
            }
        } catch (Exception ex) {
            val = null; // best effort
        }
        return val;
    }

    // -------------------
    // Helper: extract FROM clause (robust for multi-line SOQL)
    // -------------------
    private static String extractFromClause(String soql) {
        if (soql == null) return null;

        // Replace multiple spaces and line breaks with a single space
        String cleanSoql = soql.replaceAll('\\s+', ' ').trim();

        // Find "FROM" case-insensitive
        Integer idxFrom = cleanSoql.toLowerCase().indexOf(' from ');
        if (idxFrom == -1) return null;

        String fromPart = cleanSoql.substring(idxFrom);
        fromPart = stripLimitOffsetOrderBy(fromPart);
        return fromPart;
    }

    // -------------------
    // Helper: strip LIMIT, OFFSET, ORDER BY
    // -------------------
    private static String stripLimitOffsetOrderBy(String soql) {
        if (soql == null) return '';
        String lower = soql.toLowerCase();
        Integer idxOrder = lower.indexOf(' order by ');
        Integer idxLimit = lower.indexOf(' limit ');
        Integer idxOffset = lower.indexOf(' offset ');
        Integer cutIdx = soql.length();
        if (idxOrder > -1) cutIdx = Math.min(cutIdx, idxOrder);
        if (idxLimit > -1) cutIdx = Math.min(cutIdx, idxLimit);
        if (idxOffset > -1) cutIdx = Math.min(cutIdx, idxOffset);
        return soql.substring(0, cutIdx).trim();
    }

    // -------------------
    // Helper: extract SELECT fields
    // -------------------
    private static List<String> extractSelectFields(String soql) {
        List<String> res = new List<String>();
        if (soql == null) return res;

        // Remove line breaks
        String cleanSoql = soql.replaceAll('\\s+', ' ').trim();

        Integer idxSelect = cleanSoql.toLowerCase().indexOf('select ');
        Integer idxFrom = cleanSoql.toLowerCase().indexOf(' from ');
        if (idxSelect == -1 || idxFrom == -1) return res;

        String fields = cleanSoql.substring(idxSelect + 7, idxFrom);
        List<String> parts = fields.split(',');
        for (String p : parts) {
            String t = p.trim();
            if (t.length() > 0) res.add(t);
        }
        return res;
    }

    // -------------------
    // Normalize field key for LWC
    // -------------------
    private static String normalizeFieldKey(String fieldToken) {
        if (String.isBlank(fieldToken)) return '';
        String t = fieldToken.trim();

        // handle "AS alias"
        String lowerT = t.toLowerCase();
        Integer idx = lowerT.indexOf(' as ');
        if (idx > -1) {
            String alias = t.substring(idx + 4).trim();
            alias = alias.replaceAll('"', '').replaceAll('\'', '');
            return alias;
        }

        // Remove parentheses
        if (t.contains('(') && t.contains(')')) {
            t = t.replaceAll('[()]', '');
        }

        // Keep full path for relationships
        if (t.contains('.')) return t;

        return t;
    }
}