
class BrightnessService extends Service {
    static {
        Service.register(
            this,
            {
                'screen-changed': ['float'],
                'value-changed': ['float'],
            },
            {
                'screen-value': ['float', 'r'],
                'value': ['float', 'rw'],
            },
        );
    }

    #interface = Utils.exec("sh -c 'ls -w1 /sys/class/backlight | head -1'");
    #screenValue = 0;
    #max = Number(Utils.exec('brightnessctl max'));
    #internalValue = Number(Utils.exec('brightnessctl get')) / this.#max;
    #buffer = 0.05; // 5% buffer

    get screen_value() {
        return this.#screenValue;
    }

    get value() {
        return this.#internalValue;
    }

    set value(percent) {
        if (percent < 0)
            percent = 0;
        if (percent > 1)
            percent = 1;

        this.#internalValue = percent;
        this.emit('value-changed', this.#internalValue);
        this.notify('value');

        // Update screen brightness if the change is greater than the buffer
        if (Math.abs(percent - this.#screenValue) > this.#buffer) {
            Utils.execAsync(`brightnessctl set ${percent * 100}% -q`);
            // The file monitor will handle updating #screenValue
        }
    }

    constructor() {
        super();
        const brightness = `/sys/class/backlight/${this.#interface}/brightness`;
        Utils.monitorFile(brightness, () => this.#onChange());
        this.#onChange();
    }

    #onChange() {
        const newScreenValue = Number(Utils.exec('brightnessctl get')) / this.#max;
        if (newScreenValue !== this.#screenValue) {
            this.#screenValue = newScreenValue;
            this.emit('changed');
            this.notify('screen-value');
            this.emit('screen-changed', this.#screenValue);
        }
    }

    connect(event = 'value-changed', callback) {
        return super.connect(event, callback);
    }
}

const service = new BrightnessService;
export default service;
