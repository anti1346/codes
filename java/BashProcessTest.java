import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

public class BashProcessTest {
    public static void main(String[] args) {
        try {
            // Step 1: Check the bash path using `which bash`
            String bashPath = executeCommand(new String[]{"which", "bash"});
            System.out.println("Bash Path: " + bashPath);

            // Step 2: Execute echo command using bash
            if (bashPath != null && !bashPath.isEmpty()) {
                String echoResult = executeCommand(new String[]{bashPath.trim(), "-c", "echo Hello from Bash"});
                System.out.println("Echo Result: " + echoResult);
            } else {
                System.err.println("Bash not found. Please ensure bash is installed and in PATH.");
            }
        } catch (IOException e) {
            System.err.println("IOException occurred: " + e.getMessage());
        } catch (InterruptedException e) {
            System.err.println("Process was interrupted: " + e.getMessage());
        }
    }

    private static String executeCommand(String[] command) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true); // Combine error stream with output stream
        Process process = processBuilder.start();

        // Read the output of the command
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            StringBuilder output = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append(System.lineSeparator());
            }

            // Wait for the process to complete
            process.waitFor();
            return output.toString().trim();
        }
    }
}