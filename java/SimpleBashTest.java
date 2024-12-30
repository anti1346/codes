import java.io.BufferedReader;
import java.io.InputStreamReader;

public class SimpleBashTest {
    public static void main(String[] args) {
        try {
            // Step 1: Check bash path
            System.out.println("Bash Path: " + runCommand("which bash"));

            // Step 2: Run echo command
            System.out.println("Echo Result: " + runCommand("bash -c 'echo Hello from Bash'"));
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
        }
    }

    private static String runCommand(String command) throws Exception {
        Process process = Runtime.getRuntime().exec(command);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            StringBuilder result = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                result.append(line).append(System.lineSeparator());
            }
            process.waitFor(); // Ensure the process completes
            return result.toString().trim();
        }
    }
}
