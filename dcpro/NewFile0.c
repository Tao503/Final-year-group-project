#include <stdio.h>
#include <string.h>
#include <math.h>
int main()
{
	int num1, sqr, result;
	char symbol[40];
	
	printf("enter the symbol for power of a numbero (x2): ");
	scanf("%d", &symbol);
	
	printf("enter a number: ");
	scanf("%d", &num1);
	
	if(strcmp(symbol, "x2")|| (strcmp(symbol, "x2")) ==0 )
		
		{
			result = num1 * num1;
			printf("result: %d", result);
		}

		
}