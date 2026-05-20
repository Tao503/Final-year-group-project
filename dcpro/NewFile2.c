#include <stdio.h>
int main()
{
  char check;
  printf("Enter a character: ");
  scanf("%c", &check);
  
  if(check >= 'a' && check <= 'z')
  {
  	printf("The character is LowerCase");
  }
  else if(check >= 'A' && check <= "Z')
  {
  	printf("This is UpperCase Character");
  }
  else{
	  printf("Invalid input Or not a character");
  }
}