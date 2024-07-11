App.addIcons(`${App.configDir}/assets`);
import { setupBar } from './bar/bar.js';
import { setupSettings } from './settings/settings.js';


export const settingsVisible = Variable(false);

setupSettings();
setupBar();
App.config({
    windows: [
        // this is where window definitions will go
    ],
    style: './style.css',
})

export {}
