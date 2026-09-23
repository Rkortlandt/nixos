import QtQuick

QtObject {
    id: root

    property var revealers: []
    property var activeRevealer: null

    function register(revealer) {
        if (!revealer) return;
        for (let i = 0; i < revealers.length; ++i) {
            if (revealers[i] === revealer) return;
        }
        revealers.push(revealer);
        revealer.revealedChanged.connect(() => {
            if (revealer.revealed) {
                root.setActive(revealer);
            }
        });
    }

    function unregister(revealer) {
        let idx = revealers.indexOf(revealer);
        if (idx !== -1) {
            revealers.splice(idx, 1);
        }
        if (activeRevealer === revealer) {
            activeRevealer = null;
        }
    }

    function setActive(revealer) {
        activeRevealer = revealer;
        for (let i = 0; i < revealers.length; ++i) {
            let r = revealers[i];
            if (r && r !== revealer && r.revealed) {
                r.revealed = false;
            }
        }
    }
}
