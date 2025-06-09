import { GLib, } from "astal";

export function calculate(expression: string): { result: string, terse: string, error: null | string } {
    try {
        let utf8decoder = new TextDecoder();
        // Get terse version
        let [success, stdout, stderr] = GLib.spawn_command_line_sync(`qalc "${expression}"`);

        // Prepare return object
        const result: { result: string; terse: string; error: null | string } = {
            result: "",
            terse: "",
            error: null
        };

        // Handle full result
        if (success && stdout != null) {
            result.result = utf8decoder.decode(stdout).trim();
        } else if (stderr != null) {
            result.error = (result.error ? result.error + "\n" : "") +
                "Full error: " + utf8decoder.decode(stderr).trim();
        }

        [success, stdout, stderr] = GLib.spawn_command_line_sync(`qalc -t "${expression}"`);

        if (success && stdout != null) {
            result.terse = utf8decoder.decode(stdout).trim();
        } else if (stderr != null) {
            result.error = (result.error ? result.error + "\n" : "") +
                "Full error: " + utf8decoder.decode(stderr).trim();
        }

        return result;
    } catch (e) {
        return {
            result: "",
            terse: "",
            error: "Error running qalc: " + (e instanceof Error ? e.toString() : String(e)),
        };
    }
}

