/**
* @File Name : ChildBeatOrderComparator.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 20, 2025 |   | Initial Version
**/

public class ChildBeatOrderComparator implements Comparator<Child_Beat__c> {
    private Map<Id, Integer> beatOrderMap;

    public ChildBeatOrderComparator(Map<Id, Integer> beatOrderMap) {
        this.beatOrderMap = beatOrderMap;
    }

   public Integer compare(Child_Beat__c cb1, Child_Beat__c cb2) {
    Integer order1 = beatOrderMap.get(cb1.Id);
    Integer order2 = beatOrderMap.get(cb2.Id);

    if (order1 == null && order2 == null) return 0;
    if (order1 == null) return 1;
    if (order2 == null) return -1;

    if (order1 < order2) return -1;
    if (order1 > order2) return 1;
    return 0;
}
}