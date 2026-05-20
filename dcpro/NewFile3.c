#include <stdio.h>
int main()
{
	int score;
	printf("Enter Your score");
	scanf("%d", &score);
	if(score > 100)
	{
		printf("invalid");
	}

	else if(score>=75)
	{
		printf("Grade: A");
	}
		else if(score >= 65)
	{
		printf("Grade: B");
	}
		else if(score >= 45)
	{
		printf("Grade: C");
	}
		else if(score < 45)
	{
		printf("fail");
	}
	else{
		printf("invalid");
	}
}