#include <stdio.h>

int main()
{
	char symbol;
	int num1, num2, result;
	
	printf("Enter Any of these: + - % / *: ");
	scanf("%c", & symbol);
	
	printf("Enter a number: ");
	scanf("%d", &num1);
	
    printf("Enter the second number: ");
	scanf("%d", &num2);
	
	switch(symbol)
	{
		case '+':
        result = num1 + num2;
        printf("Result: %d", result);
        break;
        
        case '-':
        result = num1 - num2;
        printf("Result: %d", result);
        break;
        
   		case '%':
        result = num1 % num2;
        printf("Result: %d", result);
        break;
    
   		case '/':
        result = num1 / num2;
        printf("Result: %d", result);
        break;
    
   		case '*':
        result = num1 * num2;
        printf("Result: %d", result);
        break;
    
        default:
        printf("Invalid Input");
	}
}