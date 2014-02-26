import java.util.Arrays;


public class MyArray {

	//B[i] = A[1]*...*A[n]/A[i], don't use multiply. O(n)
	public static int[] MultiplyWithoutMe(int[] A)
	{
		if(A.length == 0)return null;
		int[] B = new int[A.length];
		int[] C = new int[A.length];
		int[] D = new int[A.length];
		Arrays.fill(B, 0);
		Arrays.fill(C, 0);
		Arrays.fill(D, 0);
		
		C[0] = 1;
		D[D.length - 1] = 1;
		
		for(int cnt = 1; cnt < C.length; cnt++)
		{
			C[cnt] = C[cnt - 1]*A[cnt - 1];
		}
		
		for(int cnt = D.length - 2; cnt >= 0; cnt--)
		{
			D[cnt] = D[cnt+1]*A[cnt+1];
		}
		
		for(int cnt = 0; cnt < B.length; cnt++)
		{
			B[cnt] = C[cnt] * D[cnt];
		}
		return B;
	}
	
	/*B[i] = A[1]*...*A[n]/A[i], don't use multiply. O(n), space O(1)
	 * First: B[i] = B[i-1]*A[i] ... B[n] = B[n-1], C = A[n]
	 * Second: B[i] = B[i-1] * C, C = C * A[i-1], ... B[0]
	*/
		public static int[] MultiplyWithoutMe2(int[] A)
		{
			if(A.length == 0)return null;
			int[] B = new int[A.length];
			int C = 0;
			Arrays.fill(B, 0);
						
			B[0] = A[0];
			for(int cnt = 1; cnt < B.length - 1; cnt++)
			{
				B[cnt] = B[cnt - 1]*A[cnt];
			}
			B[B.length - 1] = B[B.length - 2];
			C = A[A.length - 1];
			
			for(int cnt = B.length - 2; cnt >= 1; cnt--)
			{
				B[cnt] = B[cnt-1]*C;
				C = C*A[cnt];
			}
			
			B[0] = C;
			return B;
		}
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		int[] A = {2,3,4,5,6};
		int[] B = MultiplyWithoutMe(A);
		System.out.println(Arrays.toString(B));
		B = MultiplyWithoutMe2(A);
		System.out.println(Arrays.toString(B));
	}

}
