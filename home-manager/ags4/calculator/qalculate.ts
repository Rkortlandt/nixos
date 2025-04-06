import { GLib, } from "astal";

export function calculate(expression: string): {result: string, error: null | string} {
    try {
        // Get terse version
        let [success, stdout, stderr] = GLib.spawn_command_line_sync(`qalc "${expression}"`);
        
        // Prepare return object
        const result: {result: string; error: null | string} = {
            result: "",
            error: null
        };
        
        // Handle full result
        if (success && stdout != null) {
            result.result = stdout.toString().trim();
        } else if (stderr != null) {
            result.error = (result.error ? result.error + "\n" : "") + 
                           "Full error: " + stderr.toString().trim();
        }
        
        return result;
    } catch (e) {
        return {
            result: "",
            error: "Error running qalc: " + (e instanceof Error? e.toString() : String(e)),
        };
    }
}

