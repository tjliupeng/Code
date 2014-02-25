
public class SingleLinkedList {
	public static class node
	{
		private String val;
		private node next;
		
		public node(String value)
		{
			val = value;
			next = null;
		}
		
		public node(String value, node n)
		{
			val = value;
			next = n;
		}
		public void setNext(node n)
		{
			next = n;
		}
		
		public node getNext()
		{
			return next;
		}
		
		public String getValue()
		{
			return val;
		}
	}

	public static void Rotate(node head, int position)
	{
		int len = 0;
		node tmp = head;
		node tail = head;
		while(tmp != null)
		{
			len++ ;
			tail = tmp;
			tmp = tmp.getNext();			
		}
		
		if (len == 0)return;
		if (position == 0)return;
		if (position == len)return;
		tmp = head;
		node newtail = head;
		int movesteps = len - (position)%len;
		while(movesteps != 0)
		{
			newtail = tmp;
			tmp = tmp.getNext();
			movesteps--;
		}
		
		node newhead = tmp;
		tail.setNext(head);
		newtail.setNext(null);
		head = newhead;
		Print(head);
	}
	
	public static node Rotate2(node head, int position)
	{
		int len = 0;
		node tmp = head;
		while(tmp != null)
		{
			len++ ;
			tmp = tmp.getNext();
		}
		
		if (len == 0)return head;
		if ((position % len) == 0)return head;
		tmp = head;
		node tmp2 = null;
		int movesteps = len - (position)%len -1;
		while(movesteps != 0)
		{
			tmp = tmp.getNext();
			movesteps--;
		}
		
		while(tmp.getNext() != null)
		{
			tmp = tmp.getNext();
			if (tmp2 == null)
			{
				tmp2 = head;
			}
			else
			{
				tmp2 = tmp2.getNext();
			}
		}
		
		tmp.setNext(head);
		head = tmp2.getNext();
		tmp2.setNext(null);		
		return head;		
	}
	
	public static void Print(node head)
	{
		while(head != null)
		{
			System.out.println(head.getValue());
			head = head.getNext();
		}
	}
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		node node6 = new node("6", null);
		node node5 = new node("5", node6);
		node node4 = new node("4", node5);
		node node3 = new node("3", node4);
		node node2 = new node("2", node3);
		node node1 = new node("1", node2);
		//Rotate(node1, 4);
		node1 = Rotate2(node1, 1);
		Print(node1);
	}

}
