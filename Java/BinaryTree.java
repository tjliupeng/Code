import java.util.Stack;


public class BinaryTree {

	public static class node
	{
		private String val;
		private node left;
		private node right;
		
		public node(String value){
			val = value;
			left = null;
			right = null;
		}
		
		public String getValue()
		{
			return val;
		}
		
		public node Left()
		{
			return left;
		}
		
		public node right()
		{
			return right;
		}
		
		public void setLeft(node l)
		{
			left = l;
		}
		
		public void setRight(node r)
		{
			right = r;
		}				
	}
	
	public static void process(node n)
	{
		System.out.println(n.getValue());
	}
	
	public static void NonrecursivePostOrder(node root)
	{
		if (root == null) return;
		Stack<node> stack = new Stack<node>();
		Stack<Boolean> visit = new Stack<Boolean>();
		node tmp = root;
		
		while(!stack.empty() || (tmp != null))
		{
			if (tmp != null)
			{
				stack.push(tmp);
				visit.push(false);
				tmp = tmp.Left();
			}
			else
			{
				tmp = stack.peek();
				if (visit.peek())
				{
					visit.pop();
					stack.pop();
					process(tmp);
					tmp = null;
				}
				else
				{
					visit.set(visit.size() -  1, true);
					tmp = tmp.right();
				}
			}
		}
	}
	
	public static void NonrecursiveInOrder(node root)
	{
		if (root == null) return;
		Stack<node> stack = new Stack<node>();
		//stack.add(root);
		node tmp = root;
		while(!stack.empty() || (tmp != null))
		{
			if (tmp != null)
			{
				stack.push(tmp);				
				tmp = tmp.Left();
			}
			else
			{
				tmp = stack.pop();
				process(tmp);
				tmp = tmp.right();
			}
		}
	}
	public static void NonRecursivePreOrder(node root)
	{
		if (root == null)
		{
			return;
		}
		
		Stack<node> stack = new Stack<node>();
		//stack.add(root);
		node tmp = root;
		while(!stack.empty() || (tmp != null))
		{
			if (tmp != null)
			{
				stack.push(tmp);
				process(tmp);
				tmp = tmp.Left();
			}
			else
			{
				tmp = stack.pop();
				tmp = tmp.right();
			}
		}
		/*while(!stack.empty())
		{
			tmp = stack.peek();
			process(tmp);
			if (tmp.Left() != null)
			{
				stack.push(tmp.Left());				
			}
			else
			{
				stack.pop();
				tmp = stack.pop();
				tmp = tmp.right();
				if (tmp != null)
					stack.push(tmp);
			}
		}*/
	}
	
	public static void main(String[] args)
	{
		node root = new node("A");
		node left1 = new node("B");
		node right1 = new node("C");
		node left2 = new node("D");
		node right2 = new node("E");
		node left31 = new node("F");
		node right31 = new node("G");
		node left32 = new node("H");
		node right32 = new node("I");
		node left41 = new node("j");
		
		root.setLeft(left1);
		root.setRight(right1);
		left1.setLeft(left2);
		left1.setRight(right2);
		left2.setLeft(left31);
		left2.setRight(right31);
		right2.setLeft(left32);
		right2.setRight(right32);
		left32.setLeft(left41);
		
		//NonRecursivePreOrder(root);
		//NonrecursiveInOrder(root);
		NonrecursivePostOrder(root);
	}
}
