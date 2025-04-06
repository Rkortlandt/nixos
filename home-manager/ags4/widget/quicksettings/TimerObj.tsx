import { type Subscribable } from "astal/binding"
import Gtk from "gi://Gtk"

export class VarMap<K = string, T = { name: string; establishedTime: number; finishTime: number, length: number; }> implements Subscribable {
    #subs = new Set<(v: Array<[K, T]>) => void>()
    #map: Map<K, T> = new Map();

    #notifiy() {
        const value = this.get()
        for (const sub of this.#subs) {
            sub(value)
        }
    }

    #delete(key: K) {
        const v = this.#map.get(key)

        if (v instanceof Gtk.Widget) {
            v.destroy()
        }

        this.#map.delete(key)
    }

    constructor() {
    }

    set(key: K, value: T) {
        this.#delete(key)
        this.#map.set(key, value)
        this.#notifiy()
    }

    delete(key: K) {
        this.#delete(key)
        this.#notifiy()
    }

    get() {
        return [...this.#map.entries()]
    }

    subscribe(callback: (v: Array<[K, T]>) => void) {
        this.#subs.add(callback)
        return () => this.#subs.delete(callback)
    }
}
