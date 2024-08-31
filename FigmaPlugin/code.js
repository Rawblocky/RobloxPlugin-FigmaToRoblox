"use strict";
// This plugin will open a window to prompt the user to enter a number, and
// it will then create that many rectangles on the screen.
// This file holds the main code for the plugins. It has access to the *document*.
// You can access browser APIs in the <script> tag inside "ui.html" which has a
// full browser environment (see documentation).
// This shows the HTML page in "ui.html".
figma.showUI(__html__);
figma.ui.resize(500, 300);
// Calls to "parent.postMessage" from within the HTML page will trigger this
// callback. The callback will be passed the "pluginMessage" property of the
// posted message.

figma.ui.onmessage = msg => {
    // One way of distinguishing between different types of messages sent from
    // your HTML page is to use an object with a "type" property like this.
    const currentPage = figma.currentPage;
    let Code = [];

    function Check(node){
        if ("opacity" in node) {
            let Adding = {
                type: node.type,
                //
                name: node.name,
                visible: node.visible,
                //
                width: node.width,
                height: node.height,
                x: node.x,
                y: node.y,
                //
                rotation: node.rotation,
                clipsContent: node.clipsContent,
                fills: node.fills,
                cornerRadius: node.cornerRadius,
                strokeWeight: node.strokeWeight,
                strokes: node.strokes,
                //
                children: []
            }
            if (node.type == "TEXT") {
                Adding.textAlignHorizontal = node.textAlignHorizontal
                Adding.textAlignVertical = node.textAlignVertical
                Adding.textAutoResize = node.textAutoResize
                Adding.characters = node.characters
                Adding.fontSize = node.fontSize
                Adding.fontName = node.fontName
            }
            if ("children" in node){
                for (const node2 of node.children) {
                    const AdditionalInformation = Check(node2)
                    if (AdditionalInformation) {
                        Adding.children.push(AdditionalInformation)
                    }
                }
            }
            return Adding
        }
    }
    if (msg === 'Run') {
        for (const node of figma.currentPage.selection) {
            const Adding = Check(node)
            if (Adding) {
                Code.push(Adding)
            }
        }
        Code = JSON.stringify(Code)
        console.log(Code)
        figma.ui.postMessage(Code)
        return Code
    }
    // Make sure to close the plugin when you're done. Otherwise the plugin will
    // keep running, which shows the cancel button at the bottom of the screen.
    // figma.closePlugin();
};
