int fibonacci(int n){
   if (n == 0){
      return 0;
   }else if (n == 1){
      return 1;
   }else{
      return (fibonacci(n-1) + fibonacci(n-2));
   }
} 
 
int main(){
   int i = 0, s;
   while(i < 5){
      s = fibonacci(i);
      printf(s);
      i = i + 1;
   }
   return 0;
}
 