import java.io.*;
public class Test {
	public static void main(String[] args) {
		System.out.println("Hello World, from Java!");
		System.out.flush();
		try{
			BufferedWriter br = new BufferedWriter(new FileWriter("/tmp/dpriv-java-test"));
			br.write("Hello World, from Java!\n");
			br.flush();
		} catch(Exception e){ }
	}
}
