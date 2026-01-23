@isTest
public class NumberTOWordConvertion_test {
    @isTest
    public static void getNumberTOWordConvertion_Test(){
        decimal num = 234456778;
        
        NumberTOWordConvertion nc = new NumberTOWordConvertion();
        NumberTOWordConvertion nc1 = new NumberTOWordConvertion(null);
        nc.getNumberTOWordConvertion(num);
        nc.getDayOfMonthSuffix(1);
        nc.getDayOfMonthSuffix(2);
        nc.getDayOfMonthSuffix(12);
        nc.getDayOfMonthSuffix(null);
        nc.getDayOfMonthSuffix(3);
        
    }
}