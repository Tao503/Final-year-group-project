#include <stdio.h>
int main()
{
	int num1, num2;
	printf("Enter Number-1");
	scanf("%d", &num1);
	
	printf("Enter Number -2: ");
	scanf("%d", &num2);
	
	if(num1 % num2 ==0){
		printf("Number-1 is divisible");
	}
	else{
		printf("Not divisible");
	}
}