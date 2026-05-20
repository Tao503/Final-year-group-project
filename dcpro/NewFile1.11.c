#include <stdio.h>
int main()
{
	int num1, num2, result;
	
	printf("Number-1: ");
	scanf("%d", &num1);
	
	printf("Number-2: ");
	scanf("%d", &num2);
	
	result = num1 - num2;
	
	if( result == num1 || result == num2)
		printf("The difference is equal to the value entered"); 
}