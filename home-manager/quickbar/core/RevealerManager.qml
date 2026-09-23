pragma Singleton
import QtQuick

QtObject {
    id: root

    property var groups: ({})

    function register(target, groupName) {
        if (!target || !groupName) return;
        if (!groups[groupName]) {
            groups[groupName] = [];
        }
        let list = groups[groupName];
        if (list.indexOf(target) === -1) {
            list.push(target);
            target.revealedChanged.connect(() => {
                if (target.revealed) {
                    closeOthers(target, groupName);
                }
            });
        }
    }

    function unregister(target, groupName) {
        if (!target || !groupName || !groups[groupName]) return;
        let list = groups[groupName];
        let idx = list.indexOf(target);
        if (idx !== -1) {
            list.splice(idx, 1);
        }
    }

    function closeOthers(activeTarget, groupName) {
        if (!groups[groupName]) return;
        let list = groups[groupName];
        for (let i = 0; i < list.length; ++i) {
            let item = list[i];
            if (item && item !== activeTarget && item.revealed) {
                item.revealed = false;
            }
        }
    }
}
